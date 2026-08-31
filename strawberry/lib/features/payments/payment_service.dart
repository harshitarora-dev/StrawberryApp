import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:strawberry/core/upi_config.dart';
import 'package:strawberry/features/auth/auth_service.dart';

/// Result of a single "Pay Now" attempt.
///
/// [autoStatus] is set when the UPI app itself reported a definite
/// success/failure/cancellation back to us (Android only, via
/// [PaymentService.payViaUpi]'s native `startActivityForResult` channel).
/// When it's `null`, we genuinely don't know the outcome (no native
/// channel available, e.g. iOS/web/desktop, or the UPI app didn't return a
/// parseable response) and the UI should fall back to asking the student.
class UpiPaymentResult {
  final bool launched;
  final String rowId;
  final String? autoStatus; // 'success' | 'failed' | 'cancelled' | null
  final String? failureReason; // human-readable, only set when autoStatus == 'failed'

  UpiPaymentResult({
    required this.launched,
    required this.rowId,
    this.autoStatus,
    this.failureReason,
  });
}

/// Handles UPI fee payments via a `upi://pay` deep link, and logs every
/// attempt to the `fee_payments` Supabase table so it shows up in both the
/// student's payment history and the admin's tracking screen.
///
/// **Status detection:** On Android, the link is launched with
/// `startActivityForResult` through a small native method channel
/// (see `MainActivity.kt`) instead of `url_launcher`'s plain `startActivity`.
/// This lets the UPI app (GPay/PhonePe/Paytm/etc.) hand back its own
/// SUCCESS/FAILURE/SUBMITTED response when it closes, so most payments are
/// tracked automatically — no student action needed. This is the same
/// underlying Android mechanism the old `upi_india` plugin used; it's just
/// implemented directly here so there's no unmaintained third-party plugin
/// to break on newer Android Gradle Plugin versions.
///
/// This is not 100% airtight — a UPI app *can* report "SUCCESS" optimistically
/// before final bank settlement, and on iOS/web/desktop there's no such
/// channel at all. So:
///   - When the native channel gives a clear SUCCESS/FAILURE/CANCELLED, that
///     status is saved immediately (and on SUCCESS, the student's fee record
///     is marked paid right away).
///   - When the result is ambiguous (SUBMITTED, unparseable, or no native
///     channel available), the app falls back to asking the student "did
///     you complete it?" and the admin does a final manual confirm — same
///     safety net as before.
class PaymentService {
  final SupabaseClient _client = Supabase.instance.client;
  static const _upiChannel = MethodChannel('strawberry/upi');

  /// Generates a short, unique-enough alphanumeric reference for the `tr`
  /// (transaction reference) param — UPI requires this to be <= 35 chars.
  String generateTxnRef(String studentId) {
    final shortId = studentId.length > 6
        ? studentId.substring(0, 6)
        : studentId;
    final rand = Random().nextInt(9999).toString().padLeft(4, '0');
    final raw = 'SB${DateTime.now().millisecondsSinceEpoch}$shortId$rand'
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return raw.substring(0, min(35, raw.length));
  }

  /// Builds the `upi://pay?...` deep link with the school's UPI ID, payee
  /// name, amount, and a note pre-filled — this is what actually opens
  /// Google Pay / PhonePe / Paytm / any UPI app with the payment form
  /// ready to go.
  String buildUpiUri({
    required double amount,
    required String txnRef,
    required String note,
  }) {
    final params = {
      'pa': UpiConfig.vpa,
      'pn': UpiConfig.payeeName,
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
      'tn': note,
      'tr': txnRef,
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return 'upi://pay?$query';
  }

  static const _monthNamesShort = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Turns a `YYYY-MM` month key into a short readable label, e.g.
  /// "2026-01" -> "Jan 2026". Falls back to the raw key if it's malformed.
  String _formatMonthLabel(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;
    final m = int.tryParse(parts[1]) ?? 0;
    if (m < 1 || m > 12) return monthKey;
    return '${_monthNamesShort[m]} ${parts[0]}';
  }

  /// Builds the UPI transaction note shown to the payer in their UPI app
  /// and stored alongside the payment, e.g. "Fees - Riya Sharma - Jan 2026".
  /// UPI's `tn` field is commonly truncated by banks/PSPs around 50 chars,
  /// so this keeps the student name portion short if needed.
  String buildTransactionNote({
    required String studentName,
    required String monthKey,
  }) {
    final monthLabel = _formatMonthLabel(monthKey);
    final name = studentName.trim().isEmpty ? 'Student' : studentName.trim();
    var note = 'Fees - $name - $monthLabel';
    const maxLen = 50;
    if (note.length > maxLen) {
      // Trim the name first, keep the month intact since that matters most
      // for reconciliation.
      final suffix = ' - $monthLabel';
      final budget = maxLen - 'Fees - '.length - suffix.length;
      final trimmedName = budget > 3 ? name.substring(0, budget) : name;
      note = 'Fees - $trimmedName$suffix';
    }
    return note;
  }

  /// Parses a UPI app's raw response extra, e.g.
  /// "txnId=ABC123&responseCode=00&Status=SUCCESS&approvalRefNo=..."
  /// into a lowercase-keyed map. Different UPI apps use slightly different
  /// casing/key names, so lookups against this map should be case-insensitive
  /// (handled by [_classifyStatus] below).
  Map<String, String> _parseUpiResponse(String raw) {
    final result = <String, String>{};
    for (final pair in raw.split('&')) {
      final idx = pair.indexOf('=');
      if (idx <= 0) continue;
      final key = pair.substring(0, idx).toLowerCase();
      final value = Uri.decodeComponent(pair.substring(idx + 1));
      result[key] = value;
    }
    return result;
  }

  /// Builds a human-readable reason string from a parsed UPI response, e.g.
  /// "responseCode=Z9 · Transaction Declined by Bank". UPI apps vary a lot
  /// in which keys they actually fill in, so this just surfaces whatever
  /// is present instead of assuming a fixed shape.
  String? _buildFailureReason(Map<String, String> parsed) {
    if (parsed.isEmpty) return null;
    final parts = <String>[];
    for (final key in [
      'responsecode',
      'errorcode',
      'code',
      'msg',
      'message',
      'error',
      'errordescription',
    ]) {
      final value = parsed[key];
      if (value != null && value.trim().isNotEmpty) {
        parts.add('$key=$value');
      }
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Turns a parsed UPI response into one of our own statuses.
  /// Returns null when the outcome is genuinely ambiguous, so the caller
  /// falls back to asking the student — this is the safe default, since
  /// wrongly telling someone "your payment failed" when it actually went
  /// through is far worse than asking them to confirm manually.
  ///
  /// IMPORTANT: many UPI apps (Google Pay especially) don't reliably set
  /// any of these fields at all for a raw `upi://pay` deep link — they just
  /// close with resultCode == RESULT_CANCELED (0) and no data, *whether or
  /// not the payment actually succeeded*. So an empty response must NOT be
  /// treated as "cancelled" — only an explicit Status text counts.
  String? _classifyStatus(Map<String, String> parsed, int resultCode) {
    final status = (parsed['status'] ?? '').toUpperCase();
    if (status == 'SUCCESS') return 'success';
    if (status == 'FAILURE' || status == 'FAILED') return 'failed';
    // 'SUBMITTED', an unrecognised status, or no status at all — all
    // ambiguous. Ask the student rather than guess.
    return null;
  }

  /// Opens the UPI app via the native `startActivityForResult` channel and
  /// waits for its response. Returns null when the channel isn't available
  /// (non-Android platform) or something went wrong invoking it — callers
  /// should fall back to the plain `url_launcher` flow in that case.
  Future<Map<String, dynamic>?> _payWithUpiNative(String uri) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final result = await _upiChannel.invokeMethod('payWithUpi', {
        'uri': uri,
      });
      if (result is Map) return Map<String, dynamic>.from(result);
      return null;
    } on MissingPluginException {
      return null; // native side not wired up (e.g. running on an old build)
    } on PlatformException {
      return null;
    }
  }

  Future<String> _logPayment({
    required String studentId,
    required String studentName,
    required String monthKey,
    required double amount,
    required String txnRef,
    required String status,
  }) async {
    final row = await _client
        .from('fee_payments')
        .insert({
          'student_id': studentId,
          'student_name': studentName,
          'month_key': monthKey,
          'amount': amount,
          'txn_ref': txnRef,
          'upi_app': 'UPI',
          'status': status,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> _updateStatus(
    String rowId,
    String status, {
    String? rawResponse,
  }) async {
    final update = <String, dynamic>{'status': status};
    if (rawResponse != null) update['raw_response'] = rawResponse;
    await _client.from('fee_payments').update(update).eq('id', rowId);
  }

  /// Opens the UPI app chooser with amount + school UPI ID pre-filled, and
  /// logs the attempt. On Android this tries to detect success/failure
  /// automatically (see class doc above); elsewhere, or if that fails, it
  /// falls back to a plain launch that the student self-reports on.
  Future<UpiPaymentResult> payViaUpi({
    required double amount,
    required String monthKey,
    required String studentId,
    required String studentName,
    AuthService? authService,
  }) async {
    final txnRef = generateTxnRef(studentId);
    final rowId = await _logPayment(
      studentId: studentId,
      studentName: studentName,
      monthKey: monthKey,
      amount: amount,
      txnRef: txnRef,
      status: 'initiated',
    );

    final note = buildTransactionNote(
      studentName: studentName,
      monthKey: monthKey,
    );
    final uriString = buildUpiUri(amount: amount, txnRef: txnRef, note: note);

    // --- Try the native "wait for the UPI app's own result" path first. ---
    final native = await _payWithUpiNative(uriString);
    if (native != null) {
      final noAppFound = native['noAppFound'] == true;
      if (noAppFound) {
        await _updateStatus(rowId, 'cancelled');
        return UpiPaymentResult(launched: false, rowId: rowId);
      }

      final resultCode = (native['resultCode'] as num?)?.toInt() ?? -1;
      final raw = native['raw'] as String?;
      final parsed = raw != null ? _parseUpiResponse(raw) : <String, String>{};
      final status = _classifyStatus(parsed, resultCode);
      // Stored in the DB (raw_response column) so it can be checked from
      // the Supabase table editor, no device/console access needed.
      final rawForDb = raw ?? '(empty, resultCode=$resultCode)';

      // Also log it to the console for anyone running via `flutter run`.
      debugPrint(
        '[UPI] resultCode=$resultCode raw="$raw" classified=$status',
      );

      if (status == 'success') {
        await _updateStatus(rowId, 'success', rawResponse: rawForDb);
        if (authService != null) {
          await authService.markFeesPaid(studentId, monthKey);
        }
        return UpiPaymentResult(
          launched: true,
          rowId: rowId,
          autoStatus: 'success',
        );
      } else if (status == 'failed') {
        final reason = _buildFailureReason(parsed);
        await _updateStatus(rowId, 'failed', rawResponse: rawForDb);
        return UpiPaymentResult(
          launched: true,
          rowId: rowId,
          autoStatus: 'failed',
          failureReason: reason,
        );
      } else {
        // Ambiguous (e.g. SUBMITTED, unrecognised, or no Status at all —
        // many UPI apps just close silently whether the payment went
        // through or not). Fall back to student self-report + admin
        // confirm rather than guessing, same as before.
        await _updateStatus(rowId, 'submitted', rawResponse: rawForDb);
        return UpiPaymentResult(launched: true, rowId: rowId);
      }
    }

    // --- Fallback: plain launch, no native result channel available. ---
    bool launched = false;
    try {
      launched = await launchUrl(
        Uri.parse(uriString),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      launched = false;
    }

    await _updateStatus(rowId, launched ? 'submitted' : 'cancelled');
    return UpiPaymentResult(launched: launched, rowId: rowId);
  }

  /// Student self-report: "I've completed the payment" — keeps the row
  /// visible as submitted/awaiting confirmation. Does NOT mark fees paid
  /// by itself; the admin still confirms (see class doc above).
  Future<void> markSelfReportedPaid(String rowId) async {
    await _updateStatus(rowId, 'submitted');
  }

  /// Direct submission for manual/external UPI payments (e.g. copied UPI ID,
  /// paid outside the app or from another phone, or app was restarted).
  Future<String> submitManualPayment({
    required String studentId,
    required String studentName,
    required String monthKey,
    required double amount,
    String? utrOrTxnNote,
  }) async {
    final txnRef = generateTxnRef(studentId);
    final note = utrOrTxnNote != null && utrOrTxnNote.trim().isNotEmpty
        ? 'Manual UTR/Note: ${utrOrTxnNote.trim()}'
        : buildTransactionNote(studentName: studentName, monthKey: monthKey);

    final row = await _client
        .from('fee_payments')
        .insert({
          'student_id': studentId,
          'student_name': studentName,
          'month_key': monthKey,
          'amount': amount,
          'txn_ref': txnRef,
          'upi_app': 'Manual / Direct UPI',
          'status': 'submitted',
          'raw_response': note,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  /// Student self-report: payment didn't go through / was cancelled.
  Future<void> markSelfReportedFailed(String rowId) async {
    await _updateStatus(rowId, 'failed');
  }

  /// Payment history for a single student (newest first).
  Future<List<Map<String, dynamic>>> getPaymentsForStudent(
    String studentId,
  ) async {
    final rows = await _client
        .from('fee_payments')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// All payment attempts across every student — for the admin tracking
  /// screen (newest first).
  Future<List<Map<String, dynamic>>> getAllPayments() async {
    final rows =
        await _client.from('fee_payments').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Admin: confirm a payment after checking the bank statement, and mark
  /// the month paid on the student's profile (mirrors the existing manual
  /// "mark fees paid" flow).
  Future<void> adminConfirmPayment({
    required String rowId,
    required String studentId,
    required String monthKey,
    required AuthService authService,
  }) async {
    await _updateStatus(rowId, 'success');
    await authService.markFeesPaid(studentId, monthKey);
  }

  /// Admin: mark a payment attempt as failed/invalid.
  Future<void> adminRejectPayment(String rowId) async {
    await _updateStatus(rowId, 'failed');
  }
}
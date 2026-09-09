import 'package:supabase_flutter/supabase_flutter.dart';

class FeeItem {
  final String id;
  final String studentId;
  final String title;
  final String feeType; // 'one_time' | 'monthly' | 'annual'
  final double amount;
  final String periodKey; // e.g. '2026-10', '2026-27', 'ONE_TIME'
  final String status; // 'pending' | 'paid' | 'waived'
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? paidVia; // 'cash' | 'upi' | 'bank_transfer'
  final String? txnRef;
  final String? createdBy;
  final DateTime? createdAt;

  FeeItem({
    required this.id,
    required this.studentId,
    required this.title,
    required this.feeType,
    required this.amount,
    required this.periodKey,
    this.status = 'pending',
    this.dueDate,
    this.paidAt,
    this.paidVia,
    this.txnRef,
    this.createdBy,
    this.createdAt,
  });

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isWaived => status == 'waived';

  factory FeeItem.fromMap(Map<String, dynamic> map) {
    return FeeItem(
      id: map['id']?.toString() ?? '',
      studentId: map['student_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Fee',
      feeType: map['fee_type']?.toString() ?? 'one_time',
      amount: ((map['amount'] ?? 0) as num).toDouble(),
      periodKey: map['period_key']?.toString() ?? 'ONE_TIME',
      status: map['status']?.toString() ?? 'pending',
      dueDate: map['due_date'] != null ? DateTime.tryParse(map['due_date'].toString()) : null,
      paidAt: map['paid_at'] != null ? DateTime.tryParse(map['paid_at'].toString()) : null,
      paidVia: map['paid_via']?.toString(),
      txnRef: map['txn_ref']?.toString(),
      createdBy: map['created_by']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'student_id': studentId,
      'title': title,
      'fee_type': feeType,
      'amount': amount,
      'period_key': periodKey,
      'status': status,
    };
    if (dueDate != null) map['due_date'] = dueDate!.toIso8601String().split('T').first;
    if (paidAt != null) map['paid_at'] = paidAt!.toIso8601String();
    if (paidVia != null) map['paid_via'] = paidVia;
    if (txnRef != null) map['txn_ref'] = txnRef;
    if (createdBy != null) map['created_by'] = createdBy;
    return map;
  }
}

class FeeService {
  final SupabaseClient _client = Supabase.instance.client;

  static const List<String> defaultFeeTitles = [
    'Admission Fee',
    'Annual Charges',
    'Curriculum Fee',
    'Tuition Fee',
    'Books & Stationery',
    'Uniform Fee',
    'Transport Fee',
    'Picnic / Excursion Fee',
    'Exam Fee',
    'Sports & Activity Fee',
    'Development Fee',
    'Lab Fee',
    'Identity Card Fee',
    'Late Fee',
  ];

  static List<String>? _cachedSuggestions;

  /// Fetch distinct fee titles created across the system + combine with defaults
  Future<List<String>> getFeeHeadSuggestions({bool forceRefresh = false}) async {
    if (_cachedSuggestions != null && !forceRefresh) {
      return _cachedSuggestions!;
    }
    try {
      final res = await _client
          .from('student_fee_items')
          .select('title')
          .limit(300);

      final pastTitles = <String>{};
      for (final row in (res as List)) {
        final t = (row['title'] as String?)?.trim();
        if (t != null && t.isNotEmpty) {
          pastTitles.add(t);
        }
      }

      final merged = <String>{...defaultFeeTitles};
      for (final pt in pastTitles) {
        merged.add(pt);
      }
      _cachedSuggestions = merged.toList();
      return _cachedSuggestions!;
    } catch (_) {
      _cachedSuggestions = List.from(defaultFeeTitles);
      return _cachedSuggestions!;
    }
  }

  /// Register a newly used fee head into memory cache
  static void registerFeeHead(String title) {
    final t = title.trim();
    if (t.isEmpty) return;
    _cachedSuggestions ??= List.from(defaultFeeTitles);
    if (!_cachedSuggestions!.contains(t)) {
      _cachedSuggestions!.add(t);
    }
  }

  /// Fetch all fee items for a particular student, newest first
  Future<List<FeeItem>> getStudentFeeItems(String studentId) async {
    try {
      final response = await _client
          .from('student_fee_items')
          .select()
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      return (response as List).map((row) => FeeItem.fromMap(row as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Add a new fee item (e.g. One-Time Picnic, Uniform, Admission, Monthly Tuition)
  Future<FeeItem?> addFeeItem({
    required String studentId,
    required String title,
    required String feeType,
    required double amount,
    required String periodKey,
    String status = 'pending',
    DateTime? dueDate,
    String? createdBy,
  }) async {
    final data = <String, dynamic>{
      'student_id': studentId,
      'title': title,
      'fee_type': feeType,
      'amount': amount,
      'period_key': periodKey,
      'status': status,
    };
    if (dueDate != null) {
      data['due_date'] = dueDate.toIso8601String().split('T').first;
    }
    if (createdBy != null) {
      data['created_by'] = createdBy;
    }

    final response = await _client
        .from('student_fee_items')
        .insert(data)
        .select()
        .single();

    registerFeeHead(title);
    return FeeItem.fromMap(response);
  }

  /// Bulk insert fee items (e.g. during student admission approval)
  Future<void> addMultipleFeeItems(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    await _client.from('student_fee_items').insert(items);
    for (final item in items) {
      if (item['title'] is String) {
        registerFeeHead(item['title'] as String);
      }
    }
  }

  /// Update an existing fee item
  Future<void> updateFeeItem(String itemId, Map<String, dynamic> updates) async {
    await _client.from('student_fee_items').update(updates).eq('id', itemId);
  }

  /// Delete a fee item (Primary Admin action)
  Future<void> deleteFeeItem(String itemId) async {
    await _client.from('student_fee_items').delete().eq('id', itemId);
  }

  /// Mark a specific fee item as paid
  Future<void> markFeeItemPaid(
    String itemId, {
    required String paidVia,
    String? txnRef,
  }) async {
    final payload = <String, dynamic>{
      'status': 'paid',
      'paid_at': DateTime.now().toIso8601String(),
      'paid_via': paidVia,
    };
    if (txnRef != null) payload['txn_ref'] = txnRef;
    await _client.from('student_fee_items').update(payload).eq('id', itemId);
  }

  /// Unmark a fee item (set back to pending)
  Future<void> unmarkFeeItemPaid(String itemId) async {
    await _client.from('student_fee_items').update({
      'status': 'pending',
      'paid_at': null,
      'paid_via': null,
      'txn_ref': null,
    }).eq('id', itemId);
  }

  /// Batch mark multiple fee items as paid
  Future<void> batchMarkPaid(
    List<String> itemIds, {
    required String paidVia,
    String? txnRef,
  }) async {
    if (itemIds.isEmpty) return;
    final payload = <String, dynamic>{
      'status': 'paid',
      'paid_at': DateTime.now().toIso8601String(),
      'paid_via': paidVia,
    };
    if (txnRef != null) payload['txn_ref'] = txnRef;
    await _client.from('student_fee_items').update(payload).inFilter('id', itemIds);
  }
}

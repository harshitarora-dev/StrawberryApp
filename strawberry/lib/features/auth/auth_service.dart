import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:strawberry/features/auth/push_notification_service.dart';

class AuthService {
  FirebaseAuth? get _firebaseAuth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }
  static const String _webClientId =
      '246316625668-m9fe5m33tjhhril3cpv2uhempcsai3ot.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
    scopes: ['email'],
  );
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Sign in with Google — native Android account picker on mobile, standard popup on web
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb && _firebaseAuth != null) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        return await _firebaseAuth!.signInWithPopup(googleProvider);
      }

      // Mobile: Trigger native Google Sign-In account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential from Google tokens
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _firebaseAuth?.signInWithCredential(credential);
    } on Exception catch (e) {
      final msg = e.toString().toLowerCase();
      // Silently handle user cancellation
      if (msg.contains('cancel') ||
          msg.contains('sign_in_canceled') ||
          msg.contains('popup_closed_by_user') ||
          msg.contains('canceled-by-user')) {
        return null;
      }
      rethrow;
    }
  }

  // Checks if a user is currently logged in via Firebase
  bool isLoggedIn() {
    try {
      return _firebaseAuth?.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  // Get current user ID (Firebase UID string)
  String? get currentUserId {
    try {
      return _firebaseAuth?.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  // Get current user display name from Google
  String? get currentUserDisplayName {
    try {
      return _firebaseAuth?.currentUser?.displayName;
    } catch (_) {
      return null;
    }
  }

  // Get current user email
  String? get currentUserEmail {
    try {
      return _firebaseAuth?.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  // Get current user photo URL
  String? get currentUserPhotoUrl {
    try {
      return _firebaseAuth?.currentUser?.photoURL;
    } catch (_) {
      return null;
    }
  }

  // Log out of Firebase and Google session
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth?.signOut();
    } catch (_) {}
  }

  // Fetches the user profile from Supabase database matching Firebase UID
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final data = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data != null) {
        // Trigger register device token asynchronously
        unawaited(PushNotificationService().registerDeviceToken());
      }
      return data;
    } catch (e) {
      return null;
    }
  }

  // Check if an email is pre-authorized as admin in Supabase
  Future<bool> isEmailAuthorizedAdmin(String email) async {
    try {
      final response = await _supabaseClient
          .from('allowed_admins')
          .select('email')
          .eq('email', email)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Create a profile for the current Firebase user in Supabase
  // Name is automatically taken from the Google account (displayName)
  Future<Map<String, dynamic>> createProfile() async {
    final userId = currentUserId;
    final name = currentUserDisplayName ?? 'User';
    final email = currentUserEmail ?? '';
    final photoUrl = currentUserPhotoUrl;

    if (userId == null) {
      throw Exception('User is not logged in');
    }

    final isAdmin = await isEmailAuthorizedAdmin(email);
    final profileData = {
      'id': userId, // Firebase UID
      'email': email,
      'name': name,
      'photo_url': photoUrl,
      'role': isAdmin ? 'admin' : 'student',
      'status': isAdmin ? 'approved' : 'pending',
      'student_type': isAdmin ? 'Admin' : null,
      'fees': 0,
    };

    await _supabaseClient.from('profiles').insert(profileData).select();
    
    // Trigger register device token asynchronously
    unawaited(PushNotificationService().registerDeviceToken());

    return profileData;
  }


  // Get list of pending student approval requests (Admins only)
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final response = await _supabaseClient
        .from('profiles')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // Approve a pending request and assign type and fees (Admins only)
  Future<void> approveStudent(String uid, String type, double fees) async {
    await _supabaseClient
        .from('profiles')
        .update({'status': 'approved', 'student_type': type, 'fees': fees})
        .eq('id', uid);
  }

  // Add an email to allowed_admins (Admins only)
  Future<void> addAdmin(String email) async {
    // 1. Add to allowed_admins
    await _supabaseClient.from('allowed_admins').insert({'email': email});

    // 2. If the user already has a profile, upgrade their role to admin and approve them
    try {
      await _supabaseClient
          .from('profiles')
          .update({'role': 'admin', 'status': 'approved'})
          .eq('email', email);
    } catch (e) {
      // Profile might not exist yet, which is fine
    }
  }

  // Get all pre-authorized admins
  Future<List<String>> getAllowedAdmins() async {
    final response = await _supabaseClient
        .from('allowed_admins')
        .select('email');
    return List<String>.from(
      (response as List).map((e) => e['email'] as String),
    );
  }

  // ----- Attendance Methods -----

  // Fetch attendance records for a student between dates
  Future<List<Map<String, dynamic>>> getStudentAttendance(
    String uid, {
    DateTime? start,
    DateTime? end,
  }) async {
    var query = _supabaseClient
        .from('attendance')
        .select('*')
        .eq('student_id', uid);
    if (start != null) {
      query = query.gte('date', start.toIso8601String().split('T').first);
    }
    if (end != null) {
      query = query.lte('date', end.toIso8601String().split('T').first);
    }
    final response = await query.order('date', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Fetch attendance records for all students for a specific date
  Future<List<Map<String, dynamic>>> getAttendanceForDate(String date) async {
    final response = await _supabaseClient
        .from('attendance')
        .select('student_id, status, in_time, out_time')
        .eq('date', date);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Mark attendance for a date; entries: list of maps {student_id, status, in_time, out_time}
  Future<void> markAttendance(
    String date,
    List<Map<String, dynamic>> entries,
  ) async {
    if (entries.isEmpty) return;

    // Delete existing records for these specific student IDs on this date to avoid duplicates
    final studentIds = entries.map((e) => e['student_id'] as String).toList();
    await _supabaseClient
        .from('attendance')
        .delete()
        .eq('date', date)
        .inFilter('student_id', studentIds);

    // Insert new entries with date field
    final toInsert = entries
        .map(
          (e) => {
            'student_id': e['student_id'],
            'date': date,
            'status': e['status'],
            'in_time': e['in_time'],
            'out_time': e['out_time'],
          },
        )
        .toList();
    await _supabaseClient.from('attendance').insert(toInsert);
  }

  // Retrieve all approved students (for admin dropdown)
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    final response = await _supabaseClient
        .from('profiles')
        .select()
        .eq('role', 'student')
        .eq('status', 'approved');
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Fetch attendance records for ALL students within a date range (Admin analytics).
  // Used for the review/analysis dashboard — day-wise present/absent/late counts,
  // monthly trends, etc.
  Future<List<Map<String, dynamic>>> getAttendanceInRange({
    DateTime? start,
    DateTime? end,
  }) async {
    var query = _supabaseClient.from('attendance').select('student_id, date, status, in_time, out_time');
    if (start != null) {
      query = query.gte('date', start.toIso8601String().split('T').first);
    }
    if (end != null) {
      query = query.lte('date', end.toIso8601String().split('T').first);
    }
    final response = await query.order('date', ascending: true);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Reject a student application (Admin only)
  Future<void> rejectStudent(String uid) async {
    await _supabaseClient
        .from('profiles')
        .update({'status': 'rejected'})
        .eq('id', uid);
  }

  // Re-submit a rejected student's request (Student action)
  Future<void> reRequestApproval(String uid) async {
    await _supabaseClient
        .from('profiles')
        .update({'status': 'pending'})
        .eq('id', uid);
  }

  // Mark a specific month as paid for a student
  // monthKey format: "YYYY-MM" e.g. "2024-07"
  Future<void> markFeesPaid(String uid, String monthKey) async {
    // Fetch current array first
    final profile = await _supabaseClient
        .from('profiles')
        .select('fees_paid_months')
        .eq('id', uid)
        .maybeSingle();
    final existing = List<String>.from(
      (profile?['fees_paid_months'] as List?) ?? [],
    );
    if (!existing.contains(monthKey)) {
      existing.add(monthKey);
    }
    await _supabaseClient
        .from('profiles')
        .update({'fees_paid_months': existing})
        .eq('id', uid);
  }

  // Remove a month from fees_paid for a student
  Future<void> unmarkFeesPaid(String uid, String monthKey) async {
    final profile = await _supabaseClient
        .from('profiles')
        .select('fees_paid_months')
        .eq('id', uid)
        .maybeSingle();
    final existing = List<String>.from(
      (profile?['fees_paid_months'] as List?) ?? [],
    );
    existing.remove(monthKey);
    await _supabaseClient
        .from('profiles')
        .update({'fees_paid_months': existing})
        .eq('id', uid);
  }

  // Update a student's category and/or fees (Upgrade Student)
  Future<void> updateStudent(
    String uid, {
    String? studentType,
    double? fees,
  }) async {
    final updates = <String, dynamic>{};
    if (studentType != null) updates['student_type'] = studentType;
    if (fees != null) updates['fees'] = fees;
    if (updates.isEmpty) return;
    await _supabaseClient.from('profiles').update(updates).eq('id', uid);
  }

  // ----- Notice Methods -----

  // Fetch notices for a particular audience (All or specific type)
  Future<List<Map<String, dynamic>>> getNotices({
    required String audience,
  }) async {
    final response = await _supabaseClient
        .from('notices')
        .select('*')
        .eq('target_audience', audience)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Fetch notices targeted specifically at a student by UID
  Future<List<Map<String, dynamic>>> getStudentSpecificNotices(
    String uid,
  ) async {
    if (uid.isEmpty) return [];
    final response = await _supabaseClient
        .from('notices')
        .select('*')
        .eq('target_audience', 'Specific')
        .eq('specific_student_id', uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Create a new notice.
  //
  // scheduleType:
  //   'now'    -> dispatched immediately (default, unchanged behaviour)
  //   'once'   -> dispatched once at `scheduledAt`
  //   'daily'  -> dispatched every day at `recurrenceTime`
  //   'weekly' -> dispatched every week on `recurrenceDays` (ISO weekday 1=Mon..7=Sun) at `recurrenceTime`
  //
  // For 'once'/'daily'/'weekly' the row is inserted with status 'pending' and
  // next_run_at set; the `dispatch-scheduled-notices` Edge Function (driven by
  // pg_cron) picks it up and sends the push when it's due.
  Future<void> createNotice({
    required String title,
    required String body,
    required String audience,
    String? specificStudentId,
    String category = 'General',
    String scheduleType = 'now',
    DateTime? scheduledAt,
    TimeOfDay? recurrenceTime,
    List<int>? recurrenceDays, // ISO weekday: 1=Mon .. 7=Sun
    DateTime? recurrenceEndDate,
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'body': body,
      'target_audience': audience,
      'category': category,
      'created_at': DateTime.now().toIso8601String(),
      'schedule_type': scheduleType,
      'status': scheduleType == 'now' ? 'sent' : 'pending',
    };
    if (scheduleType == 'now') {
      // Marks it as already-delivered so students see it right away, same as
      // a scheduled notice becomes visible only once the dispatcher stamps this.
      data['last_sent_at'] = DateTime.now().toUtc().toIso8601String();
    }
    if (audience == 'Specific' && specificStudentId != null) {
      data['specific_student_id'] = specificStudentId;
    }

    if (scheduleType == 'once' && scheduledAt != null) {
      data['next_run_at'] = scheduledAt.toUtc().toIso8601String();
    } else if (scheduleType == 'daily' && recurrenceTime != null) {
      data['recurrence_time'] =
          '${recurrenceTime.hour.toString().padLeft(2, '0')}:${recurrenceTime.minute.toString().padLeft(2, '0')}:00';
      data['next_run_at'] = _nextDailyRun(recurrenceTime).toUtc().toIso8601String();
      if (recurrenceEndDate != null) {
        data['recurrence_end_date'] = recurrenceEndDate.toIso8601String().split('T').first;
      }
    } else if (scheduleType == 'weekly' && recurrenceTime != null && recurrenceDays != null && recurrenceDays.isNotEmpty) {
      data['recurrence_time'] =
          '${recurrenceTime.hour.toString().padLeft(2, '0')}:${recurrenceTime.minute.toString().padLeft(2, '0')}:00';
      data['recurrence_days'] = recurrenceDays;
      data['next_run_at'] = _nextWeeklyRun(recurrenceTime, recurrenceDays).toUtc().toIso8601String();
      if (recurrenceEndDate != null) {
        data['recurrence_end_date'] = recurrenceEndDate.toIso8601String().split('T').first;
      }
    }

    await _supabaseClient.from('notices').insert(data);
  }

  // Next occurrence (today if the time hasn't passed yet, else tomorrow) for a daily notice.
  DateTime _nextDailyRun(TimeOfDay time) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  // Next occurrence for a weekly notice given a set of ISO weekdays (1=Mon..7=Sun).
  DateTime _nextWeeklyRun(TimeOfDay time, List<int> isoWeekdays) {
    final now = DateTime.now();
    for (int i = 0; i <= 7; i++) {
      final candidateDate = now.add(Duration(days: i));
      final candidate = DateTime(
          candidateDate.year, candidateDate.month, candidateDate.day, time.hour, time.minute);
      if (isoWeekdays.contains(candidate.weekday) && candidate.isAfter(now)) {
        return candidate;
      }
    }
    // Fallback: shouldn't normally happen since we scan a full week ahead.
    return now.add(const Duration(days: 7));
  }

  // Fetch all notices for admin review (includes pending/scheduled/recurring ones)
  Future<List<Map<String, dynamic>>> getSentNotices() async {
    final response = await _supabaseClient
        .from('notices')
        .select('*')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Delete a notice
  Future<void> deleteNotice(int id) async {
    await _supabaseClient.from('notices').delete().eq('id', id);
  }

  // Cancel a pending scheduled/recurring notice without deleting its history row.
  Future<void> cancelScheduledNotice(int id) async {
    await _supabaseClient
        .from('notices')
        .update({'status': 'cancelled'})
        .eq('id', id);
  }

  // ----- Category Methods -----

  // Fetch student categories from the database.
  // Fallbacks to default categories if the fetch fails or table doesn't exist.
  Future<List<String>> getCategories() async {
    try {
      final response = await _supabaseClient
          .from('student_categories')
          .select('name')
          .order('name', ascending: true);
      
      final list = List<String>.from(
        (response as List).map((e) => e['name'] as String),
      );
      if (list.isEmpty) {
        return ['Playgroup', 'Nursery', 'LKG', 'UKG', 'Tution'];
      }
      return list;
    } catch (e) {
      return ['Playgroup', 'Nursery', 'LKG', 'UKG', 'Tution'];
    }
  }

  // Add a new student category
  Future<void> addCategory(String name) async {
    await _supabaseClient.from('student_categories').insert({'name': name});
  }

  // Delete a student category
  Future<void> deleteCategory(String name) async {
    await _supabaseClient.from('student_categories').delete().eq('name', name);
  }

  // Submit prospective parent admission enquiry
  Future<void> submitAdmissionEnquiry({
    required String parentName,
    required String phone,
    String? childName,
    String? childAge,
    String? program,
    String? message,
  }) async {
    try {
      await _supabaseClient.from('admission_enquiries').insert({
        'parent_name': parentName,
        'phone': phone,
        'child_name': childName ?? '',
        'child_age': childAge ?? '',
        'program': program ?? '',
        'message': message ?? '',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Table may not exist yet or offline; gracefully handle
    }
  }

  // ----- Student/Admin Removal Methods -----

  // Remove a student (Primary Admin only)
  Future<void> removeStudent(String uid) async {
    // 1. Delete attendance records for this student
    await _supabaseClient.from('attendance').delete().eq('student_id', uid);

    // 2. Delete chat messages involving this student
    await _supabaseClient
        .from('messages')
        .delete()
        .or('sender_id.eq.$uid,receiver_id.eq.$uid');

    // 3. Delete student profile
    await _supabaseClient.from('profiles').delete().eq('id', uid);
  }

  // Remove a co-admin (Primary Admin only)
  Future<void> removeAdmin(String email) async {
    // Prevent primary admin deletion
    if (email.trim().toLowerCase() == 'dev.harshitcreations@gmail.com') {
      throw Exception('Cannot delete the primary administrator.');
    }

    // 1. Remove from allowed_admins
    await _supabaseClient.from('allowed_admins').delete().eq('email', email);

    // 2. Delete profile from profiles
    await _supabaseClient.from('profiles').delete().eq('email', email);
  }

  // ----- Notice Board Methods for Students -----

  // Fetch notices filtered for student (General notices + category notices + specific student notices)
  Future<List<Map<String, dynamic>>> getNoticesForStudent(
      String uid, String? studentType) async {
    String orFilter = 'target_audience.eq.All';
    if (studentType != null && studentType.isNotEmpty) {
      orFilter += ',target_audience.eq.$studentType';
    }
    if (uid.isNotEmpty) {
      orFilter += ',and(target_audience.eq.Specific,specific_student_id.eq.$uid)';
    }

    final response = await _supabaseClient
        .from('notices')
        .select('*')
        .or(orFilter)
        .not('last_sent_at', 'is', null) // hide scheduled/recurring notices until they've actually been dispatched
        .order('last_sent_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  // Listen to Postgres changes for notices targeted at the student in real-time.
  // Only notices that have actually been dispatched (last_sent_at set) are
  // surfaced — a scheduled/recurring notice sits invisible until the
  // dispatch-scheduled-notices Edge Function stamps last_sent_at on it.
  Stream<List<Map<String, dynamic>>> getNoticesRealtimeStream(
      String uid, String? studentType) {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    List<Map<String, dynamic>> noticesList = [];
    // Tracks the last_sent_at we've already shown for each notice id, so a
    // recurring notice firing again (same id, new last_sent_at) is detected
    // as a fresh delivery instead of being silently ignored.
    final Map<int, String?> lastKnownSentAt = {};

    bool isNoticeForStudent(Map<String, dynamic> notice) {
      final audience = (notice['target_audience'] ?? 'All') as String;
      final specificId = notice['specific_student_id'] as String?;
      if (audience == 'All') return true;
      if (studentType != null && audience == studentType) return true;
      if (audience == 'Specific' && specificId == uid) return true;
      return false;
    }

    bool isDispatched(Map<String, dynamic> notice) => notice['last_sent_at'] != null;

    Future<void> fetchInitial() async {
      try {
        final list = await getNoticesForStudent(uid, studentType);
        noticesList = list;
        for (final n in list) {
          lastKnownSentAt[n['id'] as int] = n['last_sent_at'] as String?;
        }
        if (!controller.isClosed) controller.add(List.from(noticesList));
      } catch (e) {
        print('NoticesStream fetchInitial error: $e');
      }
    }

    fetchInitial();

    // `onNewDelivery` fires only for genuinely new pushes: either a brand
    // new notice, or a recurring one whose last_sent_at just advanced.
    void handleIncomingRow(Map<String, dynamic> row, void Function(Map<String, dynamic>) onNewDelivery) {
      if (!isNoticeForStudent(row) || !isDispatched(row)) return;

      final id = row['id'] as int;
      final incomingSentAt = row['last_sent_at'] as String?;
      final alreadyKnownSentAt = lastKnownSentAt[id];

      if (alreadyKnownSentAt == incomingSentAt) return; // nothing new to show

      lastKnownSentAt[id] = incomingSentAt;

      final existingIndex = noticesList.indexWhere((n) => n['id'] == id);
      if (existingIndex != -1) {
        noticesList[existingIndex] = row;
      } else {
        noticesList.insert(0, row);
      }
      noticesList.sort((a, b) => ((b['last_sent_at'] ?? '') as String)
          .compareTo((a['last_sent_at'] ?? '') as String));

      if (!controller.isClosed) controller.add(List.from(noticesList));
      onNewDelivery(row);
    }

    final channelName = 'notices_realtime';
    final channel = _supabaseClient.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notices',
          callback: (payload) {
            handleIncomingRow(Map<String, dynamic>.from(payload.newRecord), (_) {});
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notices',
          callback: (payload) {
            // Skipped on the very first tick after subscribing to avoid
            // re-announcing everything fetchInitial() already loaded.
            handleIncomingRow(Map<String, dynamic>.from(payload.newRecord), (_) {});
          },
        )
        .subscribe();

    controller.onCancel = () {
      _supabaseClient.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  // ----- Gallery Methods -----

  // Upload gallery images (compress to <=450KB on native, direct bytes on web) and store URLs
  Future<List<String>> uploadGalleryImages(
    List<dynamic> files, {
    String? category,
    String? title,
  }) async {
    final List<String> urls = [];
    for (var file in files) {
      try {
        Uint8List bytes;
        String rawName;

        if (file is XFile) {
          bytes = await file.readAsBytes();
          rawName = file.name;
        } else if (file is File) {
          if (!kIsWeb) {
            final compressed = await compressImage(file);
            bytes = await compressed.readAsBytes();
          } else {
            bytes = await file.readAsBytes();
          }
          rawName = file.path.split('/').last.split('\\').last;
        } else {
          continue;
        }

        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$rawName';

        await Supabase.instance.client.storage
            .from('gallery')
            .uploadBinary(fileName, bytes);

        final publicUrl = Supabase.instance.client.storage
            .from('gallery')
            .getPublicUrl(fileName);

        // Try inserting with category/title with fallback
        try {
          final insertData = <String, dynamic>{
            'image_url': publicUrl,
            'uploaded_by': currentUserId,
            'created_at': DateTime.now().toIso8601String(),
          };
          if (category != null && category.isNotEmpty) {
            insertData['category'] = category;
          }
          if (title != null && title.isNotEmpty) {
            insertData['title'] = title;
          }
          await _supabaseClient.from('gallery').insert(insertData);
        } catch (_) {
          await _supabaseClient.from('gallery').insert({
            'image_url': publicUrl,
            'uploaded_by': currentUserId,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
        urls.add(publicUrl);
      } catch (e, stackTrace) {
        debugPrint("ERROR DURING UPLOAD/COMPRESSION: $e");
        debugPrint(stackTrace.toString());
        rethrow;
      }
    }
    return urls;
  }

  // Helper to compress image using flutter_image_compress to <=450KB
  Future<File> compressImage(File file) async {
    if (kIsWeb) return file;
    const maxSize = 450 * 1024; // 450KB
    var quality = 95;
    File? compressedFile = file;
    try {
      while (true) {
        final result = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          '${file.path}_compressed.jpg',
          quality: quality,
        );
        if (result == null) break;
        final asFile = File(result.path); // XFile → File (v2.x returns XFile)
        final bytes = await asFile.length();
        if (bytes <= maxSize || quality <= 30) {
          compressedFile = asFile;
          break;
        }
        quality -= 10;
      }
    } catch (_) {
      return file;
    }
    return compressedFile ?? file;
  }

  // Fetch gallery images
  Future<List<Map<String, dynamic>>> getGalleryImages() async {
    final response = await _supabaseClient
        .from('gallery')
        .select('*')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Delete a gallery image from database and storage
  Future<void> deleteGalleryImage(int id, String imageUrl) async {
    await _supabaseClient.from('gallery').delete().eq('id', id);
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final fileName = pathSegments.last;
        await _supabaseClient.storage.from('gallery').remove([fileName]);
      }
    } catch (e) {
      print("Error deleting storage file: $e");
    }
  }

  // ----- Chat Methods -----

  // Send a chat message.
  // Returns the inserted row (with its real `id` + `created_at`) so the
  // caller can optimistically show it immediately, instead of waiting on
  // the Realtime INSERT event to round-trip back.
  Future<Map<String, dynamic>> sendMessage(
    String senderId,
    String receiverId,
    String text,
  ) async {
    final inserted = await _supabaseClient
        .from('messages')
        .insert({
          'sender_id': senderId,
          'receiver_id': receiverId,
          'message': text,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    return Map<String, dynamic>.from(inserted);
  }

  // Delete a single chat message (admin only, either side's message).
  Future<void> deleteMessage(int id) async {
    await _supabaseClient.from('messages').delete().eq('id', id);
  }

  // Delete an entire chat thread between a student and admin.
  Future<void> deleteChatThread(String studentId) async {
    await _supabaseClient
        .from('messages')
        .delete()
        .or('and(sender_id.eq.$studentId,receiver_id.eq.admin),and(sender_id.eq.admin,receiver_id.eq.$studentId)');
  }

  // Stream messages for a chat between student and admin
  // Uses Realtime channel subscription + initial fetch for reliability
  Stream<List<Map<String, dynamic>>> getChatStream(String studentId) {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    List<Map<String, dynamic>> messages = [];

    bool isMessageForThisChat(Map<String, dynamic> m) {
      final sender = (m['sender_id'] ?? '') as String;
      final receiver = (m['receiver_id'] ?? '') as String;
      return (sender == studentId && receiver == 'admin') ||
          (sender == 'admin' && receiver == studentId);
    }

    // Step 1: Fetch existing messages immediately
    Future<void> fetchInitial() async {
      try {
        final data = await _supabaseClient
            .from('messages')
            .select()
            .or('and(sender_id.eq.$studentId,receiver_id.eq.admin),and(sender_id.eq.admin,receiver_id.eq.$studentId)')
            .order('created_at', ascending: true);
        messages = List<Map<String, dynamic>>.from(data);
        if (!controller.isClosed) controller.add(List.from(messages));
      } catch (e) {
        print('ChatStream fetchInitial error: $e');
      }
    }

    fetchInitial();

    // Step 2: Subscribe to Realtime INSERT events on messages table
    final channelName = 'chat_${studentId}_admin';
    final channel = _supabaseClient.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final newRow = payload.newRecord;
            if (isMessageForThisChat(newRow)) {
              final id = newRow['id'];
              // Avoid duplicating a message we already added optimistically
              // on the sending side (see ChatPage._sendMessage).
              if (id != null && messages.any((m) => m['id'] == id)) return;
              messages.add(Map<String, dynamic>.from(newRow));
              // Sort by created_at to ensure correct order
              messages.sort((a, b) {
                final ta = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
                final tb = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
                return ta.compareTo(tb);
              });
              if (!controller.isClosed) controller.add(List.from(messages));
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            // Supabase only guarantees the primary key in oldRecord unless
            // REPLICA IDENTITY FULL is set on the table, so match on id only.
            final oldRow = payload.oldRecord;
            final id = oldRow['id'];
            if (id == null) return;
            final before = messages.length;
            messages.removeWhere((m) => m['id'] == id);
            if (messages.length != before && !controller.isClosed) {
              controller.add(List.from(messages));
            }
          },
        )
        .subscribe();

    // Clean up channel when stream is cancelled
    controller.onCancel = () {
      _supabaseClient.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  // Fetch list of students who have chatted (admin inbox list)
  Future<List<Map<String, dynamic>>> getChatList() async {
    // Get unique student ids from messages
    final response = await _supabaseClient
        .from('messages')
        .select('sender_id, receiver_id')
        .order('created_at', ascending: false);

    final studentIds = <String>{};
    for (var m in response) {
      final s = m['sender_id'] as String;
      final r = m['receiver_id'] as String;
      if (s != 'admin') studentIds.add(s);
      if (r != 'admin') studentIds.add(r);
    }

    if (studentIds.isEmpty) return [];

    // Get profiles details for these student IDs
    final profilesResponse = await _supabaseClient
        .from('profiles')
        .select('id, name, email, student_type')
        .inFilter('id', studentIds.toList());

    return List<Map<String, dynamic>>.from(profilesResponse as List);
  }

  // ----- Holiday Management Methods -----

  /// Check if a category has Saturday as a default weekend holiday.
  bool isSaturdayDefaultHoliday(String category) {
    final cat = category.trim().toLowerCase();
    return cat == 'lkg' || cat == 'nursery' || cat == 'playgroup' || cat == 'ukg';
  }

  /// Fetch all holiday + working_day entries for a given year-month.
  Future<List<Map<String, dynamic>>> getHolidaysForMonth(
    int year,
    int month,
  ) async {
    final from = '$year-${month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(year, month + 1, 0).day;
    final to = '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    final response = await _supabaseClient
        .from('holidays')
        .select('*')
        .gte('date', from)
        .lte('date', to)
        .order('date', ascending: true);

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Fetch all entries (holiday + working_day) for a specific date.
  Future<List<Map<String, dynamic>>> getHolidaysForDate(String date) async {
    final response = await _supabaseClient
        .from('holidays')
        .select('*')
        .eq('date', date);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Core holiday check for a date + category combination.
  /// Returns a map with:
  ///   isHoliday       -> bool
  ///   isSundayException -> bool (Weekend hai but is category ki class hai)
  ///   title           -> String? (holiday/exception ka naam)
  Future<Map<String, dynamic>> checkHoliday(
    String date, // 'yyyy-MM-dd'
    String category, // e.g. 'LKG', 'Nursery', 'School', 'All'
  ) async {
    final rows = await getHolidaysForDate(date);

    // Step 1: working_day exception for this category
    final exception = rows.firstWhere(
      (r) => r['type'] == 'working_day' && r['category'] == category,
      orElse: () => {},
    );
    if (exception.isNotEmpty) {
      return {
        'isHoliday': false,
        'isSundayException': true,
        'title': exception['title'],
      };
    }

    // Step 2: Weekend default check
    final dt = DateTime.tryParse(date);
    if (dt != null) {
      if (dt.weekday == DateTime.sunday) {
        return {'isHoliday': true, 'isSundayException': false, 'title': 'Sunday'};
      }
      if (dt.weekday == DateTime.saturday && isSaturdayDefaultHoliday(category)) {
        return {'isHoliday': true, 'isSundayException': false, 'title': 'Saturday'};
      }
    }

    // Step 3: Explicit holiday from DB
    final holiday = rows.firstWhere(
      (r) =>
          r['type'] == 'holiday' &&
          (r['category'] == 'All' || r['category'] == category),
      orElse: () => {},
    );
    if (holiday.isNotEmpty) {
      return {
        'isHoliday': true,
        'isSundayException': false,
        'title': holiday['title'],
      };
    }

    // Step 4: Normal working day
    return {'isHoliday': false, 'isSundayException': false, 'title': null};
  }

  /// Add a holiday or a working-day weekend exception.
  Future<void> addHoliday({
    required String date,
    required String title,
    String? description,
    required String category,
    String type = 'holiday',
  }) async {
    await _supabaseClient.from('holidays').upsert({
      'date': date,
      'title': title,
      'description': description,
      'category': category,
      'type': type,
    }, onConflict: 'date,category,type');
  }

  /// Delete a holiday or exception entry by its primary key id.
  Future<void> deleteHoliday(int id) async {
    await _supabaseClient.from('holidays').delete().eq('id', id);
  }
}
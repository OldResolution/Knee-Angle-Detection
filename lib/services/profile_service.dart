import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  ProfileService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static Map<String, dynamic> mergeProfileData({
    User? user,
    Map<String, dynamic>? profileRow,
    Map<String, dynamic>? metadata,
  }) {
    final resolvedMetadata = metadata ??
        (user == null
            ? const <String, dynamic>{}
            : Map<String, dynamic>.from(user.userMetadata ?? const {}));

    final fallback = <String, dynamic>{
      'id': user?.id,
      'email': user?.email,
      'name': resolvedMetadata['name'],
      'mobile': resolvedMetadata['mobile'],
      'age': resolvedMetadata['age'],
      'gender': resolvedMetadata['gender'],
    };

    final merged = <String, dynamic>{
      ...fallback,
      ...?profileRow,
    };

    merged.removeWhere((key, value) => value == null);
    return merged;
  }

  static Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final row =
          await _client.from('profiles').select().eq('id', user.id).single();
      return mergeProfileData(
        user: user,
        profileRow: Map<String, dynamic>.from(row),
      );
    } catch (_) {
      return mergeProfileData(user: user);
    }
  }

  static Future<void> ensureCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return;
    }

    final merged = mergeProfileData(user: user);
    if (merged.isEmpty) {
      return;
    }

    await _upsertProfileRow(user.id, merged);
  }

  static Future<void> upsertCurrentUserProfile({
    String? name,
    String? email,
    String? mobile,
    int? age,
    String? gender,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return;
    }

    await upsertProfileForUserId(
      userId: user.id,
      email: email ?? user.email,
      metadata: Map<String, dynamic>.from(user.userMetadata ?? const {}),
      name: name,
      mobile: mobile,
      age: age,
      gender: gender,
    );
  }

  static Future<void> upsertProfileForUserId({
    required String userId,
    String? email,
    Map<String, dynamic>? metadata,
    String? name,
    String? mobile,
    int? age,
    String? gender,
  }) async {
    final profileData = mergeProfileData(
      metadata: metadata,
      profileRow: {
        'name': name,
        'email': email,
        'mobile': mobile,
        'age': age,
        'gender': gender,
      },
    );
    await _upsertProfileRow(userId, profileData);
  }

  static Future<void> _upsertProfileRow(
    String userId,
    Map<String, dynamic> profileData,
  ) async {
    final payload = <String, dynamic>{
      'id': userId,
      ...profileData,
    }..removeWhere((key, value) => value == null);

    try {
      await _client.from('profiles').upsert(payload);
    } catch (_) {
      // The app can still fall back to auth metadata if the profiles table
      // is unavailable, so we keep auth flows resilient here.
    }
  }
}

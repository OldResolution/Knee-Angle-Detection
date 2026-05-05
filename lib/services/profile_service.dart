import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  ProfileService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static Map<String, dynamic> mergeProfileData({
    User? user,
    Map<String, dynamic>? profileRow,
    Map<String, dynamic>? metadata,
  }) {
    final resolvedMetadata = metadata ?? const <String, dynamic>{};

    final fallback = <String, dynamic>{
      'id': user?.uid,
      'email': user?.email,
      'name': resolvedMetadata['name'] ?? user?.displayName,
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
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final doc = await _firestore.collection('profiles').doc(user.uid).get();
      return mergeProfileData(
        user: user,
        profileRow: doc.exists ? doc.data() : null,
      );
    } catch (_) {
      return mergeProfileData(user: user);
    }
  }

  static Future<void> ensureCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    final merged = mergeProfileData(user: user);
    if (merged.isEmpty) {
      return;
    }

    await _upsertProfileRow(user.uid, merged);
  }

  static Future<void> upsertCurrentUserProfile({
    String? name,
    String? email,
    String? mobile,
    int? age,
    String? gender,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    await upsertProfileForUserId(
      userId: user.uid,
      email: email ?? user.email,
      metadata: const {},
      name: name ?? user.displayName,
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
      await _firestore.collection('profiles').doc(userId).set(payload, SetOptions(merge: true));
    } catch (_) {
      // The app can still fall back to auth metadata if the profiles table
      // is unavailable, so we keep auth flows resilient here.
    }
  }
}

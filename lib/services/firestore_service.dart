import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../models/user_model.dart';
import '../models/air_data_model.dart';
import '../models/issue_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // User Management
  static Future<void> createUser(AppUser user) async {
    try {
      await _firestore.collection('Users').doc(user.userId).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  static Future<AppUser?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('Users').doc(userId).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  static Future<void> updateUser(AppUser user) async {
    try {
      await _firestore.collection('Users').doc(user.userId).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Air Data Management
  static Future<void> saveAirData(AirData airData) async {
    try {
      await _firestore.collection('AirData').doc(airData.id).set(airData.toMap());
    } catch (e) {
      throw Exception('Failed to save air data: $e');
    }
  }

  static Future<List<AirData>> getAirData({int limit = 30}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('AirData')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AirData.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get air data: $e');
    }
  }

  static Stream<List<AirData>> getAirDataStream({int limit = 30}) {
    return _firestore
        .collection('AirData')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AirData.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Issue Management
  static Future<void> reportIssue(Issue issue) async {
    try {
      await _firestore.collection('${issue.type.toString().split('.').last}Issues').doc(issue.issueId).set(issue.toMap());
    } catch (e) {
      throw Exception('Failed to report issue: $e');
    }
  }

  static Future<List<Issue>> getIssues(IssueType type, {int limit = 50}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('${type.toString().split('.').last}Issues')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Issue.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get issues: $e');
    }
  }

  static Stream<List<Issue>> getIssuesStream(IssueType type, {int limit = 50}) {
    return _firestore
        .collection('${type.toString().split('.').last}Issues')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Issue.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  static Future<List<Issue>> getNearbyIssues(double latitude, double longitude, double radiusKm, IssueType type) async {
    try {
      // Simple bounding box query - for production, consider using GeoFlutterFire
      double latDelta = radiusKm / 111.0; // Approximate km per degree
      double lngDelta = radiusKm / (111.0 * math.cos(latitude * math.pi / 180));

      QuerySnapshot snapshot = await _firestore
          .collection('${type.toString().split('.').last}Issues')
          .where('latitude', isGreaterThanOrEqualTo: latitude - latDelta)
          .where('latitude', isLessThanOrEqualTo: latitude + latDelta)
          .where('longitude', isGreaterThanOrEqualTo: longitude - lngDelta)
          .where('longitude', isLessThanOrEqualTo: longitude + lngDelta)
          .get();

      return snapshot.docs
          .map((doc) => Issue.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get nearby issues: $e');
    }
  }

  // Analytics Data
  static Future<Map<String, int>> getIssueCountsByDate(IssueType type, DateTime startDate, DateTime endDate) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('${type.toString().split('.').last}Issues')
          .where('timestamp', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
          .where('timestamp', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
          .get();

      Map<String, int> counts = {};
      for (var doc in snapshot.docs) {
        Issue issue = Issue.fromMap(doc.data() as Map<String, dynamic>);
        String dateKey = '${issue.timestamp.year}-${issue.timestamp.month.toString().padLeft(2, '0')}-${issue.timestamp.day.toString().padLeft(2, '0')}';
        counts[dateKey] = (counts[dateKey] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get issue counts: $e');
    }
  }
}

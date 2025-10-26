import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  static Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? location,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User firebaseUser = result.user!;
      
      // Create user document in Firestore
      AppUser userModel = AppUser(
        userId: firebaseUser.uid,
        name: name,
        email: email,
        location: location,
        createdAt: DateTime.now(),
      );

      await FirestoreService.createUser(userModel);
      
      return firebaseUser;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with email and password
  static Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Update password
  static Future<void> updatePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      throw Exception('Password update failed: $e');
    }
  }

  // Get user profile from Firestore
  static Future<AppUser?> getUserProfile() async {
    try {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        return await FirestoreService.getUser(firebaseUser.uid);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile
  static Future<void> updateUserProfile(AppUser user) async {
    try {
      await FirestoreService.updateUser(user);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }
}

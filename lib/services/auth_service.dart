// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
// ✅ Added this import
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user profile is complete
  Future<bool> isProfileComplete() async {
    if (currentUser == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!doc.exists) return false;

      final data = doc.data();
      return data?['name'] != null &&
          data?['avatar'] != null &&
          data?['profileComplete'] == true;
    } catch (e) {
      print('Error checking profile: $e');
      return false;
    }
  }

  // Google Sign-In (Updated for v7.x)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Sign out first to force account picker
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('User cancelled Google Sign-In');
        return null;
      }

      // Obtain the auth details
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Get tokens
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        print('Failed to get tokens');
        return null;
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserDocument(userCredential.user!);
      }

      print('Google Sign-In successful: ${userCredential.user?.email}');
      return userCredential;

    } on FirebaseException catch (e) { // ✅ Fixed: Changed from FirebaseAuthException
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'profileComplete': false,
        'friendIds': [],
      }, SetOptions(merge: true));

      print('User document created: ${user.uid}');
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  // Complete user profile
  Future<bool> completeProfile({
    required String name,
    required String avatar,
  }) async {
    if (currentUser == null) return false;

    try {
      await _firestore.collection('users').doc(currentUser!.uid).set({
        'uid': currentUser!.uid,
        'email': currentUser!.email ?? '',
        'name': name,
        'avatar': avatar,
        'profileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'friendIds': [],
      }, SetOptions(merge: true));

      print('Profile completed: $name');
      return true;
    } catch (e) {
      print('Error completing profile: $e');
      return false;
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUser == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!doc.exists) {
        print('User document does not exist');
        return null;
      }

      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
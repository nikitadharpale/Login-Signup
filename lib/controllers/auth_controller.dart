import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Rx<User?> firebaseUser;
  RxBool isLoading = false.obs;

  @override
  void onReady() {
    super.onReady();
    firebaseUser = Rx<User?>(_auth.currentUser);
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _setInitialScreen);
  }

  /// Set initial screen based on auth state
  void _setInitialScreen(User? user) {
    if (user == null) {
      Get.offAll(() => const LoginScreen());
    } else {
      Get.offAll(() => const HomeScreen());
    }
  }

  /// Register new user with email & password
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection("users").doc(userCred.user!.uid).set({
        "uid": userCred.user!.uid,
        "name": name,
        "email": email,
        "phone": phone,
        "createdAt": DateTime.now(),
      });

      _showSnackbar("Success", "Account created successfully!");
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case "email-already-in-use":
          message = "This email is already registered.";
          break;
        case "invalid-email":
          message = "Invalid email address.";
          break;
        case "weak-password":
          message = "Password is too weak.";
          break;
        default:
          message = "Registration failed. Try again.";
      }
      _showSnackbar("Error", message, isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  /// Email/Password login
  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _showSnackbar("Welcome", "Logged in successfully!");
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case "user-not-found":
          message = "No user found with this email.";
          break;
        case "wrong-password":
          message = "Incorrect password.";
          break;
        case "invalid-email":
          message = "Invalid email address.";
          break;
        case "user-disabled":
          message = "This account has been disabled.";
          break;
        default:
          message = "Login failed. Try again.";
      }
      _showSnackbar("Error", message, isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  /// Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;

      UserCredential userCredential;

      if (kIsWeb) {
        // Web login
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile login
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        userCredential = await _auth.signInWithProvider(googleProvider);
      }

      final user = userCredential.user;
      if (user != null) {
        final userDoc = await _firestore.collection("users").doc(user.uid).get();

        if (!userDoc.exists) {
          // Create new user record if not exists
          await _firestore.collection("users").doc(user.uid).set({
            "uid": user.uid,
            "name": user.displayName ?? "No Name",
            "email": user.email,
            "photoUrl": user.photoURL,
            "createdAt": DateTime.now(),
            "loginMethod": "google",
          });
        }
      }

      _showSnackbar("Success", "Google login successful!");
      Get.offAll(() => const HomeScreen());
    } catch (e) {
      Get.snackbar(
        "Login Failed",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _showSnackbar("Logged out", "You have been signed out.");
    } catch (e) {
      _showSnackbar("Error", "Failed to logout. Try again.", isError: true);
    }
  }

  /// Fetch user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      final doc = await _firestore.collection("users").doc(uid).get();
      return doc.data();
    } catch (e) {
      _showSnackbar("Error", "Failed to load user data.", isError: true);
      return null;
    }
  }

  /// Custom Snackbar
  void _showSnackbar(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.red.shade100 : Colors.green.shade100,
      colorText: isError ? Colors.red.shade900 : Colors.green.shade900,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
    );
  }
}

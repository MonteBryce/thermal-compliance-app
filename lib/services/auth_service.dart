import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';

/// Dedicated authentication service for Firebase Auth operations
/// Handles email/password login, error mapping, and auth state management
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Get current authenticated user
  static User? get currentUser => _auth.currentUser;
  
  /// Stream of authentication state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// Store user ID securely in encrypted local storage
  static Future<void> _storeUserId(String uid) async {
    try {
      await SecureStorageService.storeUserId(uid);
      debugPrint('User ID stored securely (encrypted): $uid');
    } catch (e) {
      debugPrint('Failed to store user ID: $e');
    }
  }
  
  /// Retrieve stored user ID from encrypted local storage
  static Future<String?> getStoredUserId() async {
    try {
      final storedId = await SecureStorageService.getUserId();
      debugPrint('Retrieved stored user ID (encrypted): $storedId');
      return storedId;
    } catch (e) {
      debugPrint('Failed to retrieve stored user ID: $e');
      return null;
    }
  }
  
  /// Clear stored user ID from encrypted local storage
  static Future<void> _clearStoredUserId() async {
    try {
      await SecureStorageService.clearKey('user_id');
      debugPrint('Stored user ID cleared (encrypted storage)');
    } catch (e) {
      debugPrint('Failed to clear stored user ID: $e');
    }
  }
  
  /// Sign in with email and password
  /// Returns UserCredential on success, throws AuthException on failure
  static Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Store user ID and email securely for offline access
      if (credential.user?.uid != null) {
        await _storeUserId(credential.user!.uid);
        if (credential.user?.email != null) {
          await SecureStorageService.storeUserEmail(credential.user!.email!);
        }
        // Store auth token if available
        final idToken = await credential.user?.getIdToken();
        if (idToken != null) {
          await SecureStorageService.storeAuthToken(idToken);
        }
      }
      
      debugPrint('User signed in successfully: ${credential.user?.email}');
      return credential;
      
    } on FirebaseAuthException catch (e) {
      debugPrint('Authentication error: ${e.code} - ${e.message}');
      throw AuthException._fromFirebaseException(e);
    } catch (e) {
      debugPrint('Unexpected authentication error: $e');
      throw AuthException('An unexpected error occurred during sign in');
    }
  }
  
  /// Create user account with email and password
  static Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Store user ID and email securely for offline access
      if (credential.user?.uid != null) {
        await _storeUserId(credential.user!.uid);
        if (credential.user?.email != null) {
          await SecureStorageService.storeUserEmail(credential.user!.email!);
        }
        // Store auth token if available
        final idToken = await credential.user?.getIdToken();
        if (idToken != null) {
          await SecureStorageService.storeAuthToken(idToken);
        }
      }
      
      debugPrint('User account created: ${credential.user?.email}');
      return credential;
      
    } on FirebaseAuthException catch (e) {
      debugPrint('Account creation error: ${e.code} - ${e.message}');
      throw AuthException._fromFirebaseException(e);
    } catch (e) {
      debugPrint('Unexpected account creation error: $e');
      throw AuthException('An unexpected error occurred during account creation');
    }
  }
  
  /// Sign out current user
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      await SecureStorageService.clearAll(); // Clear all encrypted session data
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw AuthException('Failed to sign out');
    }
  }
  
  /// Get current user ID (UID)
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
  
  /// Get current user email
  static String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }
  
  /// Check if user is currently authenticated
  static bool get isAuthenticated => _auth.currentUser != null;
}

/// Custom exception class for authentication errors
class AuthException implements Exception {
  final String message;
  final String? code;
  
  const AuthException(this.message, [this.code]);
  
  /// Create AuthException from FirebaseAuthException
  factory AuthException._fromFirebaseException(FirebaseAuthException e) {
    String message;
    
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email address';
        break;
      case 'wrong-password':
        message = 'Incorrect password provided';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address';
        break;
      case 'user-disabled':
        message = 'This account has been disabled';
        break;
      case 'too-many-requests':
        message = 'Too many failed attempts. Please try again later';
        break;
      case 'weak-password':
        message = 'Password should be at least 6 characters';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email';
        break;
      case 'operation-not-allowed':
        message = 'Email/password accounts are not enabled';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your connection';
        break;
      default:
        message = e.message ?? 'An authentication error occurred';
    }
    
    return AuthException(message, e.code);
  }
  
  @override
  String toString() => 'AuthException: $message';
}
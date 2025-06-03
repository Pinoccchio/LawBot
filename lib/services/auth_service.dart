import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Get current user's Firebase UID
  String? get currentUserId => currentUser?.uid;

  // Sign up with email and password
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;

      if (user != null) {
        // Update display name in Firebase Auth only
        await user.updateDisplayName(fullName);

        // NO EMAIL VERIFICATION - removed sendEmailVerification()
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Re-authenticate user with password (required for sensitive operations)
  Future<bool> reauthenticateWithPassword(String password) async {
    try {
      if (currentUser == null) throw 'User not authenticated';
      if (currentUser!.email == null) throw 'User email not available';

      // Create credential with current user's email and password
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: password,
      );

      // Re-authenticate the user
      await currentUser!.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw 'Failed to verify password. Please try again.';
    }
  }

  // Delete user account (requires recent authentication)
  Future<void> deleteUserAccount() async {
    try {
      if (currentUser == null) throw 'User not authenticated';

      // Delete the Firebase user account
      await currentUser!.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Please verify your password to delete your account.';
      }
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw 'Failed to delete account: ${e.toString()}';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Failed to sign out. Please try again.';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw 'Failed to send reset email. Please try again.';
    }
  }

  // Update user profile (only in Firebase Auth)
  Future<void> updateUserDisplayName(String displayName) async {
    try {
      if (currentUser == null) throw 'User not authenticated';
      await currentUser!.updateDisplayName(displayName);
    } catch (e) {
      throw 'Failed to update display name. Please try again.';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      default:
        return e.message ?? 'An error occurred during authentication.';
    }
  }

  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get Firebase ID Token for Supabase authentication
  Future<String?> getIdToken() async {
    try {
      if (currentUser == null) return null;
      return await currentUser!.getIdToken();
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }
}
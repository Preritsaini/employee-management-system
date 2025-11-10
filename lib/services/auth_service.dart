import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/employee.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String role,
    bool isAdmin, {
    String? employeeId,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(name);

      Employee employee = Employee(
        id: credential.user!.uid,
        employeeId: employeeId ?? credential.user!.uid.substring(0, 8).toUpperCase(),
        name: name,
        email: email,
        role: role,
        createdAt: DateTime.now(),
        isAdmin: isAdmin,
      );

      try {
        await _firestore
            .collection('employees')
            .doc(credential.user!.uid)
            .set(employee.toMap());
      } on FirebaseException catch (firestoreError) {
        // If Firestore write fails, delete the auth user to clean up
        try {
          await credential.user?.delete();
        } catch (_) {}
        throw Exception('Firestore error (${firestoreError.code}): ${firestoreError.message ?? "Failed to save employee data"}');
      } catch (firestoreError) {
        // If Firestore write fails, delete the auth user to clean up
        try {
          await credential.user?.delete();
        } catch (_) {}
        rethrow;
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Authentication error: ';
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Email is already registered. Please use a different email.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak. Please use a stronger password.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        default:
          errorMessage = 'Authentication failed (${e.code}): ${e.message ?? "Unknown error"}';
      }
      throw Exception(errorMessage);
    } on FirebaseException catch (e) {
      throw Exception('Firebase error (${e.code}): ${e.message ?? "Unknown Firebase error"}');
    } catch (e) {
      // Extract the actual error message
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception: ')) {
        errorMsg = errorMsg.split('Exception: ').last;
      }
      throw Exception('Registration failed: $errorMsg');
    }
  }

  Future<Employee?> getCurrentEmployee() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      DocumentSnapshot doc =
          await _firestore.collection('employees').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return Employee.fromMap(doc.data() as Map<String, dynamic>, user.uid);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get employee data: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}



import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '/core/constants/app_constants.dart';
import '/core/domain/entities.dart';

// ═══════════════════════════════════════════════════════════
// AUTH VIEWMODEL — MVVM + Observer Pattern
// Handles: register, login, google sign-in, role assignment,
// profile management, logout, session management
// Implements ALL methods from class diagram UserEntity
// ═══════════════════════════════════════════════════════════
class AuthViewModel extends ChangeNotifier {
  // SINGLETON: Firebase instances
  final _auth    = FirebaseAuth.instance;
  final _db      = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _google  = GoogleSignIn();

  User?       _firebaseUser;
  UserEntity? _userEntity;
  bool        _isLoading = false;
  String?     _error;

  User?       get firebaseUser => _firebaseUser;
  UserEntity? get user         => _userEntity;
  bool        get isLoading    => _isLoading;
  String?     get error        => _error;
  bool        get isLoggedIn   => _firebaseUser != null;
  String?     get uid          => _firebaseUser?.uid;
  String?     get role         => _userEntity?.role;
  bool        get isStudent    => role == AppConstants.roleStudent;
  bool        get isInstructor => role == AppConstants.roleInstructor;
  bool        get isAdmin      => role == AppConstants.roleAdmin;

  // ── Initialize on app start ──
  Future<void> initialize() async {
    _firebaseUser = _auth.currentUser;
    if (_firebaseUser != null) {
      await _loadUserEntity(_firebaseUser!.uid);
    }
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      await _loadUserEntity(user.uid);
    } else {
      _userEntity = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserEntity(String uid) async {
    try {
      final doc = await _db.collection(AppConstants.usersCol).doc(uid).get();
      if (doc.exists) {
        _userEntity = _mapDocToEntity(doc);
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  UserEntity _mapDocToEntity(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final role = data['role'] as String? ?? AppConstants.roleStudent;
    final base = {
      'userId': doc.id,
      'name': data['name'] ?? '',
      'email': data['email'] ?? '',
      'role': role,
      'profilePicture': data['profilePicture'],
      'isActive': data['isActive'] ?? true,
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    };
    switch (role) {
      case AppConstants.roleInstructor:
        return InstructorEntity(
          userId: base['userId'] as String,
          name: base['name'] as String,
          email: base['email'] as String,
          createdAt: base['createdAt'] as DateTime,
          profilePicture: base['profilePicture'] as String?,
          isActive: base['isActive'] as bool,
          bio: data['bio'] ?? '',
          totalEarnings: (data['totalEarnings'] ?? 0).toDouble(),
        );
      case AppConstants.roleAdmin:
        return AdminEntity(
          userId: base['userId'] as String,
          name: base['name'] as String,
          email: base['email'] as String,
          createdAt: base['createdAt'] as DateTime,
          profilePicture: base['profilePicture'] as String?,
          isActive: base['isActive'] as bool,
        );
      default:
        return StudentEntity(
          userId: base['userId'] as String,
          name: base['name'] as String,
          email: base['email'] as String,
          createdAt: base['createdAt'] as DateTime,
          profilePicture: base['profilePicture'] as String?,
          isActive: base['isActive'] as bool,
        );
    }
  }

  // ── REGISTER (Class diagram: register()) ──
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    String role = AppConstants.roleStudent,
    String? bio,
  }) async {
    _setLoading(true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
      await cred.user!.updateDisplayName(name);

      final userData = {
        'name': name,
        'email': email,
        'role': role,
        'profilePicture': null,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        if (role == AppConstants.roleInstructor) 'bio': bio ?? '',
        if (role == AppConstants.roleInstructor) 'totalEarnings': 0.0,
      };

      await _db.collection(AppConstants.usersCol)
          .doc(cred.user!.uid).set(userData);
      await _loadUserEntity(cred.user!.uid);
      _setLoading(false);
      return null; // null = success
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _authError(e.code);
    }
  }

  // ── LOGIN (Class diagram: login()) ──
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email, password: password);
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _authError(e.code);
    }
  }

  // ── GOOGLE SIGN-IN ──
  Future<String?> signInWithGoogle({String role = AppConstants.roleStudent}) async {
    _setLoading(true);
    try {
      final googleUser = await _google.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return 'Google sign-in cancelled';
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      final uid = cred.user!.uid;

      // Create user doc if first time
      final doc = await _db.collection(AppConstants.usersCol).doc(uid).get();
      if (!doc.exists) {
        await _db.collection(AppConstants.usersCol).doc(uid).set({
          'name': cred.user!.displayName ?? 'User',
          'email': cred.user!.email ?? '',
          'role': role,
          'profilePicture': cred.user!.photoURL,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await _loadUserEntity(uid);
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return e.toString();
    }
  }

  // ── LOGOUT (Class diagram: logout()) ──
  Future<void> logout() async {
    await _google.signOut();
    await _auth.signOut();
    _userEntity = null;
    notifyListeners();
  }

  // ── MANAGE PROFILE (Class diagram: manageProfile()) ──
  Future<String?> updateProfile({
    required String name,
    String? bio,
    File? avatarFile,
  }) async {
    if (_firebaseUser == null) return 'Not logged in';
    _setLoading(true);
    try {
      String? photoUrl;
      if (avatarFile != null) {
        final ref = _storage.ref(
          '${AppConstants.avatarsPath}/${_firebaseUser!.uid}.jpg');
        await ref.putFile(avatarFile);
        photoUrl = await ref.getDownloadURL();
      }

      final updates = <String, dynamic>{'name': name};
      if (bio != null) updates['bio'] = bio;
      if (photoUrl != null) updates['profilePicture'] = photoUrl;

      await _db.collection(AppConstants.usersCol)
          .doc(_firebaseUser!.uid).update(updates);
      await _firebaseUser!.updateDisplayName(name);
      if (photoUrl != null) await _firebaseUser!.updatePhotoURL(photoUrl);
      await _loadUserEntity(_firebaseUser!.uid);
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return e.toString();
    }
  }

  // ── PASSWORD RESET ──
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  // ── Get Firebase ID Token for backend calls ──
  Future<String?> getIdToken() async {
    return await _firebaseUser?.getIdToken();
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void clearError() { _error = null; notifyListeners(); }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'email-already-in-use': return 'Email is already registered.';
      case 'invalid-email': return 'Please enter a valid email.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'too-many-requests': return 'Too many attempts. Please try later.';
      case 'network-request-failed': return 'Network error. Check your connection.';
      default: return 'Authentication failed. Please try again.';
    }
  }
}

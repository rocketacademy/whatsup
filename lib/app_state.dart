import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AppState extends ChangeNotifier {
  /// User information.
  String _userPhotoUrl;
  String _userDisplayName;
  String _userEmail;
  String _uid;

  /// User information getters.
  String get userPhotoUrl => _userPhotoUrl;
  String get userDisplayName => _userDisplayName;
  String get userEmail => _userEmail;

  /// Our authentication related classes.
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Our authentication getters.
  String get uid => _uid;

  AppState() {
    // Fetch user information if there is a session.
    initialiseAppState();
  }

  void initialiseAppState() async {
    // Confirms if user is signed in.
    final user = await _firebaseAuth.currentUser();

    if (user != null) {
      // Update user variables.
      _userPhotoUrl = user.photoUrl;
      _userDisplayName = user.displayName;
      _userEmail = user.email;
    }
    // Notifies listeners of variable changes.
    notifyListeners();
  }

  void signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleSignInAccount =
          await _googleSignIn.signIn().catchError((onError) {
        print('Error: $onError');
      });

      if (googleSignInAccount != null) {
        final googleAuth = await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.getCredential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final authResult = await _firebaseAuth.signInWithCredential(credential);
        final FirebaseUser user = authResult.user;

        // Confirms if user is signed in.
        assert(!user.isAnonymous);

        // Update user variables on Firestore.
        Firestore.instance.document('chats/main/users/${user.uid}').setData({
          'email': user.email,
          'name': user.displayName,
        });

        // Update user variables.
        _userPhotoUrl = user.photoUrl;
        _userDisplayName = user.displayName;
        _userEmail = user.email;
        _uid = user.uid;
      } else {
        return null;
      }
    } on PlatformException catch (e) {
      print('Error: $e');
    }
    // Notifies listeners of variable changes.
    notifyListeners();
  }

  void signOut() async {
    // Signs user out of Firebase.
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    // Update user variables.
    _userPhotoUrl = null;
    _userDisplayName = null;
    _userEmail = null;
    _uid = null;
    // Notifies listeners of variable changes.
    notifyListeners();
  }
}

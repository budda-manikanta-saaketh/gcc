import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInProvider extends ChangeNotifier {
  GoogleSignInAccount? _user;
  GoogleSignInAccount? get user => _user;

  GoogleSignInProvider() {
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    await GoogleSignIn.instance.initialize();

    GoogleSignIn.instance.authenticationEvents.listen((event) {
      _user = switch (event) {
        GoogleSignInAuthenticationEventSignIn() => event.user,
        GoogleSignInAuthenticationEventSignOut() => null,
      };
      notifyListeners();
    });
  }

  Future<void> googleLogin() async {
    try {
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        final result = await GoogleSignIn.instance.authenticate(
          scopeHint: ['email', 'profile'],
        );

        // Sign in to Firebase
        // final credential = GoogleAuthProvider.credential(
        //   accessToken: result.accessToken.token,
        //   idToken: result.idToken,
        // );
        // await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      print('Error signing in with Google: $e');
    }
  }

  Future<void> googleLogout() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}

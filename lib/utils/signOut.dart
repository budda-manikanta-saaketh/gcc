import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

Future<void> handleSignOut(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();
    // await GoogleSignIn().signOut();
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
    print("${FirebaseAuth.instance.currentUser?.email}");
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error signing out: $error')),
    );
  }
}

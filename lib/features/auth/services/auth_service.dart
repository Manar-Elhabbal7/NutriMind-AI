import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  /// Set your Google OAuth web client ID here for Chrome/web builds.
  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb && webClientId.isNotEmpty ? webClientId : null,
    scopes: ['email', 'profile'],
  );

  Future<GoogleSignInAccount?> signInWithGoogle() {
    return _googleSignIn.signIn();
  }

  Future<void> signOut() {
    return _googleSignIn.signOut();
  }
}

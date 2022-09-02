// @author Matthias Weigt 02.09.2022
// All rights reserved ©2022

import 'package:dart_easy_authenticator/domain/authentication_types/email_password.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

class EasyAuthenticator{
  static const String _emailPasswordBoxId = "dzEeFagES";
  static const String _emailKey = "jakflqoefgk";
  static const String _passwordKey = "asdaldqwfne";

  static bool initialized = false;


  static void init() async{
    await Hive.openBox(_emailPasswordBoxId);
    initialized = true;
  }

  static void _ensureIsInitialized() {
    if(!initialized) {
      throw StateError("call EasyAuthenticator.init() before accessing.");
    }
  }

  /// Registers a new User with email and password.
  Future<void> registerWithEmailAndPassword({required String email, required String password,Function? emailAlreadyInUse,Function? invalidEmail,Function? weakPassword,Function? otherError,Function? onSuccess}) async {
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if(onSuccess != null) {
        onSuccess();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        if(weakPassword!=null) {
          weakPassword();
        }
      } else if (e.code == 'email-already-in-use') {
        if(emailAlreadyInUse!=null) {
          emailAlreadyInUse();
        }
      } else if (e.code == 'invalid-email') {
        if(invalidEmail!=null) {
          invalidEmail();
        }
      }
    } catch (e) {
      if(otherError!=null) {
        otherError();
      }
    }

  }
  /// Logins a user with email and password.
  Future<void> loginWithEmailAndPassword({required String email,required String password,Function? wrongPassword,Function? userNotFound,Function? invalidEmail,Function? onSuccess}) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
          email: email,
          password: password);
      if(onSuccess != null) {
        onSuccess();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        if(userNotFound!=null) {
          userNotFound();
        }
      } else if (e.code == 'invalid-email') {
        if(invalidEmail!=null) {
          invalidEmail();
        }
      } else if (e.code == 'wrong-password') {
        if(wrongPassword!=null) {
          wrongPassword();
        }
      }
    }

  }
  /// Sings the user out.
  Future<void> signOut() async {
    await getFirebaseAuth().signOut();
  }
  /// Tells if the user is signed in.
  bool isSignedIn() {
    return getFirebaseAuth().currentUser != null;
  }
  /// Getter for a [FirebaseAuth] instance.
  FirebaseAuth getFirebaseAuth() {
    return FirebaseAuth.instance;
  }


  void writeEmailPassword({required String email,required String password}) {
    var box = _box;
    box.put(_emailKey, email);
    box.put(_passwordKey, password);
  }

  EmailPassword? readEmailPassword() {
    var box = _box;
    String? mail = box.get(_emailKey);
    String? password = box.get(_passwordKey);
    if(mail == null || password == null) {
      return null;
    }
    return EmailPassword(email: mail, password: password);
  }

  Box get _box{
    _ensureIsInitialized();
    return Hive.box(_emailPasswordBoxId);
  }

}
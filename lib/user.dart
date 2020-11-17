import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hello_me/database.dart';
import 'package:image_picker/image_picker.dart';

enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class UserRepository with ChangeNotifier {
  final _saved = Set<String>();
  final _savedLocally = Set<String>();
  var _avatarUrl;
  FirebaseAuth _auth;
  User _user;
  Status _status = Status.Uninitialized;

  UserRepository.instance() : _auth = FirebaseAuth.instance {
    _auth.authStateChanges().listen((event) {
      return _onAuthStateChanged(event);
    });
  }

  Status get status => _status;

  User get user => _user;

  Future<bool> signIn(String email, String password) async {
    try {
      print(email);
      print(password);
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      DocumentSnapshot userPrefs =
          await DatabaseServiceCloud(user.uid).getUserPreferences();
      try {
        final json = (userPrefs.get('favorites'));
        if (json != null) {
          json.forEach((element) {
            final fav = element.toString();
            print("Adding " + fav + " to local saved favorites.");
            _saved.add(fav);
          });
        }
      } catch (e) {}
      _status = Status.Authenticated;
      DatabaseServiceCloud(user.uid).updateUserFavorites(_saved);
      _avatarUrl = await DatabaseServiceCloud(user.uid).getAvatarUrl();
      notifyListeners();
      return true;
    } catch (e) {
      if (_status == Status.Authenticated) {
        _avatarUrl = null;
        return true;
      }
      _status = Status.Unauthenticated;
      notifyListeners();

      return false;
    }
  }

  Future signOut() async {
    _auth.signOut();
    _status = Status.Unauthenticated;
    _saved.clear();
    _avatarUrl = null;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future<void> _onAuthStateChanged(User user) async {
    if (user == null) {
      _status = Status.Unauthenticated;
    } else {
      _user = user;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }

  Future<bool> registerNewUser(String email, String pass) async {
    print("registerNewUser: registering user- email: " +
        email +
        " pass: " +
        pass);

    await _auth.createUserWithEmailAndPassword(email: email, password: pass);
    print(
        "registerNewUser: signing in user- email: " + email + " pass: " + pass);
    bool success = await signIn(email, pass);

    String log = success
        ? "registerNewUser: signed in succesfuly!"
        : "registerNewUser: sign in failed!";
    print("registerNewUser: user status is : " + status.toString());
    print(log);
    notifyListeners();
    return success;
  }

  getFavorites() {
    return _saved;
  }

  void removeFavorite(String pair) {
    print("user_repo: removeFavorite: removing pair: " + pair.toString());
    _saved.remove(pair);
    _savedLocally.remove(pair);
    notifyListeners();
    if (status == Status.Authenticated) {
      DatabaseServiceCloud(user.uid).updateUserFavorites(_saved);
    }
  }

  void addFavorite(String pair) {
    _saved.add(pair);
    _savedLocally.add(pair);
    notifyListeners();
    if (status == Status.Authenticated) {
      DatabaseServiceCloud(user.uid).updateUserFavorites(_saved);
    }
  }

  isFavorite(String wp) {
    return _saved.contains(wp);
  }

  getEmail() {
    return user.email;
  }

  String getUid() {
    return user.uid;
  }

  Future<PickedFile> chooseNewAvatar() async {
    var avatarImage = await DatabaseServiceCloud(user.uid).chooseFile();
    if(avatarImage == null){
      return null;
    }
    notifyListeners();
    String uploadedFileUrl =
        await DatabaseServiceCloud(user.uid).uploadAvatar(avatarImage);
    _avatarUrl = uploadedFileUrl;
    notifyListeners();
    return avatarImage;
  }


  String getAvatarUrl() {
    return _avatarUrl;
  }

  hasAvatar() {
    return _avatarUrl != null;
  }
}

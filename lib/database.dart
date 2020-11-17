import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class DatabaseServiceCloud {
  final String uid;
  final ImagePicker imagePicker = ImagePicker();
  final FirebaseStorage storage =
      FirebaseStorage.instanceFor(bucket: "gs://hellome-7b9a6.appspot.com");

  DatabaseServiceCloud(this.uid);

  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  Future updateUserFavorites(Set<String> favorites) async {
    List<String> favoritesList = favorites.toList();
    return users.doc(uid).set({'favorites': (favoritesList)});
  }

  Future<DocumentSnapshot> getUserPreferences() {
    return users.doc(uid).get();
  }

  Future<PickedFile> chooseFile() {
    return imagePicker.getImage(source: ImageSource.gallery);
  }

  Future<String> uploadAvatar(PickedFile avatarImage) async {
    var file = File(avatarImage.path);
    var storageRef = storage.ref().child("users/avatars/$uid");
    UploadTask uploadTask = storageRef.putFile(file);
    await uploadTask.whenComplete(() => null);
    var downloadUrl = await storageRef.getDownloadURL();
    return downloadUrl.toString();
  }

  getAvatarUrl() async {
    var storageRef = storage.ref().child("users/avatars/$uid");
    return storageRef.getDownloadURL();
  }
}

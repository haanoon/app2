import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'menu.dart';

class FirebaseService {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  static Future<List<MenuItem>> getMenuItems() async {
    final snapshot = await _firestore.collection('menuItems').get();
    return snapshot.docs.map((doc) => MenuItem.fromMap(doc.data())).toList();
  }

  static Future<void> addMenuItem(MenuItem item) async {
    await _firestore.collection('menuItems').doc(item.id).set(item.toMap());
  }

  static Future<void> updateMenuItem(MenuItem item) async {
    await _firestore.collection('menuItems').doc(item.id).update(item.toMap());
  }

  static Future<void> deleteMenuItem(String id) async {
    await _firestore.collection('menuItems').doc(id).delete();
  }

  static Future<String> uploadImage(File imageFile, String id) async {
    final ref = _storage.ref().child('menu_images/$id.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }
}

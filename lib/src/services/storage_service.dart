import 'package:cloud_firestore/cloud_firestore.dart';

const String _userCollection = 'users';
const String _userSubcollectionDocId = 'data';
const String _gameStateDocId = 'gameState';

class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDocRef(String userId) {
    return _firestore
        .collection(_userCollection)
        .doc(userId)
        .collection(_userSubcollectionDocId)
        .doc(_gameStateDocId);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserDataStream(String userId) {
    return _userDocRef(userId).snapshots();
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final docSnap = await _userDocRef(userId).get();
      if (docSnap.exists) {
        return docSnap.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> setUserData(String userId, Map<String, dynamic> data) async {
    if (userId.isEmpty) return false;
    try {
      await _userDocRef(userId).set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUserData(String userId) async {
    if (userId.isEmpty) return false;
    try {
      await _userDocRef(userId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
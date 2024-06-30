import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseServices {

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Authentication
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Create user error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // Database
  Future<void> saveUserData(String userId, Map<String, dynamic> userData) async {
    try {
      await _firebaseFirestore.collection('users').doc(userId).set(userData);
    } catch (e) {
      print('Save user data error: $e');
    }
  }

  Future<DocumentSnapshot> getUserData(String userId) async {
    try {
      return await _firebaseFirestore.collection('users').doc(userId).get();
    } catch (e) {
      print('Get user data error: $e');
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;
  String? get userId => _firebaseAuth.currentUser?.uid;

  String getUserId() {
    return _firebaseAuth.currentUser.uid;
  }

  String getCurrentUserName() {
    return _firebaseAuth.currentUser.displayName;
  }

  String getCurrentEmail() {
    return _firebaseAuth.currentUser.email;
  }

  final CollectionReference productsRef = FirebaseFirestore
    .instance
    .collection('Products');

  final CollectionReference usersCartRef = FirebaseFirestore
      .instance
      .collection('Users'); // TO STORE USERS CART | User-->userId->Cart-->productId

  final CollectionReference usersCartHistoryRef = FirebaseFirestore
      .instance
      .collection("UsersCartHistory");

  final CollectionReference userDetailsRef = FirebaseFirestore
      .instance
      .collection("UserDetails");

  Future<void> userSetup(String displayName) async {
    CollectionReference users = _firebaseFirestore.collection('UserDetails');

    String uid = getCurrentEmail().toString();
    String displayName = getCurrentUserName().toString();

    users.doc(getUserId()).set({'displayName': displayName, 'uid': uid});
    return;
  }
}

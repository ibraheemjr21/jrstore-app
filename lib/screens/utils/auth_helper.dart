import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> isUserLoggedIn() async {
  User? user = FirebaseAuth.instance.currentUser;

  // إذا كان المستخدم غير مسجل دخول
  if (user == null) {
    return false;
  }

  // تحقق مما إذا كان المستخدم موجودًا في قاعدة البيانات (Firestore)
  DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

  // إذا كانت البيانات غير موجودة في Firestore، هذا يعني أن الحساب تم حذفه
  if (!userDoc.exists) {
    return false; // حساب المستخدم محذوف من Firestore
  }

  return true; // المستخدم مسجل دخول وبياناته موجودة في Firestore
}

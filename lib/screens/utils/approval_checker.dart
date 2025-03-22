import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home_screen.dart';

Future<void> checkApprovalAndLogoutIfNeeded(BuildContext context) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final data = doc.data();

  if (data?['userType'] == 'store_owner' && data?['isApproved'] == false) {
    await FirebaseAuth.instance.signOut();

    // تأكد أنك ما فاتح هذا الـ Dialog مرتين
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text("تم سحب الموافقة", style: TextStyle(color: Colors.black)),
          content: Text("تم سحب الموافقة على حسابك كصاحب متجر. تم تسجيل خروجك.",
              style: TextStyle(color: Colors.black)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // يغلق الـ Dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => HomeScreen()),
                  (route) => false,
                );
              },
              child: Text("موافق", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    }
  }
}

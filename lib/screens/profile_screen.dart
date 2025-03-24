import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import '../screens/utils/approval_checker.dart'; // ✅ استيراد الفحص

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({required this.uid});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkApprovalAndLogoutIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الملف الشخصي'),
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return DrawerHeader(
                          decoration: BoxDecoration(color: Colors.green),
                          child: Text("مرحبًا بك"),
                        );
                      }

                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final userName = userData['userName'] ?? '';
                      final userType = userData['userType'] ?? '';

                      return FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('stores')
                            .where('ownerUid', isEqualTo: widget.uid)
                            .get(),
                        builder: (context, storeSnapshot) {
                          Widget myStoreSection = SizedBox();

                          if (userType == 'store_owner' &&
                              storeSnapshot.hasData &&
                              storeSnapshot.data!.docs.isNotEmpty) {
                            final storeData = storeSnapshot.data!.docs.first
                                .data() as Map<String, dynamic>;
                            final storeName = storeData['name'] ?? '';
                            final imageUrl = storeData['imageUrl'] ?? '';

                            myStoreSection = Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(color: Colors.white),
                                  Text("🛒 متجري",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Image.asset(
                                            'assets/images/logo.png',
                                            width: 50,
                                            height: 50,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          storeName,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DrawerHeader(
                                decoration: BoxDecoration(color: Colors.green),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.white,
                                      child: Icon(Icons.person,
                                          size: 40, color: Colors.green),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'مرحبًا بك $userName',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'في متجر JrStore 👋',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              myStoreSection,
                            ],
                          );
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.category, color: Colors.white),
                    title:
                        Text('الفئات', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.white),
                    title: Text('تسجيل الخروج',
                        style: TextStyle(color: Colors.white)),
                    onTap: () async {
                      Navigator.pop(context);
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 50,
                ),
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("تعذر تحميل البيانات"));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRow("اسم المستخدم:", data['userName']),
                _buildRow("البريد الإلكتروني:", data['email']),
                _buildRow("العمر:", data['age'].toString()),
                _buildRow("البلد:", data['country']),
                _buildRow("نوع الحساب:",
                    data['userType'] == 'store_owner' ? "صاحب متجر" : "مشتري"),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

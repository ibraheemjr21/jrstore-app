// ✅ كرت متجر منسق، بيانات المتجر كلها على اليمين، والصورة تبقى على اليسار

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jr_store/screens/create_store_screen.dart';
import 'home_screen.dart';
import '../screens/utils/approval_checker.dart';
import 'profile_screen.dart';

class CategoryStoresScreen extends StatefulWidget {
  final String categoryName;

  const CategoryStoresScreen({required this.categoryName});

  @override
  _CategoryStoresScreenState createState() => _CategoryStoresScreenState();
}

class _CategoryStoresScreenState extends State<CategoryStoresScreen> {
  String? userType;
  String? userUid;
  String? userName;
  bool hasStore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkApprovalAndLogoutIfNeeded(context);
      await _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = userDoc.data();
    if (data == null) return;

    userType = data['userType'];
    userUid = user.uid;
    userName = data['userName'];

    final storeQuery = await FirebaseFirestore.instance
        .collection('stores')
        .where('ownerUid', isEqualTo: user.uid)
        .get();

    setState(() {
      hasStore = storeQuery.docs.isNotEmpty;
    });
  }

  // void _logout(BuildContext context) async {
  //   await FirebaseAuth.instance.signOut();
  //   Navigator.pushAndRemoveUntil(
  //     context,
  //     MaterialPageRoute(builder: (context) => HomeScreen()),
  //     (Route<dynamic> route) => false,
  //   );
  // }
  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return SizedBox();

    return Drawer(
      backgroundColor: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get(),
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
                          .where('ownerUid', isEqualTo: user.uid)
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
                                            color: Colors.white, fontSize: 16),
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
                                  Text('في متجر JrStore 👋',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
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
                  title: Text('الفئات', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person, color: Colors.white),
                  title: Text('الملف الشخصي',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfileScreen(uid: currentUser.uid),
                        ),
                      );
                    }
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(widget.categoryName),
      ),
      drawer: _buildDrawer(),
      body: userType == 'store_owner'
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateStoreScreen(
                              categoryName: widget.categoryName),
                        ),
                      );
                    },
                    icon: Icon(Icons.add_business),
                    label: Text("إنشاء متجرك الآن"),
                  ),
                  SizedBox(height: 20),
                  if (hasStore)
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('stores')
                          .where('ownerUid', isEqualTo: userUid)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Text("لا يوجد متجر.");
                        }

                        final storeDoc = snapshot.data!.docs.first;
                        final storeData =
                            storeDoc.data() as Map<String, dynamic>;
                        if (!storeData['categories']
                            .contains(widget.categoryName)) {
                          return SizedBox();
                        }

                        final storeName = storeData['name'];
                        final storePhone = storeData['phone'];
                        final isApproved = storeData['isApproved'] ?? false;
                        final imageUrl = storeData['imageUrl'] ?? '';
                        final ownerUid = storeData['ownerUid'];

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(ownerUid)
                              .get(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) {
                              return CircularProgressIndicator();
                            }

                            final userData = userSnapshot.data!.data()
                                as Map<String, dynamic>;
                            final ownerName =
                                userData['userName'] ?? 'غير معروف';
                            final country = userData['country'] ?? 'غير محدد';

                            return Card(
                              color: Colors.green[800],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        imageUrl,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Image.asset(
                                          'assets/images/logo.png',
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            storeName,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text("📞 $storePhone",
                                              style: TextStyle(
                                                  color: Colors.white70)),
                                          Text(
                                              "الحالة: ${isApproved ? 'مفتوح ✅' : 'مغلق ⛔'}",
                                              style: TextStyle(
                                                  color: Colors.white70)),
                                          Text("مالك المتجر: $ownerName",
                                              style: TextStyle(
                                                  color: Colors.white70)),
                                          Text("البلد: $country",
                                              style: TextStyle(
                                                  color: Colors.white70)),
                                          SizedBox(height: 10),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        CreateStoreScreen(
                                                      categoryName:
                                                          widget.categoryName,
                                                      storeId: storeDoc.id,
                                                      existingData: storeData,
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon: Icon(Icons.edit),
                                              label: Text("تعديل المتجر"),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.green,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            )
          : Container(),
    );
  }
}

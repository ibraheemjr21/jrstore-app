import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_stores_screen.dart';
import 'register_screen.dart';
import '../models/category.dart';
import '../screens/utils/auth_helper.dart';
import 'profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/utils/approval_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>> getUserAndStoreData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return {};

  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final storeQuery = await FirebaseFirestore.instance
      .collection('stores')
      .where('ownerUid', isEqualTo: user.uid)
      .get();

  return {
    'user': userDoc,
    'store': storeQuery.docs.isNotEmpty ? storeQuery.docs.first : null,
  };
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategory;

  Future<void> loadSelectedCategory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCategory = prefs.getString('lastCategory');
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkApprovalAndLogoutIfNeeded(context);
    });
    loadSelectedCategory();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, userSnapshot) {
        final isGuest = userSnapshot.data == null;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.green,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 50,
                ),
                Text(
                  "اختر فئة المشروع",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
                      FutureBuilder<Map<String, dynamic>>(
                        future: getUserAndStoreData(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting ||
                              !snapshot.hasData) {
                            return DrawerHeader(
                              decoration: BoxDecoration(color: Colors.green),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white)),
                            );
                          }

                          final userDocRaw = snapshot.data?['user'];
                          if (userDocRaw == null ||
                              userDocRaw is! DocumentSnapshot) {
                            return DrawerHeader(
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
                                  Text('مرحبًا بك',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  Text('في متجر JrStore 👋',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                ],
                              ),
                            );
                          }

                          final userDoc = userDocRaw as DocumentSnapshot;
                          final storeSnapshot = snapshot.data?['store'];
                          Map<String, dynamic>? storeData;
                          String storeName = '';
                          String imageUrl = '';

                          if (storeSnapshot != null) {
                            try {
                              storeData = (storeSnapshot as dynamic).data()
                                  as Map<String, dynamic>?;
                              storeName = storeData?['name'] ?? '';
                              imageUrl = storeData?['imageUrl'] ?? '';
                            } catch (e) {
                              print('خطأ أثناء قراءة بيانات المتجر: $e');
                            }
                          }

                          if (!userDoc.exists) {
                            return DrawerHeader(
                              decoration: BoxDecoration(color: Colors.green),
                              child: Text("مرحبًا بك"),
                            );
                          }

                          final userData =
                              userDoc.data() as Map<String, dynamic>;
                          final userName = userData['userName'] ?? '';
                          final userType = userData['userType'] ?? '';

                          Widget myStoreSection = SizedBox();

                          if (userType == 'store_owner' && storeData != null) {
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
                                                      height: 50),
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
                                    Text('مرحبًا بك $userName',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
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
                      ),
                      ListTile(
                        leading: Icon(Icons.person, color: Colors.white),
                        title: Text('الملف الشخصي',
                            style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pop(context);
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      ProfileScreen(uid: user.uid)),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RegisterScreen()),
                            );
                          }
                        },
                      ),
                      if (FirebaseAuth.instance.currentUser != null)
                        ListTile(
                          leading: Icon(Icons.logout, color: Colors.white),
                          title: Text('تسجيل الخروج',
                              style: TextStyle(color: Colors.white)),
                          onTap: () async {
                            Navigator.pop(context);
                            await FirebaseAuth.instance.signOut();
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
                            offset: Offset(0, 3)),
                      ],
                    ),
                    child: Image.asset('assets/images/logo.png', height: 50),
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              if (isGuest)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.login),
                    label: Text("تسجيل الدخول أو إنشاء حساب"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.black,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RegisterScreen()),
                      );
                    },
                  ),
                ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('categories')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text("حدث خطأ أثناء تحميل الفئات",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.red)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                          child: Text("لا توجد فئات متاحة",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.white)));
                    }

                    List<Category> categories = snapshot.data!.docs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return Category.fromMap(data);
                    }).toList();

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected =
                              _selectedCategory == category.title;

                          return InkWell(
                            borderRadius: BorderRadius.circular(15),
                            splashColor: Colors.white24,
                            onTap: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString(
                                  'lastCategory', category.title);

                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) {
                                  return Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.green));
                                },
                              );

                              bool isLoggedIn = await isUserLoggedIn();
                              Navigator.pop(context);

                              if (isLoggedIn) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CategoryStoresScreen(
                                      categoryName: category.title,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RegisterScreen(
                                      categoryName: category.title,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.green[700]
                                    : Colors.green,
                                borderRadius: BorderRadius.circular(15),
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  category.image.isNotEmpty
                                      ? Image.asset(
                                          category.image,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : Icon(Icons.image_not_supported,
                                          size: 80, color: Colors.white),
                                  SizedBox(height: 10),
                                  Text(
                                    category.title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

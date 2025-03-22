import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_stores_screen.dart';
import 'register_screen.dart';
import '../models/category.dart';
import '../screens/utils/auth_helper.dart';
import 'profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/utils/approval_checker.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkApprovalAndLogoutIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
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
                // 🔼 الجزء العلوي: DrawerHeader + العناصر
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      StreamBuilder<User?>(
                        stream: FirebaseAuth.instance.authStateChanges(),
                        builder: (context, userSnapshot) {
                          final user = userSnapshot.data;

                          if (user == null) {
                            // المستخدم غير مسجل دخول
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
                                  Text(
                                    'مرحبًا بك',
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
                            );
                          } else {
                            // المستخدم مسجل دخول
                            return StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                String userName = '';
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  var data = snapshot.data!.data()
                                      as Map<String, dynamic>;
                                  userName = data['userName'];
                                }

                                return DrawerHeader(
                                  decoration:
                                      BoxDecoration(color: Colors.green),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                );
                              },
                            );
                          }
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
                                    ProfileScreen(uid: user.uid),
                              ),
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

                // 🔽 الجزء السفلي: اللوجو بأسفل الشاشة
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
          body: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('categories').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print("Error: \${snapshot.error}");
                return Center(
                    child: Text("حدث خطأ أثناء تحميل الفئات",
                        style: TextStyle(fontSize: 18, color: Colors.red)));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                    child: Text("لا توجد فئات متاحة",
                        style: TextStyle(fontSize: 18, color: Colors.white)));
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

                    return GestureDetector(
                      onTap: () async {
                        bool isLoggedIn = await isUserLoggedIn();

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
                              builder: (context) =>
                                  RegisterScreen(categoryName: category.title),
                            ),
                          );
                        }
                      },
                      child: Card(
                        color: Colors.green,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            category.image.isNotEmpty
                                ? Image.asset(
                                    category.image,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(Icons.image_not_supported,
                                    size: 80, color: Colors.white),
                            SizedBox(height: 10),
                            Text(
                              category.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
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
        );
      },
    );
  }
}

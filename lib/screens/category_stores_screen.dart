import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jr_store/screens/create_store_screen.dart';
import 'store_products_screen.dart';
import '../models/store.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../screens/utils/approval_checker.dart';

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

    // التحقق هل لديه متجر
    final storeQuery = await FirebaseFirestore.instance
        .collection('stores')
        .where('ownerUid', isEqualTo: user.uid)
        .get();

    setState(() {
      hasStore = storeQuery.docs.isNotEmpty;
    });
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(widget.categoryName),
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
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      String userName = '';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        var data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        userName = data['userName'];
                      }

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
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
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
                    leading: Icon(Icons.person, color: Colors.white),
                    title: Text('الملف الشخصي',
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(uid: uid),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.white),
                    title: Text('تسجيل الخروج',
                        style: TextStyle(color: Colors.white)),
                    onTap: () => _logout(context),
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
      body: userType == 'store_owner'
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // داخل _CategoryStoresScreenState
                  ElevatedButton.icon(
                    onPressed: () {
                      // انتقل إلى صفحة إنشاء المتجر مع تمرير اسم الفئة
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
                          return SizedBox(); // لا تعرض المتجر إذا الفئة لا تطابق
                        }

                        final storeName = storeData['name'];
                        final storePhone = storeData['phone'];
                        final isApproved = storeData['isApproved'] ?? false;

                        return Card(
                          color: Colors.green[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              storeName,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "📞 $storePhone\nالحالة: ${isApproved ? 'مفتوح ✅' : 'مغلق ⛔'}",
                              style: TextStyle(color: Colors.white70),
                            ),
                            trailing: Icon(Icons.store, color: Colors.white),
                            onTap: () {
                              // لاحقًا: الدخول لإدارة المتجر
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stores')
                  .where('category', isEqualTo: widget.categoryName)
                  .where('isApproved',
                      isEqualTo: true) // ✅ فقط المتاجر المعتمدة
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_mall_directory,
                            size: 60, color: Colors.white70),
                        SizedBox(height: 10),
                        Text(
                          "لا توجد متاجر لهذه الفئة حاليًا",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  );
                }

                List<Store> stores = snapshot.data!.docs
                    .map((doc) => Store.fromMap(
                        doc.data() as Map<String, dynamic>, doc.id))
                    .toList();

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: stores.length,
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      return Card(
                        color: Colors.green[800],
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          title: Text(
                            store.name,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "المالك: ${store.owner} | 📞 ${store.phone}",
                            style: TextStyle(color: Colors.white70),
                          ),
                          trailing: Icon(Icons.store, color: Colors.white),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    StoreProductsScreen(storeId: store.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

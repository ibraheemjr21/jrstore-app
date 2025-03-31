// ✅ كرت متجر منسق، بيانات المتجر كلها على اليمين، والصورة تبقى على اليسار

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jr_store/screens/create_store_screen.dart';
import 'home_screen.dart';
import '../screens/utils/approval_checker.dart';
import 'profile_screen.dart';
import 'dart:async';

class CategoryStoresScreen extends StatefulWidget {
  final String categoryName;

  const CategoryStoresScreen({required this.categoryName});

  @override
  _CategoryStoresScreenState createState() => _CategoryStoresScreenState();
}

class _CategoryStoresScreenState extends State<CategoryStoresScreen> {
  Timer? _refreshTimer;
  String? userType;
  String? userUid;
  String? userName;
  bool hasStore = false;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkApprovalAndLogoutIfNeeded(context);
      await _loadUserData();
      _refreshTimer = Timer.periodic(Duration(minutes: 1), (_) {
        if (mounted) setState(() {}); // يعيد بناء الواجهة كل دقيقة
      });
    });
  }

  bool isStoreOpen(Map<String, dynamic> workingHoursMap) {
    final now = DateTime.now();
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final today = days[now.weekday - 1];

    if (!workingHoursMap.containsKey(today)) return false;

    try {
      final todayHours = workingHoursMap[today];

      if (todayHours is String) {
        print("❌ workingHours[$today] is a String: $todayHours");
        return false;
      }

      final openStr = todayHours['open'] as String;
      final closeStr = todayHours['close'] as String;

      final openTimeParts = openStr.split(':');
      final closeTimeParts = closeStr.split(':');

      final openHour = int.parse(openTimeParts[0]);
      final openMinute = int.parse(openTimeParts[1].split(' ')[0]);
      final openPeriod = openStr.contains('PM') ? 12 : 0;

      final closeHour = int.parse(closeTimeParts[0]);
      final closeMinute = int.parse(closeTimeParts[1].split(' ')[0]);
      final closePeriod = closeStr.contains('PM') ? 12 : 0;

      final openTime =
          TimeOfDay(hour: openHour % 12 + openPeriod, minute: openMinute);
      final closeTime =
          TimeOfDay(hour: closeHour % 12 + closePeriod, minute: closeMinute);

      final nowTime = TimeOfDay.fromDateTime(now);

      final isAfterOpen = nowTime.hour > openTime.hour ||
          (nowTime.hour == openTime.hour && nowTime.minute >= openTime.minute);

      final isBeforeClose = nowTime.hour < closeTime.hour ||
          (nowTime.hour == closeTime.hour && nowTime.minute < closeTime.minute);

      print(
          "✅ NOW: ${nowTime.format(context)} | OPEN: ${openTime.format(context)} | CLOSE: ${closeTime.format(context)}");

      return isAfterOpen && isBeforeClose;
    } catch (e) {
      print("❌ Error in isStoreOpen: $e");
      return false;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('stores')
                          .where('ownerUid', isEqualTo: userUid)
                          .snapshots(),
                      builder: (context, storeSnapshot) {
                        Widget myStoreSection = SizedBox();

                        if (userType == 'store_owner' &&
                            storeSnapshot.hasData &&
                            storeSnapshot.data!.docs.isNotEmpty) {
                          final storeData = storeSnapshot.data!.docs.first
                              .data() as Map<String, dynamic>;
                          final bool isCurrentlyOpen =
                              isStoreOpen(storeData['workingHours']);
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
    if (userType == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: Text(widget.categoryName),
        ),
        drawer: _buildDrawer(),
        body: Center(child: CircularProgressIndicator()), // ⏳ تحميل
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(widget.categoryName),
      ),
      drawer: _buildDrawer(),
      body: userType == 'store_owner'
          ? _buildStoreOwnerView()
          : _buildBuyerView(),
    );
  }

  Widget _buildStoreOwnerView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CreateStoreScreen(categoryName: widget.categoryName),
                ),
              );
            },
            icon: Icon(Icons.add_business),
            label: Text("إنشاء متجرك الآن"),
          ),
          SizedBox(height: 20),
          if (hasStore)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stores')
                  .where('ownerUid', isEqualTo: userUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }

                if (snapshot.data!.docs.isEmpty && !_dialogShown) {
                  _dialogShown = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text("تم حذف المتجر"),
                        content: Text(
                          "تم حذف متجرك من قبل الإدارة.\nيرجى التواصل مع الإدارة.",
                          style: TextStyle(color: Colors.black),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              setState(() {
                                hasStore = false;
                              });
                            },
                            child: Text("موافق"),
                          ),
                        ],
                      ),
                    );
                  });
                  return SizedBox();
                }

                final storeDoc = snapshot.data!.docs.first;
                final storeData = storeDoc.data() as Map<String, dynamic>;
                final bool isCurrentlyOpen =
                    isStoreOpen(storeData['workingHours']);

                if (!storeData['categories'].contains(widget.categoryName)) {
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

                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    final ownerName = userData['userName'] ?? 'غير معروف';
                    final country = userData['country'] ?? 'غير محدد';

                    return Card(
                      color: Colors.green[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
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
                              child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "🏪 $storeName",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text("👤 المالك: $ownerName",
                                        style:
                                            TextStyle(color: Colors.white70)),
                                    Text("📞 الهاتف: $storePhone",
                                        style:
                                            TextStyle(color: Colors.white70)),
                                    WorkingHoursWidget(
                                      workingHours: Map<String, dynamic>.from(
                                          storeData['workingHours'] ?? {}),
                                    ),
                                    Text("📍 الدولة: $country",
                                        style:
                                            TextStyle(color: Colors.white70)),
                                    Text(
                                      "✅ الحالة: ${isApproved ? (isCurrentlyOpen ? 'مفتوح ✅' : 'مغلق الآن ⛔') : 'قيد المراجعة ⏳'}",
                                      style: TextStyle(
                                        color: isApproved
                                            ? (isCurrentlyOpen
                                                ? Colors.lightGreenAccent
                                                : Colors.redAccent)
                                            : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 12),
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
                                          foregroundColor: Colors.green[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
    );
  }

  Widget _buildBuyerView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stores')
          .where('categories', arrayContains: widget.categoryName)
          .where('isApproved', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("لا توجد متاجر في هذه الفئة"));
        }

        final stores = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: stores.length,
          itemBuilder: (context, index) {
            final storeData = stores[index].data() as Map<String, dynamic>;
            final storeName = storeData['name'] ?? '';
            final imageUrl = storeData['imageUrl'] ?? '';
            final storePhone = storeData['phone'] ?? '';
            final isApproved = storeData['isApproved'] ?? false;
            final bool isCurrentlyOpen = isStoreOpen(storeData['workingHours']);
            final ownerUid = storeData['ownerUid'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(ownerUid)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return SizedBox();
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final ownerName = userData['userName'] ?? 'غير معروف';
                final country = userData['country'] ?? 'غير محدد';

                return Card(
                  color: Colors.green[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
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
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "🏪 $storeName",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text("👤 المالك: $ownerName",
                                    style: TextStyle(color: Colors.white70)),
                                Text("📞 الهاتف: $storePhone",
                                    style: TextStyle(color: Colors.white70)),
                                WorkingHoursWidget(
                                  workingHours: Map<String, dynamic>.from(
                                      storeData['workingHours'] ?? {}),
                                ),
                                Text("📍 الدولة: $country",
                                    style: TextStyle(color: Colors.white70)),
                                Text(
                                  "✅ الحالة: ${isApproved ? (isCurrentlyOpen ? 'مفتوح ✅' : 'مغلق الآن ⛔') : 'قيد المراجعة ⏳'}",
                                  style: TextStyle(
                                    color: isApproved
                                        ? (isCurrentlyOpen
                                            ? Colors.lightGreenAccent
                                            : Colors.redAccent)
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class WorkingHoursWidget extends StatefulWidget {
  final Map<String, dynamic> workingHours;

  const WorkingHoursWidget({required this.workingHours});

  @override
  _WorkingHoursWidgetState createState() => _WorkingHoursWidgetState();
}

class _WorkingHoursWidgetState extends State<WorkingHoursWidget> {
  bool _expanded = false;

  final arabicDays = {
    'saturday': 'السبت',
    'sunday': 'الأحد',
    'monday': 'الإثنين',
    'tuesday': 'الثلاثاء',
    'wednesday': 'الأربعاء',
    'thursday': 'الخميس',
    'friday': 'الجمعة',
  };

  String getTodayName() {
    final now = DateTime.now();
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return days[now.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final today = getTodayName();
    final todayHours = widget.workingHours[today];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            "🕒 اليوم: ${arabicDays[today]} (${todayHours != null ? "${todayHours['open']} - ${todayHours['close']}" : "غير محدد"})",
            style: TextStyle(color: Colors.white70),
          ),
        ),
        if (_expanded) ...[
          SizedBox(height: 8),
          ...widget.workingHours.entries.map((entry) {
            final day = entry.key;
            final data = entry.value;
            return Text(
              "${arabicDays[day]}: ${data['open']} - ${data['close']}",
              style: TextStyle(color: Colors.white60, fontSize: 13),
            );
          }).toList(),
        ],
      ],
    );
  }
}

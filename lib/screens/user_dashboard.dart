// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'home_screen.dart';
// import 'profile_screen.dart';

// class UserDashboard extends StatefulWidget {
//   @override
//   _UserDashboardState createState() => _UserDashboardState();
// }

// class _UserDashboardState extends State<UserDashboard> {
//   bool _welcomeMessageShown = false;
//   bool _dialogShown = false;
//   bool _userDeleted = false;

//   @override
//   Widget build(BuildContext context) {
//     User? user = FirebaseAuth.instance.currentUser;
//     String uid = user?.uid ?? '';

//     if (user == null) {
//       Future.delayed(Duration.zero, () {
//         if (context.mounted) {
//           Navigator.of(context).pushAndRemoveUntil(
//             MaterialPageRoute(builder: (context) => HomeScreen()),
//             (Route<dynamic> route) => false,
//           );
//         }
//       });
//       return Scaffold(
//         appBar: AppBar(
//           title: Text('واجهة المستخدم'),
//         ),
//         drawer: Drawer(
//           child: ListView(
//             padding: EdgeInsets.zero,
//             children: [
//               DrawerHeader(
//                 decoration: BoxDecoration(color: Colors.green),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     CircleAvatar(
//                       radius: 30,
//                       backgroundColor: Colors.white,
//                       child: Icon(Icons.person, size: 40, color: Colors.green),
//                     ),
//                     SizedBox(height: 10),
//                     Text(
//                       'مرحبًا بك 👋',
//                       style: TextStyle(color: Colors.white, fontSize: 18),
//                     ),
//                   ],
//                 ),
//               ),
//               ListTile(
//                 leading: Icon(Icons.person),
//                 title: Text('الملف الشخصي'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ProfileScreen(uid: uid),
//                     ),
//                   );
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.logout),
//                 title: Text('تسجيل الخروج'),
//                 onTap: () async {
//                   Navigator.pop(context);
//                   await FirebaseAuth.instance.signOut();
//                   Navigator.pushAndRemoveUntil(
//                     context,
//                     MaterialPageRoute(builder: (context) => HomeScreen()),
//                     (route) => false,
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//         body: Center(
//           child: Text('أهلاً بك في واجهة المستخدم'),
//         ),
//       );
//     }

//     return StreamBuilder<DocumentSnapshot>(
//       stream:
//           FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Scaffold(body: Center(child: CircularProgressIndicator()));
//         }

//         if (snapshot.hasError) {
//           return Scaffold(
//             body: Center(
//               child: Text(
//                 "حدث خطأ في تحميل البيانات",
//                 style: TextStyle(fontSize: 18, color: Colors.red),
//               ),
//             ),
//           );
//         }

//         if (!snapshot.hasData ||
//             snapshot.data == null ||
//             !snapshot.data!.exists) {
//           if (!_userDeleted) {
//             _userDeleted = true;
//             FirebaseAuth.instance.signOut();
//             Future.delayed(Duration.zero, () {
//               if (context.mounted) {
//                 Navigator.of(context).pushAndRemoveUntil(
//                   MaterialPageRoute(builder: (context) => HomeScreen()),
//                   (Route<dynamic> route) => false,
//                 );
//               }
//             });
//           }
//           return Scaffold(body: Center(child: CircularProgressIndicator()));
//         }

//         var userData = snapshot.data!.data() as Map<String, dynamic>?;
//         if (userData == null) {
//           return Scaffold(
//             body: Center(child: Text("بيانات المستخدم غير موجودة")),
//           );
//         }

//         bool isStoreOwner = userData['userType'] == 'store_owner';
//         bool isApproved = userData['isApproved'] ?? false;

//         if (isStoreOwner && !isApproved && !_dialogShown) {
//           _dialogShown = true;
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showPendingDialog(context);
//           });
//         }

//         if (isStoreOwner && isApproved && !_welcomeMessageShown) {
//           _welcomeMessageShown = true;
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showWelcomeMessage(context);
//           });
//         }

//         return Scaffold(
//           appBar: AppBar(
//             title: Text('واجهة المستخدم'),
//           ),
//           drawer: Drawer(
//             child: ListView(
//               padding: EdgeInsets.zero,
//               children: [
//                 DrawerHeader(
//                   decoration: BoxDecoration(color: Colors.green),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       CircleAvatar(
//                         radius: 30,
//                         backgroundColor: Colors.white,
//                         child:
//                             Icon(Icons.person, size: 40, color: Colors.green),
//                       ),
//                       SizedBox(height: 10),
//                       Text(
//                         'مرحبًا بك 👋',
//                         style: TextStyle(color: Colors.white, fontSize: 18),
//                       ),
//                     ],
//                   ),
//                 ),
//                 ListTile(
//                   leading: Icon(Icons.person),
//                   title: Text('الملف الشخصي'),
//                   onTap: () {
//                     Navigator.pop(context);
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => ProfileScreen(uid: uid),
//                       ),
//                     );
//                   },
//                 ),
//                 ListTile(
//                   leading: Icon(Icons.logout),
//                   title: Text('تسجيل الخروج'),
//                   onTap: () async {
//                     Navigator.pop(context);
//                     await FirebaseAuth.instance.signOut();
//                     Navigator.pushAndRemoveUntil(
//                       context,
//                       MaterialPageRoute(builder: (context) => HomeScreen()),
//                       (route) => false,
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//           body: Center(
//             child: Text('أهلاً بك في واجهة المستخدم'),
//           ),
//         );
//       },
//     );
//   }

//   void _showPendingDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//           title: Text(
//             "طلب قيد المراجعة",
//             style: TextStyle(
//                 fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
//           ),
//           content: Text(
//             "تم تقديم طلبك لإنشاء حساب صاحب متجر.\nيرجى انتظار الموافقة من الإدارة قبل تسجيل الدخول.",
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.black),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 FirebaseAuth.instance.signOut();
//                 Navigator.pushAndRemoveUntil(
//                   context,
//                   MaterialPageRoute(builder: (context) => HomeScreen()),
//                   (Route<dynamic> route) => false,
//                 );
//               },
//               child: Text("موافق",
//                   style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black)),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showWelcomeMessage(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//           title: Text(
//             "مرحبًا بك في JrStore!",
//             style: TextStyle(
//                 fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
//           ),
//           content: Text(
//             "تمت الموافقة على حسابك كصاحب متجر، يمكنك الآن استخدام التطبيق بكامل ميزاته!",
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 16, color: Colors.black),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text("موافق",
//                   style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black)),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

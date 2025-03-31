import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';
import 'home_screen.dart';
import '../screens/utils/approval_checker.dart';

class CreateStoreScreen extends StatefulWidget {
  final String categoryName;
  final String? storeId;
  final Map<String, dynamic>? existingData;

  const CreateStoreScreen({
    required this.categoryName,
    this.storeId,
    this.existingData,
  });

  @override
  _CreateStoreScreenState createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends State<CreateStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final Map<String, Map<String, TimeOfDay>> _workingHours = {
    'saturday': {
      "open": TimeOfDay(hour: 8, minute: 0),
      "close": TimeOfDay(hour: 20, minute: 0)
    },
    'sunday': {
      "open": TimeOfDay(hour: 8, minute: 0),
      "close": TimeOfDay(hour: 20, minute: 0)
    },
    'monday': {
      "open": TimeOfDay(hour: 8, minute: 0),
      "close": TimeOfDay(hour: 20, minute: 0)
    },
    'tuesday': {
      "open": TimeOfDay(hour: 8, minute: 0),
      "close": TimeOfDay(hour: 20, minute: 0)
    },
    'wednesday': {
      "open": TimeOfDay(hour: 8, minute: 0),
      "close": TimeOfDay(hour: 20, minute: 0)
    },
    'thursday': {
      "open": TimeOfDay(hour: 8, minute: 0),
      "close": TimeOfDay(hour: 20, minute: 0)
    },
    'friday': {
      "open": TimeOfDay(hour: 8, minute: 0),
      "close": TimeOfDay(hour: 20, minute: 0)
    },
  };

  File? _imageFile;
  Uint8List? _imageBytes;
  String? _ownerName;
  bool _isLoading = false;

  String _translateDay(String day) {
    switch (day) {
      case 'saturday':
        return 'السبت';
      case 'sunday':
        return 'الأحد';
      case 'monday':
        return 'الإثنين';
      case 'tuesday':
        return 'الثلاثاء';
      case 'wednesday':
        return 'الأربعاء';
      case 'thursday':
        return 'الخميس';
      case 'friday':
        return 'الجمعة';
      default:
        return day;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkApprovalAndLogoutIfNeeded(context);
      _loadOwnerName();

      if (widget.existingData != null) {
        _storeNameController.text = widget.existingData!['name'] ?? '';
        _phoneController.text = widget.existingData!['phone'] ?? '';
        _imageUrlController.text = widget.existingData!['imageUrl'] ?? '';
      }
      if (widget.existingData != null) {
        _storeNameController.text = widget.existingData!['name'] ?? '';
        _phoneController.text = widget.existingData!['phone'] ?? '';
        _imageUrlController.text = widget.existingData!['imageUrl'] ?? '';

        // تحديث ساعات العمل حسب البيانات الحالية
        final existingHours = widget.existingData!['workingHours'];
        if (existingHours != null && existingHours is Map<String, dynamic>) {
          existingHours.forEach((day, times) {
            if (times is Map<String, dynamic>) {
              final open = _parseTimeOfDay(times['open']);
              final close = _parseTimeOfDay(times['close']);
              if (open != null && close != null) {
                _workingHours[day] = {
                  'open': open,
                  'close': close,
                };
              }
            }
          });
        }
      }
    });
  }

  TimeOfDay? _parseTimeOfDay(String? timeStr) {
    if (timeStr == null) return null;

    try {
      final parts = timeStr.trim().split(' ');
      if (parts.length != 2) return null;

      final time = parts[0]; // مثل "5:00"
      final period = parts[1].toUpperCase(); // "AM" أو "PM"

      final timeParts = time.split(':');
      if (timeParts.length != 2) return null;

      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      print('❌ Failed to parse time "$timeStr": $e');
      return null;
    }
  }

  Future<void> _loadOwnerName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      setState(() {
        _ownerName = userDoc['userName'];
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      } else {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    }
  }

  Future<void> _saveStore() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    String imageUrl = _imageUrlController.text.trim();

    if (kIsWeb && _imageBytes != null) {
      final imageName =
          'store_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(imageName);
      await ref.putData(_imageBytes!);
      imageUrl = await ref.getDownloadURL();
    } else if (!kIsWeb && _imageFile != null) {
      final imageName =
          'store_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(imageName);
      await ref.putFile(_imageFile!);
      imageUrl = await ref.getDownloadURL();
    }
    Map<String, Map<String, String>> formattedWorkingHours = {};
    _workingHours.forEach((day, times) {
      formattedWorkingHours[day] = {
        'open': times['open']!.format(context),
        'close': times['close']!.format(context),
      };
    });

    final storeData = {
      'name': _storeNameController.text.trim(),
      'owner': _ownerName ?? 'بدون اسم',
      'ownerUid': uid,
      'phone': _phoneController.text.trim(),
      'categories': [widget.categoryName],
      'isApproved': widget.existingData?['isApproved'] ?? false,
      'imageUrl': imageUrl,
      'workingHours': formattedWorkingHours,
    };

    if (widget.storeId != null) {
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .update(storeData);
    } else {
      await FirebaseFirestore.instance.collection('stores').add(storeData);
    }

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(widget.storeId != null
              ? "تم تحديث المتجر"
              : "تم إرسال المتجر للمراجعة")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storeId != null ? "تعديل المتجر" : "إنشاء متجر",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: (kIsWeb && _imageBytes != null)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(_imageBytes!, height: 150),
                            )
                          : (!kIsWeb && _imageFile != null)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(_imageFile!, height: 150),
                                )
                              : Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Image.network(
                                      _imageUrlController.text.isNotEmpty
                                          ? _imageUrlController.text
                                          : 'assets/images/logo.png',
                                      height: 100,
                                      width: 100,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Image.asset(
                                        'assets/images/logo.png',
                                        height: 100,
                                        width: 100,
                                      ),
                                    ),
                                  ),
                                ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _storeNameController,
                      decoration: InputDecoration(
                        labelText: "اسم المتجر",
                        labelStyle: TextStyle(color: Colors.white),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                      validator: (value) =>
                          value == null || value.isEmpty ? "مطلوب" : null,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _workingHours.keys.map((day) {
                        final open = _workingHours[day]!['open']!;
                        final close = _workingHours[day]!['close']!;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ساعات العمل ليوم ${_translateDay(day)}:',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      TimeOfDay? picked = await showTimePicker(
                                        context: context,
                                        initialTime: open,
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          _workingHours[day]!['open'] = picked;
                                        });
                                      }
                                    },
                                    icon: Icon(Icons.access_time),
                                    label: Text('فتح: ${open.format(context)}'),
                                  ),
                                  SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      TimeOfDay? picked = await showTimePicker(
                                        context: context,
                                        initialTime: close,
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          _workingHours[day]!['close'] = picked;
                                        });
                                      }
                                    },
                                    icon: Icon(Icons.access_time),
                                    label:
                                        Text('إغلاق: ${close.format(context)}'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: "رقم الهاتف",
                        labelStyle: TextStyle(color: Colors.white),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value == null || value.isEmpty ? "مطلوب" : null,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Text("الفئة: ", style: TextStyle(color: Colors.white)),
                        SizedBox(width: 8),
                        Text(widget.categoryName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(
                        labelText: "أدخل رابط صورة المتجر",
                        labelStyle: TextStyle(color: Colors.white),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _saveStore,
                      icon: Icon(Icons.save),
                      label: Text(widget.storeId != null
                          ? "حفظ التعديلات"
                          : "حفظ المتجر"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
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
}

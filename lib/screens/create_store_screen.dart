import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';
import '../screens/utils/approval_checker.dart';

class CreateStoreScreen extends StatefulWidget {
  final String categoryName;

  const CreateStoreScreen({required this.categoryName});

  @override
  _CreateStoreScreenState createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends State<CreateStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  File? _imageFile;
  Uint8List? _imageBytes;
  String? _ownerName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkApprovalAndLogoutIfNeeded(context);
      _loadOwnerName();
    });
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
    String imageUrl;

    if (kIsWeb && _imageBytes != null) {
      final imageName =
          'store_images/\${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(imageName);
      await ref.putData(_imageBytes!);
      imageUrl = await ref.getDownloadURL();
    } else if (!kIsWeb && _imageFile != null) {
      final imageName =
          'store_images/\${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(imageName);
      await ref.putFile(_imageFile!);
      imageUrl = await ref.getDownloadURL();
    } else if (_imageUrlController.text.isNotEmpty) {
      imageUrl = _imageUrlController.text.trim();
    } else {
      imageUrl = 'assets/images/logo.png';
    }

    await FirebaseFirestore.instance.collection('stores').add({
      'name': _storeNameController.text.trim(),
      'owner': _ownerName ?? 'بدون اسم',
      'ownerUid': uid,
      'phone': _phoneController.text.trim(),
      'categories': [widget.categoryName],
      'isApproved': false,
      'imageUrl': imageUrl,
    });

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("تم إرسال المتجر للمراجعة")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("إنشاء متجر", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.green),
                  ),
                  SizedBox(height: 10),
                  Text('مرحبًا بك',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  Text('في متجر JrStore 👋',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: Colors.white),
              title: Text("الصفحة الرئيسية",
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen()),
              ),
            ),
          ],
        ),
      ),
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
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      height: 100,
                                      width: 100,
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
                      label: Text("حفظ المتجر"),
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
}

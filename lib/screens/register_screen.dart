import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'category_stores_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String? categoryName; // ✅ نجعلها nullable

  const RegisterScreen({this.categoryName}); // ✅ بدون required

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _userType = 'user';
  String _errorMessage = '';
  bool _isError = false;
  bool _isLoginMode = false;

  void _toggleLoginMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  bool _isValidPassword(String password) {
    final regex = RegExp(r'^[a-zA-Z0-9]{7,}$');
    return regex.hasMatch(password);
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    return regex.hasMatch(email);
  }

  bool _validateInputs() {
    if (!_isLoginMode) {
      if (_userNameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _ageController.text.isEmpty ||
          _countryController.text.isEmpty) {
        setState(() {
          _errorMessage = 'جميع الحقول مطلوبة';
          _isError = true;
        });
        return false;
      }
    } else {
      if (_userNameController.text.isEmpty ||
          _passwordController.text.isEmpty) {
        setState(() {
          _errorMessage = 'اسم المستخدم وكلمة المرور مطلوبان';
          _isError = true;
        });
        return false;
      }
    }

    setState(() {
      _isError = false;
    });
    return true;
  }

  Future<bool> _isUserExists() async {
    QuerySnapshot usernameQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('userName', isEqualTo: _userNameController.text)
        .get();

    QuerySnapshot emailQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: _emailController.text)
        .get();

    if (usernameQuery.docs.isNotEmpty) {
      setState(() {
        _errorMessage = 'اسم المستخدم مستخدم بالفعل، الرجاء اختيار اسم آخر';
        _isError = true;
      });
      return true;
    }

    if (emailQuery.docs.isNotEmpty) {
      setState(() {
        _errorMessage =
            'البريد الإلكتروني مستخدم بالفعل، الرجاء اختيار بريد آخر';
        _isError = true;
      });
      return true;
    }

    return false;
  }

  Future<void> _authenticate() async {
    if (!_validateInputs()) return;

    if (_isLoginMode) {
      try {
        QuerySnapshot query = await FirebaseFirestore.instance
            .collection('users')
            .where('userName', isEqualTo: _userNameController.text)
            .get();

        if (query.docs.isEmpty) {
          setState(() {
            _errorMessage = 'اسم المستخدم غير موجود';
            _isError = true;
          });
          return;
        }

        var userDoc = query.docs.first;
        String email = userDoc['email'];

        await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: _passwordController.text,
        );

        var userType = userDoc['userType'];
        var isApproved = userDoc['isApproved'] ?? false;

        if (userType == 'store_owner' && !isApproved) {
          _showPendingDialog();
          await firebase_auth.FirebaseAuth.instance.signOut();
          return;
        }

        if (_userType == 'store_owner') {
          _showPendingDialog(); // عرض رسالة المراجعة
          await firebase_auth.FirebaseAuth.instance.signOut();
          return;
        }

// ✅ إذا كان مشتري - انتقل للصفحة المناسبة
        if (widget.categoryName != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryStoresScreen(
                categoryName: widget.categoryName!,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'فشل تسجيل الدخول، تحقق من بياناتك: ${e.toString()}';
          _isError = true;
        });
      }
    } else {
      try {
        if (await _isUserExists()) return;

        int userAge = int.tryParse(_ageController.text) ?? 0;
        if (userAge < 10 || userAge > 80) {
          setState(() {
            _errorMessage = 'يجب أن يكون العمر بين 10 و 80 سنة';
            _isError = true;
          });
          return;
        }

        final email = _emailController.text.trim();

        if (!_isValidEmail(_emailController.text.trim())) {
          setState(() {
            _errorMessage =
                'يرجى إدخال بريد إلكتروني صالح باللغة الإنجليزية فقط';
            _isError = true;
          });
          return;
        }

        if (!_isValidPassword(_passwordController.text)) {
          setState(() {
            _errorMessage =
                'يجب أن تحتوي كلمة المرور على 7 أحرف على الأقل وتشمل أرقامًا وحروفًا باللغة الإنجليزية فقط';
            _isError = true;
          });
          return;
        }

        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() {
            _errorMessage = 'كلمتا المرور غير متطابقتين، الرجاء التأكد';
            _isError = true;
          });
          return;
        }

        firebase_auth.UserCredential userCredential = await firebase_auth
            .FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: _passwordController.text,
        );

        User newUser = User(
          userId: userCredential.user!.uid,
          userType: _userType,
          email: email,
          userName: _userNameController.text,
          age: userAge,
          country: _countryController.text,
          isApproved: _userType == 'store_owner' ? false : true,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser.toMap());

        if (_userType == 'store_owner') {
          _showPendingDialog(); // عرض رسالة المراجعة
          await firebase_auth.FirebaseAuth.instance.signOut();
          return;
        }

// ✅ التنقل بعد إنشاء حساب مشتري
        if (widget.categoryName != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryStoresScreen(
                categoryName: widget.categoryName!,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء التسجيل: ${e.toString()}';
          _isError = true;
        });
      }
    }
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "طلب قيد المراجعة",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          content: Text(
            "تم تقديم طلبك لإنشاء حساب صاحب متجر.\nيرجى انتظار الموافقة من الإدارة قبل تسجيل الدخول.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // يغلق الـ Dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
              child: Text(
                "موافق",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          _isLoginMode ? "تسجيل الدخول" : "إنشاء حساب",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_isError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              TextField(
                controller: _userNameController,
                decoration: InputDecoration(
                    labelText: 'اسم المستخدم',
                    labelStyle: TextStyle(color: Colors.white)),
                style: TextStyle(color: Colors.white),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    labelStyle: TextStyle(color: Colors.white)),
                style: TextStyle(color: Colors.white),
                obscureText: true,
              ),
              if (!_isLoginMode)
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      labelStyle: TextStyle(color: Colors.white)),
                  style: TextStyle(color: Colors.white),
                  obscureText: true,
                ),
              if (!_isLoginMode) ...[
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      labelStyle: TextStyle(color: Colors.white)),
                  style: TextStyle(color: Colors.white),
                ),
                TextField(
                  controller: _ageController,
                  decoration: InputDecoration(
                      labelText: 'العمر',
                      labelStyle: TextStyle(color: Colors.white)),
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _countryController,
                  decoration: InputDecoration(
                      labelText: 'البلد',
                      labelStyle: TextStyle(color: Colors.white)),
                  style: TextStyle(color: Colors.white),
                ),
                DropdownButtonFormField<String>(
                  value: _userType,
                  items: [
                    DropdownMenuItem(
                      value: 'user',
                      child:
                          Text('مشتري', style: TextStyle(color: Colors.white)),
                    ),
                    DropdownMenuItem(
                      value: 'store_owner',
                      child: Text('صاحب متجر',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _userType = value!;
                    });
                  },
                  dropdownColor: Colors.black,
                  decoration: InputDecoration(
                      labelText: 'نوع الحساب',
                      labelStyle: TextStyle(color: Colors.white)),
                  style: TextStyle(color: Colors.white),
                ),
              ],
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _authenticate,
                child: Text(_isLoginMode ? "تسجيل الدخول" : "إنشاء حساب"),
              ),
              TextButton(
                onPressed: _toggleLoginMode,
                child: Text(_isLoginMode
                    ? "إنشاء حساب جديد"
                    : "لديك حساب؟ تسجيل الدخول"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

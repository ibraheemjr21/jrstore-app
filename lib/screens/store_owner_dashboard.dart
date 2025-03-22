import 'package:flutter/material.dart';

class StoreOwnerDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة تحكم صاحب المتجر'),
      ),
      body: Center(
        child: Text('أهلاً بك في لوحة تحكم صاحب المتجر'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import 'product_details_screen.dart';

class StoreProductsScreen extends StatelessWidget {
  final String storeId; // ✅ تحديد المتجر المختار

  const StoreProductsScreen({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("منتجات المتجر"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('storeId',
                isEqualTo: storeId) // ✅ جلب المنتجات الخاصة بالمتجر
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "لا توجد منتجات متاحة لهذا المتجر",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            );
          }

          List<Product> products = snapshot.data!.docs
              .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                color: Colors.grey[900],
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title:
                      Text(product.name, style: TextStyle(color: Colors.white)),
                  subtitle: Text("السعر: ${product.price} شاقل",
                      style: TextStyle(color: Colors.white70)),
                  trailing: Icon(Icons.arrow_forward, color: Colors.white),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsScreen(product: product),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class Product {
  final String name;
  final String details;
  final double price;
  final double? oldPrice;
  final bool discount;
  final String image;
  final String preparationTime;
  final String deliveryTime;
  final DateTime addedDate;
  final String storeId; // ✅ ربط المنتج بالمتجر

  Product({
    required this.name,
    required this.details,
    required this.price,
    this.oldPrice,
    required this.discount,
    required this.image,
    required this.preparationTime,
    required this.deliveryTime,
    required this.addedDate,
    required this.storeId, // ✅ إضافة `storeId`
  });

  // تحويل المنتج إلى Map لحفظه في Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'details': details,
      'price': price,
      'oldPrice': oldPrice,
      'discount': discount,
      'image': image,
      'preparationTime': preparationTime,
      'deliveryTime': deliveryTime,
      'addedDate': addedDate.toIso8601String(),
      'storeId': storeId, // ✅ حفظ معرف المتجر
    };
  }

  // إنشاء كائن `Product` من Firestore
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      name: map['name'],
      details: map['details'],
      price: (map['price'] as num).toDouble(),
      oldPrice:
          map['oldPrice'] != null ? (map['oldPrice'] as num).toDouble() : null,
      discount: map['discount'],
      image: map['image'],
      preparationTime: map['preparationTime'],
      deliveryTime: map['deliveryTime'],
      addedDate: DateTime.parse(map['addedDate']),
      storeId: map['storeId'], // ✅ استرجاع `storeId`
    );
  }
}

class Store {
  final String id;
  final String name;
  final String owner;
  final String ownerUid;
  final String phone;
  final List<String> categories;
  final bool isApproved;
  final bool isOpen; // ✅ الجديد
  final String imageUrl;

  Store({
    required this.id,
    required this.name,
    required this.owner,
    required this.ownerUid,
    required this.phone,
    required this.categories,
    required this.isApproved,
    required this.isOpen, // ✅
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'owner': owner,
      'ownerUid': ownerUid,
      'phone': phone,
      'categories': categories,
      'isApproved': isApproved,
      'isOpen': isOpen, // ✅
      'imageUrl': imageUrl,
    };
  }

  factory Store.fromMap(Map<String, dynamic> map, String id) {
    return Store(
      id: id,
      name: map['name'],
      owner: map['owner'],
      ownerUid: map['ownerUid'],
      phone: map['phone'],
      categories: List<String>.from(map['categories']),
      isApproved: map['isApproved'] ?? false,
      isOpen: map['isOpen'] ?? true, // ✅
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}

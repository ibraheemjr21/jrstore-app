class Category {
  final String title;
  final String image;

  Category({
    required this.title,
    required this.image,
  });

  // تحويل Map إلى Category
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      title: map['title'] ?? '', // التأكد من وجود `title`
      image: map['image'] ?? '', // التأكد من وجود `image`
    );
  }
}

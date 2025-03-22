class User {
  final String userId;
  final String userType;
  final String email;
  final String userName;
  final int age;
  final String country;
  bool isApproved;

  User({
    required this.userId,
    required this.userType,
    required this.email,
    required this.userName,
    required this.age,
    required this.country,
    this.isApproved = false,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['userId'],
      userType: map['userType'],
      email: map['email'],
      userName: map['userName'],
      age: map['age'],
      country: map['country'],
      isApproved: map['isApproved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userType': userType,
      'email': email,
      'userName': userName,
      'age': age,
      'country': country,
      'isApproved': isApproved,
    };
  }
}

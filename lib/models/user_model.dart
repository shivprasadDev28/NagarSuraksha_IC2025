class AppUser {
  final String userId;
  final String name;
  final String email;
  final String? location;
  final DateTime createdAt;

  AppUser({
    required this.userId,
    required this.name,
    required this.email,
    this.location,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      location: map['location'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'location': location,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

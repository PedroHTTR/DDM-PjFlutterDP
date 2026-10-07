class User {
  final int id;
  final String username;
  final double budget;

  const User({
    required this.id,
    required this.username,
    required this.budget,
  });

  factory User.fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as int,
      username: map['username'] as String,
      budget: (map['budget'] as num).toDouble(),
    );
  }
}

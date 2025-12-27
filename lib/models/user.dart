class User {
  User({
    this.id,
    required this.name,
    required this.budget,
  });

  final int? id;
  final String name;
  final double budget;

  User copyWith({
    int? id,
    String? name,
    double? budget,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      budget: budget ?? this.budget,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'budget': budget,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      budget: (map['budget'] as num).toDouble(),
    );
  }
}


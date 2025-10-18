class User {
  int? id;
  String name;
  int height;
  int weight;
  String gender;
  DateTime birthDate;

  User({
    this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.gender,
    required this.birthDate,
  });

  int get age {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'height': height,
      'weight': weight,
      'gender': gender,
      'birthDate': birthDate.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      height: map['height'],
      weight: map['weight'],
      gender: map['gender'],
      birthDate: DateTime.parse(map['birthDate']),
    );
  }
}

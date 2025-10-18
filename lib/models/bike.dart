class Bike {
  final int? id;
  final String brand;
  final String model;
  final int year;
  final double weight;

  Bike({
    this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.weight,
  });

  factory Bike.fromMap(Map<String, dynamic> map) => Bike(
        id: map['id'] as int?,
        brand: map['brand'] as String,
        model: map['model'] as String,
        year: map['year'] as int,
        weight: map['weight'] as double,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'brand': brand,
        'model': model,
        'year': year,
        'weight': weight,
      };
}

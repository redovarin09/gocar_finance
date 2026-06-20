class TripModel {
  final int? id;
  final String date;
  final int fare;
  final String paymentType;
  final int tip;
  final double kmAdded;
  final String createdAt;

  const TripModel({
    this.id,
    required this.date,
    required this.fare,
    required this.paymentType,
    this.tip = 0,
    this.kmAdded = 0.0,
    required this.createdAt,
  });

  // Total per trip (fare + tip)
  int get totalIncome => fare + tip;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'fare': fare,
      'payment_type': paymentType,
      'tip': tip,
      'km_added': kmAdded,
      'created_at': createdAt,
    };
  }

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: map['id'] as int?,
      date: map['date'] as String,
      fare: map['fare'] as int,
      paymentType: map['payment_type'] as String,
      tip: map['tip'] as int,
      kmAdded: (map['km_added'] as num).toDouble(),
      createdAt: map['created_at'] as String,
    );
  }

  TripModel copyWith({
    int? id,
    String? date,
    int? fare,
    String? paymentType,
    int? tip,
    double? kmAdded,
    String? createdAt,
  }) {
    return TripModel(
      id: id ?? this.id,
      date: date ?? this.date,
      fare: fare ?? this.fare,
      paymentType: paymentType ?? this.paymentType,
      tip: tip ?? this.tip,
      kmAdded: kmAdded ?? this.kmAdded,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

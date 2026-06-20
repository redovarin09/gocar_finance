class IncentiveTargetModel {
  final int? id;
  final String date;
  final String tierName;
  final int tripTarget;
  final int bonusAmount;
  final String createdAt;

  const IncentiveTargetModel({
    this.id,
    required this.date,
    required this.tierName,
    required this.tripTarget,
    required this.bonusAmount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'tier_name': tierName,
      'trip_target': tripTarget,
      'bonus_amount': bonusAmount,
      'created_at': createdAt,
    };
  }

  factory IncentiveTargetModel.fromMap(Map<String, dynamic> map) {
    return IncentiveTargetModel(
      id: map['id'] as int?,
      date: map['date'] as String,
      tierName: map['tier_name'] as String,
      tripTarget: map['trip_target'] as int,
      bonusAmount: map['bonus_amount'] as int,
      createdAt: map['created_at'] as String,
    );
  }
}

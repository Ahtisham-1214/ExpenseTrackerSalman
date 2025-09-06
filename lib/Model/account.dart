class Account {
  final int? id;
  final String name;
  final double openingBalance;
  final String createdAt;   // always set (custom or system default)
  final String? updatedAt;
  final String type;

  Account({
    this.id,
    required this.name,
    required this.type,
    this.openingBalance = 0,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'account_id': id,
      'name': name,
      'type': type,
      'opening_balance': openingBalance,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['account_id'],
      name: map['name'],
      type: map['type'],
      openingBalance: map['opening_balance'] ?? 0,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}

class TransactionModel {
  final String id;
  final String type;
  final String party;
  final double amount;
  final double cost;
  final double balance;
  final String time;
  final String tag;

  TransactionModel({
    required this.id,
    required this.type,
    required this.party,
    required this.amount,
    required this.cost,
    required this.balance,
    required this.time,
    required this.tag,
  });

  // Convert TransactionModel to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'party': party,
      'amount': amount,
      'cost': cost,
      'balance': balance,
      'time': time,
      'tag': tag,
    };
  }

  // Convert map to TransactionModel
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      type: map['type'],
      party: map['party'],
      amount: map['amount'],
      cost: map['cost'],
      balance: map['balance'],
      time: map['time'],
      tag: map['tag'],
    );
  }
}

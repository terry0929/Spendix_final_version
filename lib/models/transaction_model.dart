class TransactionModel {
  final int? id;
  final String category;
  final bool isExpense;
  final double amount;
  final String note;
  final DateTime date;
  final bool isSaving;
  final double savingAmount;

  TransactionModel({
    this.id,
    required this.category,
    required this.isExpense,
    required this.amount,
    required this.note,
    required this.date,
    this.isSaving = false,
    this.savingAmount = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'isExpense': isExpense ? 1 : 0,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'isSaving': isSaving ? 1 : 0,
      'savingAmount': savingAmount,
    }..removeWhere((key, value) => value == null);
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      category: map['category'],
      isExpense: map['isExpense'] == 1,
      amount: map['amount'],
      note: map['note'],
      date: DateTime.parse(map['date']),
      isSaving: map['isSaving'] == 1,
      savingAmount: map['savingAmount'],
    );
  }
}

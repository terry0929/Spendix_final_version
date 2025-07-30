import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  late Future<List<TransactionModel>> _transactions;
  DateTime _selectedMonth = DateTime.now();

  final Map<String, String> categoryTranslations = {
    'Food': '食物',
    'Transport': '交通',
    'Entertainment': '娛樂',
    'Grocery': '生活用品',
    'Others': '其他',
    '薪資': '薪資',
    '投資': '投資',
    '獎金': '獎金',
    '其他': '其他',
  };

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    _transactions = DatabaseHelper().getTransactions();
  }

  Future<void> _deleteTransaction(int id) async {
    final db = await DatabaseHelper().database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    setState(_loadTransactions);
  }

  void _selectPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _selectNextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5),
      appBar: AppBar(
        backgroundColor: Colors.brown[700],
        title: const Text('記帳紀錄', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: FutureBuilder<List<TransactionModel>>(
          future: _transactions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.info_outline, size: 60, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      "目前沒有任何記帳紀錄",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final transactions = snapshot.data!;
            final filteredTransactions = transactions
                .where(
                  (txn) =>
                      txn.date.year == _selectedMonth.year &&
                      txn.date.month == _selectedMonth.month,
                )
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date)); // ← 這行讓日期由新到舊排序


            final totalExpense = filteredTransactions
                .where((txn) => txn.isExpense)
                .fold(0.0, (sum, txn) => sum + txn.amount);
            final totalIncome = filteredTransactions
                .where((txn) => !txn.isExpense)
                .fold(0.0, (sum, txn) => sum + txn.amount);

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFDDDDDD), width: 0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _selectPreviousMonth,
                            child: const Icon(
                              CupertinoIcons.chevron_left,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedMonth.year}年 ${_selectedMonth.month}月',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _selectNextMonth,
                            child: const Icon(
                              CupertinoIcons.chevron_right,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem('總支出', totalExpense, Colors.red),
                          _buildSummaryItem('總收入', totalIncome, Colors.green),
                          _buildSummaryItem(
                            '結餘',
                            totalIncome - totalExpense,
                            Colors.brown,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      top: 12,
                      left: 12,
                      right: 12,
                      bottom: 24,
                    ),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final txn = filteredTransactions[index];
                      final amountColor =
                          txn.isExpense ? Colors.red : Colors.green;
                      final amountText =
                          (txn.isExpense ? "- " : "+ ") +
                          "\$${txn.amount.toStringAsFixed(0)}";

                      return Dismissible(
                        key: Key(txn.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          padding: const EdgeInsets.only(right: 24),
                          alignment: Alignment.centerRight,
                          color: Colors.redAccent,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          final confirm = await showCupertinoDialog<bool>(
                            context: context,
                            builder:
                                (context) => CupertinoAlertDialog(
                                  title: const Text(
                                    "確認刪除",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: const Padding(
                                    padding: EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      "你確定要刪除這筆記帳紀錄嗎？",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text("取消"),
                                    ),
                                    CupertinoDialogAction(
                                      isDestructiveAction: true,
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: const Text("刪除"),
                                    ),
                                  ],
                                ),
                          );
                          return confirm ?? false;
                        },
                        onDismissed: (_) => _deleteTransaction(txn.id!),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            leading: Icon(
                              txn.isExpense
                                  ? Icons.remove_circle
                                  : Icons.add_circle,
                              color: amountColor,
                            ),
                            //title: Text(txn.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                            title: Text(
                              categoryTranslations[txn.category] ??
                                  txn.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat.yMMMd().format(txn.date)),
                                if (txn.note.isNotEmpty)
                                  Text(
                                    txn.note.length > 20
                                        ? txn.note.substring(0, 20) + '...'
                                        : txn.note,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  amountText,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: amountColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => _editTransaction(txn),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            onTap:
                                txn.note.length > 20
                                    ? () => _showFullNoteDialog(txn.note)
                                    : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _editTransaction(TransactionModel txn) {
    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: const Text(
              "尚未實作",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text("待實作編輯功能 🙂", style: TextStyle(fontSize: 16)),
            ),
            actions: [
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFDDDDDD), width: 0.6),
                  ),
                ),
                child: CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
    );
  }

  void _showFullNoteDialog(String note) {
    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: const Text(
              "完整備註",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(note, style: const TextStyle(fontSize: 16)),
            ),
            actions: [
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFDDDDDD), width: 0.6),
                  ),
                ),
                child: CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
    );
  }
}

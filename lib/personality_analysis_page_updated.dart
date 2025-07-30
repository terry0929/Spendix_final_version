import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../database/database_helper.dart';
import '../api/personality_predictor_debug.dart';

class PersonalityAnalysisPage extends StatefulWidget {
  final DateTime selectedMonth;

  const PersonalityAnalysisPage({super.key, required this.selectedMonth});

  @override
  State<PersonalityAnalysisPage> createState() =>
      _PersonalityAnalysisPageState();
}

class _PersonalityAnalysisPageState extends State<PersonalityAnalysisPage> {
  PersonalityResult? _result;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _analyzePersonalityFromSelectedMonth();
  }

  Future<void> _analyzePersonalityFromSelectedMonth() async {
    setState(() => _isLoading = true);

    //final transactions = await DatabaseHelper().getAllTransactions();
    final List<TransactionModel> transactions =
        await DatabaseHelper().getTransactions();

    final targetTxns =
        transactions
            .where(
              (txn) =>
                  txn.date.year == widget.selectedMonth.year &&
                  txn.date.month == widget.selectedMonth.month &&
                  txn.isExpense,
            )
            .toList();

    final Map<String, double> sums = {
      'food': 0,
      'transport': 0,
      'entertainment': 0,
      'grocery': 0,
      'others': 0,
    };

    for (var txn in targetTxns) {
      final key = txn.category.toLowerCase();
      if (sums.containsKey(key)) {
        sums[key] = sums[key]! + txn.amount;
      } else {
        sums['others'] = sums['others']! + txn.amount;
      }
    }

    final api = PersonalityApiClient();
    final result = await api.predictPersonality(
      food: sums['food']!,
      transport: sums['transport']!,
      entertainment: sums['entertainment']!,
      grocery: sums['grocery']!,
      others: sums['others']!,
    );

    setState(() {
      _result = result;
      _isLoading = false;
    });
  }

  Widget _buildPersonalityContent() {
    String imageAsset = 'assets/images/L.png';
    String description = '你是謹慎型消費者，花錢前會仔細思考，傾向存錢與理性規劃。';

    if (_result!.name.startsWith('J')) {
      imageAsset = 'assets/images/J.png';
      description = '你是享樂型消費者，偏好即時享受，購物偏感性。';
    } else if (_result!.name.startsWith('G')) {
      imageAsset = 'assets/images/G.png';
      description = '你是自由型消費者，消費行為多元，靈活調整但較缺乏規劃。';
    }

    return Column(
      children: [
        Image.asset(imageAsset, height: 220, fit: BoxFit.contain),
        const SizedBox(height: 24),
        Text(
          '你的消費人格是：',
          style: TextStyle(fontSize: 20, color: Colors.grey[700]),
        ),
        const SizedBox(height: 10),
        Text(
          _result!.name,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
        const SizedBox(height: 30),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  '個性描述',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  '系統建議',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _result!.suggestion,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5),
      appBar: AppBar(
        title: const Text('消費人格分析', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _result == null
              ? const Center(child: Text('分析失敗，請稍後再試'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: _buildPersonalityContent(),
              ),
    );
  }
}

// 📄 savings_progress_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../database/database_helper.dart';
//import '../models/transaction_model.dart';

class SavingsProgressPage extends StatefulWidget {
  const SavingsProgressPage({super.key});

  @override
  State<SavingsProgressPage> createState() => _SavingsProgressPageState();
}

class _SavingsProgressPageState extends State<SavingsProgressPage> {
  Map<String, dynamic>? result;
  bool isLoading = true;

  // ✅ 儲蓄計劃設定（之後可從 UI 或 SQLite 取得）
  final String startDate = "2025-04-01";
  final String endDate = "2025-07-01";
  final double targetAmount = 60000;
  //final double currentSaved = 18000;
  double currentSaved = 0.0; // 初始為0，從資料庫動態抓

  @override
  void initState() {
    super.initState();
    //_fetchAnalysis();
    _loadAndFetchAnalysis();
  }

  Future<void> _loadAndFetchAnalysis() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> savedIncomeRecords = await db.query(
      'transactions',
      where: 'isExpense = ? AND isSaving = ?',
      whereArgs: [0, 1],
    );

    double sum = 0.0;
    for (final record in savedIncomeRecords) {
      sum += double.tryParse(record['savingAmount'].toString()) ?? 0.0;
    }

    setState(() {
      currentSaved = sum;
    });

    _fetchAnalysis();
  }

  Future<void> _fetchAnalysis() async {
    const url = 'https://fastapi-71db.onrender.com/analyze';
    final body = jsonEncode({
      "start_date": startDate,
      "end_date": endDate,
      "target_amount": targetAmount,
      "current_saved": currentSaved,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        setState(() {
          result = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception("API 回傳錯誤");
      }
    } catch (e) {
      setState(() {
        result = {"error": e.toString()};
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5),
      appBar: AppBar(
        backgroundColor: Colors.brown[700],
        title: const Text('儲蓄進度分析', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : result == null || result!.containsKey("error")
                ? Text("錯誤：${result?['error'] ?? '無資料'}")
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopPreview(result!),
                    const Divider(height: 40),
                    _buildResultCard(result!),
                    // FutureBuilder(
                    //   future: http.post(
                    //     Uri.parse('https://ai-fintech-apis.onrender.com/analyze'),
                    //     headers: {"Content-Type": "application/json"},
                    //     body: jsonEncode({
                    //       "start_date": startDate,
                    //       "end_date": endDate,
                    //       "target_amount": targetAmount,
                    //       "current_saved": currentSaved
                    //     }),
                    //   ),
                    //   builder: (context, snapshot) {
                    //     if (snapshot.connectionState == ConnectionState.waiting) {
                    //       return const Center(child: CircularProgressIndicator());
                    //     } else if (snapshot.hasError || snapshot.data?.statusCode != 200) {
                    //       return const SizedBox.shrink();
                    //     } else {
                    //       final res = jsonDecode(snapshot.data!.body);
                    //       final progress = (res['progress_ratio'] as num).toDouble() / 100.0;
                    //       final ideal = ((res['expected_saved'] as num) / targetAmount).clamp(0.0, 1.0);
                    //       final saved = (res['current_saved'] as num).toDouble();
                    //
                    //       return Card(
                    //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    //         elevation: 3,
                    //         child: Padding(
                    //           padding: const EdgeInsets.all(16),
                    //           child: Column(
                    //             crossAxisAlignment: CrossAxisAlignment.start,
                    //             children: [
                    //               Text('🔍 儲蓄進度預覽', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown[700])),
                    //               const SizedBox(height: 12),
                    //               Text('目前進度：${res['progress_ratio']}% (NT\$${saved.toStringAsFixed(0)} / NT\$${targetAmount.toStringAsFixed(0)})'),
                    //               const SizedBox(height: 8),
                    //               ClipRRect(
                    //                 borderRadius: BorderRadius.circular(10),
                    //                 child: Column(
                    //                   crossAxisAlignment: CrossAxisAlignment.start,
                    //                   children: [
                    //                     LinearProgressIndicator(
                    //                       value: ideal,
                    //                       minHeight: 10,
                    //                       backgroundColor: Colors.transparent,
                    //                       color: Colors.blue[300],
                    //                     ),
                    //                     const SizedBox(height: 2),
                    //                     LinearProgressIndicator(
                    //                       value: progress,
                    //                       minHeight: 10,
                    //                       backgroundColor: Colors.transparent,
                    //                       color: Colors.green[400],
                    //                     ),
                    //                   ],
                    //                 ),
                    //               ),
                    //               const SizedBox(height: 4),
                    //               const Text('🔵 藍色為理想進度，🟢 綠色為實際進度'),
                    //             ],
                    //           ),
                    //         ),
                    //       );
                    //     }
                    //   },
                    // ),
                    // const Divider(height: 40),
                    // _buildResultCard(result!),
                  ],
                ),
      ),
    );
  }

  Widget _buildTopPreview(Map<String, dynamic> data) {
    final double progress = (data['progress_ratio'] as num).toDouble() / 100.0;
    final double saved = (data['current_saved'] as num).toDouble();
    final double idealProgress = 0.75;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔍 儲蓄進度預覽',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '目前進度：${data['progress_ratio']}% (NT\$${saved.toStringAsFixed(0)}/NT\$${targetAmount.toStringAsFixed(0)})',
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: idealProgress,
                    minHeight: 10,
                    backgroundColor: Colors.transparent,
                    color: Colors.blue[300],
                  ),
                  const SizedBox(height: 2),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.transparent,
                    color: Colors.green[400],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text('🔵 藍色為理想進度，🟢 綠色為實際進度'),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> data) {
    final double progress = (data['progress_ratio'] as num).toDouble() / 100.0;
    final int remainingDays =
        (data['total_days'] as num).toInt() -
        (data['days_passed'] as num).toInt();
    final double remaining =
        targetAmount - (data['current_saved'] as num).toDouble();
    final double daily = remainingDays > 0 ? remaining / remainingDays : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎯 你已儲蓄 NT\$${data['current_saved']} / NT\$${targetAmount.toStringAsFixed(0)}（達成 ${data['progress_ratio']}%）',
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          minHeight: 12,
          backgroundColor: Colors.grey[300],
        ),
        const SizedBox(height: 24),
        Text(
          '📅 預計應達進度為 ${((data['expected_saved'] as num) / targetAmount * 100).toStringAsFixed(1)}%，等於 NT\$${data['expected_saved']}',
        ),
        Text(
          data['gap_status'] == 'ahead'
              ? '✅ 你已超前 NT\$${data['gap']}'
              : '⚠️ 你已落後 NT\$${data['gap']}',
        ),
        const SizedBox(height: 24),
        Text(
          '📅 剩下 15 天，尚需儲蓄 NT\$${remaining.toStringAsFixed(0)}',
        ),
        Text('📈 平均每日存入 NT\$${(remaining / 15).toStringAsFixed(0)} 元，即可按時完成目標')
      ],
    );
  }
}

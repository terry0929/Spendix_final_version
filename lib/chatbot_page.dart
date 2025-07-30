import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../api/personality_predictor_debug.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
    String _removeMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'[*_`#>-]'), '') // 去除 Markdown 符號
        .replaceAll(RegExp(r'\n{2,}'), '\n') // 多行換行轉成單一換行
        .replaceAll(RegExp(r'^\s+', multiLine: true), '') // 移除行首空白
        .trim(); // 移除前後空白
    }

  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      //final transactions = await DatabaseHelper().getAllTransactions();
      final List<TransactionModel> transactions =
          await DatabaseHelper().getTransactions();

      final now = DateTime.now();
      final targetTxns =
          transactions
              .where(
                (txn) =>
                    txn.date.year == now.year &&
                    txn.date.month == now.month &&
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

      if (result == null) {
        setState(
          () => _messages.add({
            'role': 'bot',
            'text': '⚠️ 消費人格分析失敗，請稍後再試',
            'timestamp': DateTime.now(),
          }),
        );
        return;
      }

      await _sendAutoMessage(
        persona: result.name,
        expenses: sums,
        savingGoal: 30000,
        months: 6,
      );

      setState(() => _initialized = true);
    } catch (e) {
      print('初始化錯誤：$e');
      setState(
        () => _messages.add({
          'role': 'bot',
          'text': '⚠️ 初始化失敗，請稍後再試',
          'timestamp': DateTime.now(),
        }),
      );
    }
  }

  Future<void> _sendAutoMessage({
    required String persona,
    required Map<String, double> expenses,
    required double savingGoal,
    required int months,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://fastapi-71db.onrender.com/chatt'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': [
            {'role': 'user', 'message': '請幫我根據以下資訊規劃儲蓄建議'},
          ],
          'persona': persona,
          'expenses': expenses,
          'saving_goal': savingGoal,
          'months': months,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decoded);
        final reply = data['reply'] ?? '⚠️ AI 沒有回覆';
        final cleanReply = _removeMarkdown(reply);
        setState(() {
          _messages.add({
            'role': 'bot',
            'text': cleanReply,
            'timestamp': DateTime.now(),
          });
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'bot',
            'text': '❌ 伺服器錯誤 (${response.statusCode})',
            'timestamp': DateTime.now(),
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'bot',
          'text': '❌ 無法連線到伺服器：$e',
          'timestamp': DateTime.now(),
        });
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final now = DateTime.now();

    setState(() {
      _messages.add({'role': 'user', 'text': text, 'timestamp': now});
      _controller.clear();
    });

    try {
      final response = await http.post(
        Uri.parse('https://fastapi-71db.onrender.com/chatt'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': [
            {'role': 'user', 'message': text},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decoded);
        final reply = data['reply'] ?? '⚠️ AI 沒有回覆';
        final cleanReply = _removeMarkdown(reply);
        setState(() {
          _messages.add({
            'role': 'bot',
            'text': cleanReply,
            'timestamp': DateTime.now(),
          });
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'bot',
            'text': '❌ 伺服器錯誤 (${response.statusCode})',
            'timestamp': DateTime.now(),
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'bot',
          'text': '❌ 無法連線到伺服器：$e',
          'timestamp': DateTime.now(),
        });
      });
    }
  }

  bool _shouldShowDate(int index) {
    if (index == 0) return true;
    final current = _messages[index]['timestamp'] as DateTime;
    final previous = _messages[index - 1]['timestamp'] as DateTime;
    return current.day != previous.day ||
        current.month != previous.month ||
        current.year != previous.year;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5),
      appBar: AppBar(
        backgroundColor: Colors.brown[700],
        title: const Text('AI 儲蓄規劃助理', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                final timestamp = message['timestamp'] as DateTime;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_shouldShowDate(index))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(
                            DateFormat.yMMMd().format(timestamp),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.brown[300] : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isUser ? 12 : 0),
                            bottomRight: Radius.circular(isUser ? 0 : 12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['text'] ?? '',
                              style: TextStyle(
                                color: isUser ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat.Hm().format(timestamp),
                              style: TextStyle(
                                color: isUser ? Colors.white70 : Colors.black54,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_initialized) _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '輸入訊息...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.brown),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
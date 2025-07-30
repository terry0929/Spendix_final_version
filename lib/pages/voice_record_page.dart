import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';

class VoiceRecordPage extends StatefulWidget {
  final void Function(TransactionModel)? onResult;

  const VoiceRecordPage({Key? key, this.onResult}) : super(key: key);

  @override
  State<VoiceRecordPage> createState() => _VoiceRecordPageState();
}

class _VoiceRecordPageState extends State<VoiceRecordPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = "";

  final TextEditingController itemController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String type = '';
  String category = '';

  final Map<String, List<String>> categories = {
    "食物": [
    "早餐", "午餐", "晚餐", "宵夜", "飲料", "吃", "喝", "麥當勞", "肯德基", "星巴克", "手搖", "珍奶", "便當", "拉麵", "火鍋", "燒烤", "滷味", "炸雞", "甜點", "咖啡", "麵包", "Uber Eats", "Foodpanda", "生魚片", "壽司", "涼麵", "鹹酥雞", "全家", "7-11"
  ],
  "交通": [
    "捷運", "公車", "高鐵", "火車", "加油", "加油站", "停車費", "計程車", "Uber", "Lyft", "租車", "共享機車", "YouBike", "油錢", "交通費", "開車", "機車", "加電", "電動車", "車票"
  ],
  "娛樂": [
    "電影", "唱歌", "遊戲", "KTV", "影城", "Netflix", "Disney+", "Switch", "PS5", "手遊", "Steam", "Twitch", "動漫", "演唱會", "追劇", "桌遊", "遊樂園", "展覽", "露營", "夜唱", "livehouse"
  ],
  "生活用品": [
    "蝦皮", "全聯", "家樂福", "小北", "五金行", "超市", "生活用品", "日用品", "衛生紙", "洗髮精", "牙膏", "洗衣精", "沐浴乳", "掃把", "收納盒", "Amazon", "Momo", "PChome", "大創", "IKEA"
  ],
  "薪資": [
    "薪水", "收入", "發薪", "薪資", "打工錢", "匯款", "工資", "時薪", "勞健保", "匯入"
  ],
  "投資": [
    "股息", "投資", "股票", "ETF", "基金", "虛擬貨幣", "加密貨幣", "比特幣", "儲蓄險", "資產配置", "買股", "美股", "台股"
  ],
  "獎金": [
    "獎金", "紅包", "年終", "三節禮金", "中獎", "發票中獎", "抽獎", "零用錢", "回饋金", "獎學金"
  ],
  "其他": [
    "其他", "未知支出", "雜支", "不明費用", "捐款", "人情支出", "轉帳", "退款", "罰單", "醫療費", "保險", "手續費", "學費", "社團費"
  ]
  };

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await Permission.microphone.request();
    _speech = stt.SpeechToText();
  }

  void _startListening() async {
    final available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        localeId: "zh_TW",
        onResult: (val) {
          setState(() {
            _recognizedText = val.recognizedWords;
          });
          _analyzeText(val.recognizedWords);
          if (val.hasConfidenceRating && val.finalResult) {
            if (dateController.text.isEmpty) {
              final now = DateTime.now();
              dateController.text = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
            }
          }
        },
      );
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  void _analyzeText(String text) {
    for (var entry in categories.entries) {
      for (var kw in entry.value) {
        if (text.contains(kw)) {
          category = entry.key;
          type = ["薪資", "投資", "獎金"].contains(category) ? "收入" : "支出";
          itemController.text = kw;
          noteController.text = kw;
          break;
        }
      }
      if (category.isNotEmpty) break;
    }

    final amountReg = RegExp(r'(\d{1,10})元');
    final amountMatch = amountReg.firstMatch(text);
    if (amountMatch != null) {
      amountController.text = amountMatch.group(1)!;
    }

    final now = DateTime.now();
    final dateReg = RegExp(r'(\d{1,2})月(\d{1,2})[號日]?');
    final match = dateReg.firstMatch(text);
    if (match != null) {
      final month = int.parse(match.group(1)!);
      final day = int.parse(match.group(2)!);
      dateController.text = DateTime(now.year, month, day).toIso8601String().split('T')[0];
    } else if (text.contains("昨天")) {
      dateController.text = now.subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
    } else if (text.contains("前天")) {
      dateController.text = now.subtract(const Duration(days: 2)).toIso8601String().split('T')[0];
    } else if (text.contains("明天")) {
      dateController.text = now.add(const Duration(days: 1)).toIso8601String().split('T')[0];
    } else if (text.contains("後天")) {
      dateController.text = now.add(const Duration(days: 2)).toIso8601String().split('T')[0];
    }
  }

  void _submitOnlyToManualPage() {
    if (amountController.text.isEmpty || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 請確認金額和類別都有填寫')),
      );
      return;
    }

    final txn = TransactionModel(
      category: category,
      isExpense: type == "支出",
      amount: double.tryParse(amountController.text) ?? 0,
      note: noteController.text,
      date: DateTime.tryParse(dateController.text) ?? DateTime.now(),
    );

    widget.onResult?.call(txn);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F4EF),
      appBar: AppBar(
        title: const Text('語音記帳'),
        backgroundColor: const Color(0xFF5C3B2E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isListening ? _stopListening : _startListening,
              icon: Icon(_isListening ? Icons.stop : Icons.mic),
              label: Text(_isListening ? '停止辨識' : '開始語音記帳'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD9A066),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 20),
            _buildInputField(itemController, '項目'),
            _buildInputField(amountController, '金額', isNumber: true),
            _buildInputField(dateController, '日期 (yyyy-MM-dd)'),
            _buildInputField(noteController, '備註'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _submitOnlyToManualPage,
              icon: const Icon(Icons.check),
              label: const Text('確認轉到手動頁'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF7A6E65)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE6B27A)),
          ),
        ),
      ),
    );
  }
}
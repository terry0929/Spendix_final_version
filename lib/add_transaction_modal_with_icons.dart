import '../pages/voice_record_page.dart';
//記帳(modify)
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'database/database_helper.dart';
import 'ios_success_dialog.dart';
import 'models/transaction_model.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;


class AddTransactionModal extends StatefulWidget {
  const AddTransactionModal({super.key});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  bool isManual = true;
  bool isExpense = true;
  String selectedCategory = 'Food';
  DateTime selectedDate = DateTime.now();

  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController savingAmountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceInput = '';

  bool addToSavingPlan = false;
  bool usePercentage = true;
  double sliderValue = 0.0;

  final expenseCategories = {
    '食物': Icons.fastfood,
    '交通': Icons.directions_car,
    '娛樂': Icons.movie,
    '生活用品': Icons.shopping_cart,
    '其他': Icons.more_horiz,
  };

  final incomeCategories = {
    '薪資': Icons.attach_money,
    '投資': Icons.trending_up,
    '獎金': Icons.card_giftcard,
    '其他': Icons.account_balance_wallet,
  };

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  void _submitTransaction() async {
    if (amountController.text.isEmpty) return;

    final double amount = double.tryParse(amountController.text) ?? 0.0;
    double savingAmount = 0.0;

    if (!isExpense && addToSavingPlan) {
      if (usePercentage) {
        savingAmount = amount * sliderValue / 100.0;
      } else {
        final input = double.tryParse(savingAmountController.text) ?? 0.0;
        if (input > amount) {
          showCupertinoDialog(
            context: context,
            builder:
                (_) => CupertinoAlertDialog(
                  title: Text('錯誤'),
                  content: Text('儲蓄金額不能超過收入金額'),
                  // actions: [
                  //   CupertinoDialogAction(isDefaultAction: true, child: Text('OK')),
                  // ],
                  actions: [
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      child: const Text('OK'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
          );
          return;
        }
        savingAmount = input;
      }
    }

    final newTxn = TransactionModel(
      category: selectedCategory,
      isExpense: isExpense,
      amount: amount,
      note: noteController.text,
      date: selectedDate,
      isSaving: addToSavingPlan,
      savingAmount: savingAmount,
    );

    await DatabaseHelper().insertTransaction(newTxn);

    if (addToSavingPlan && !isExpense) {
      await showCupertinoDialog(
        context: context,
        builder:
            (_) => CupertinoAlertDialog(
              title: const Text('✅ 儲蓄成功'),
              content: Text(
                '已成功加入儲蓄計劃\n儲蓄金額：\$${savingAmount.toStringAsFixed(0)}',
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
    }

    showTransactionSuccessDialog(
      context: context,
      isExpense: isExpense,
      amount: amountController.text,
      category: selectedCategory,
    );
  }
  
  
  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: \$val'),
      onError: (val) => print('onError: \$val'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) => setState(() {
          _voiceInput = val.recognizedWords;
          _itemNameController.text = _voiceInput;
        }),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }


  @override
  Widget build(BuildContext context) {
    final categories = isExpense ? expenseCategories : incomeCategories;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFCF8F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 記帳方式切換
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildToggleButtonWithIcon(
                      icon: Icons.edit_note,
                      label: "手動記帳",
                      selected: isManual,
                      onTap: () => setState(() => isManual = true),
                      activeColor: Colors.blueAccent,
                    ),
                    const SizedBox(width: 12),
                    _buildToggleButtonWithIcon(
                      icon: Icons.mic,
                      label: "語音記帳",
                      selected: !isManual,
                      activeColor: Colors.deepOrangeAccent, // 💡你可以換別的顏色也行
                      onTap: () {
                        setState(() => isManual = false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VoiceRecordPage(
                              onResult: (txn) {
                                setState(() {
                                  isManual = true;
                                  selectedCategory = txn.category;
                                  isExpense = txn.isExpense;
                                  amountController.text = txn.amount.toString();
                                  noteController.text = txn.note;
                                  selectedDate = txn.date;
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 收支切換
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildToggleButton("支出", isExpense, () {
                      setState(() {
                        isExpense = true;
                        selectedCategory = 'Food';
                        addToSavingPlan = false;
                      });
                    }, activeColor: Colors.redAccent),
                    const SizedBox(width: 12),
                    _buildToggleButton("收入", !isExpense, () {
                      setState(() {
                        isExpense = false;
                        selectedCategory = '薪資';
                      });
                    }, activeColor: Colors.green),
                  ],
                ),
                const SizedBox(height: 20),

                if (!isExpense)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: addToSavingPlan,
                            onChanged: (val) {
                              setState(() {
                                addToSavingPlan = val ?? false;
                              });
                            },
                          ),
                          const Text('加入儲蓄計劃'),
                        ],
                      ),
                      if (addToSavingPlan)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('% 數'),
                                  selected: usePercentage,
                                  onSelected:
                                      (val) =>
                                          setState(() => usePercentage = true),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('自訂金額'),
                                  selected: !usePercentage,
                                  onSelected:
                                      (val) =>
                                          setState(() => usePercentage = false),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (usePercentage)
                              Column(
                                children: [
                                  Text(
                                    '儲蓄比例：${sliderValue.toStringAsFixed(0)}%',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Slider(
                                    value: sliderValue,
                                    min: 0,
                                    max: 100,
                                    divisions: 100,
                                    label: sliderValue.toStringAsFixed(0),
                                    onChanged:
                                        (value) =>
                                            setState(() => sliderValue = value),
                                  ),
                                ],
                              )
                            else
                              TextField(
                                controller: savingAmountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: '儲蓄金額（不得超過收入）',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                    ],
                  ),

                // 類別選擇
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children:
                      categories.entries.map((entry) {
                        return GestureDetector(
                          onTap:
                              () =>
                                  setState(() => selectedCategory = entry.key),
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  selectedCategory == entry.key
                                      ? Colors.brown[100]
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(entry.value, size: 30),
                                const SizedBox(height: 4),
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize:
                                        entry.key == 'Entertainment' ? 10 : 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 20),

                // 日期選擇
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '日期：${DateFormat.yMMMd().format(selectedDate)}',
                      ),
                    ),
                    IconButton(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 金額欄
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    prefixText: "\$ ",
                    labelText: "金額",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 備註欄
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "備註",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 確認按鈕
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "確認",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleButton(
    String label,
    bool selected,
    VoidCallback onTap, {
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButtonWithIcon({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : Colors.black87,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

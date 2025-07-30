import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<void> showTransactionSuccessDialog({
  required BuildContext context,
  required bool isExpense,
  required String amount,
  required String category,
}) {
  //final String title = "記帳成功";
  final TextStyle amountStyle = TextStyle(
    color: isExpense ? Colors.red : Colors.green,
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );

  return showCupertinoDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        //title: Text(title),
        title: Text(
          "記帳成功",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF642100), // 灰棕色系
          ),
        ),

        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      children: [
                        const TextSpan(text: '您已新增一筆'),
                        TextSpan(
                          text: isExpense ? '支出' : '收入',
                          style: TextStyle(color: isExpense ? Colors.red : Colors.green),
                        ),
                        const TextSpan(text: '：\n'),
                      ],
                    ),
                    TextSpan(text: '\$ $amount 元\n', style: amountStyle),
                    const TextSpan(text: '類別：'),
                    TextSpan(
                      text: category,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],

                ),
              ),
            ],
          ),
        ),
        // actions: [
        //   CupertinoDialogAction(
        //     onPressed: () {
        //       Navigator.of(context).popUntil((route) => route.isFirst);
        //     },
        //     child: const Text('OK'),
        //     // child: Text(
        //     //   'OK',
        //     //   style: TextStyle(
        //     //     color: isExpense ? Colors.red : Colors.green,
        //     //     fontWeight: FontWeight.bold,
        //     //   ),
        //     // ),
        //   ),
        // ],
        actions: [
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFDDDDDD), // #DDDDDD 很淡的灰，微妙但有感
                  width: 0.6,
                ),
              ),
            ),
            child: CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              isDefaultAction: true,
              child: const Text('OK'),
            ),
          ),
        ],

      );
    },
  );
}

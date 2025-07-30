// personality_predictor.dart
// flutter呼叫 /predict FAST API
import 'dart:convert';
import 'package:http/http.dart' as http;

class PersonalityResult {
  final String type;
  final String name;
  final String suggestion;

  PersonalityResult({
    required this.type,
    required this.name,
    required this.suggestion,
  });

  // factory PersonalityResult.fromJson(Map<String, dynamic> json) {
  //   return PersonalityResult(
  //     type: json['type'],
  //     name: json['name'],
  //     suggestion: json['suggestion'],
  //   );
  // }

  factory PersonalityResult.fromJson(Map<String, dynamic> json) {
    return PersonalityResult(
      type: '', // 不顯示 cluster
      name: json['persona'] ?? '未知角色',
      suggestion: json['suggestion'] ?? '暫無建議',
    );
  }
}

class PersonalityApiClient {
  //static const String _baseUrl = 'https://your-api-url.onrender.com/predict'; // TODO: 改成實際 URL
  //static const String _baseUrl = 'https://ai-fintech-apis.onrender.com/predict';
  static const String _baseUrl =
      'https://fastapi-71db.onrender.com/predict/'; // 本地測試用

  Future<PersonalityResult?> predictPersonality({
    required double food,
    required double transport,
    required double entertainment,
    required double grocery,
    required double others,
  }) async {
    // final payload = {
    //   'food': food,
    //   'transport': transport,
    //   'entertainment': entertainment,
    //   'grocery': grocery,
    //   'others': others,
    // };

    // final payload = {
    //   'food': food ?? 0.0,
    //   'transport': transport ?? 0.0,
    //   'entertainment': entertainment ?? 0.0,
    //   'grocery': grocery ?? 0.0,
    //   'others': others ?? 0.0,
    // };

    final payload = {
      'Food': food,
      'Transport': transport,
      'Entertainment': entertainment,
      'Grocery': grocery,
      'Others': others,
    };

    try {
      //print('🚀 傳送 payload: \${jsonEncode(payload)}');
      print('🚀 傳送 payload: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('✅ 成功取得回應：${response.body}');
        print(utf8.decode(response.bodyBytes)); // ← 印出整段解過的 UTF-8

        //final data = jsonDecode(response.body);
        final decoded = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decoded);

        return PersonalityResult.fromJson(data);
      } else {
        print('❌ 錯誤回應：${response.statusCode}');
        print('❌ 錯誤內容：${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 請求失敗：$e');
      return null;
    }
  }
}

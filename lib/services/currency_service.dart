import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl = 'https://api.frankfurter.app/latest?from=IDR';

  static Future<Map<String, double>> fetchRates() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = Map<String, double>.from(
          (data['rates'] as Map).map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ),
        );
        return rates;
      } else {
        throw Exception('Failed to load rates: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static double convert({
    required double amountIDR,
    required double rate,
  }) {
    return amountIDR * rate;
  }
}

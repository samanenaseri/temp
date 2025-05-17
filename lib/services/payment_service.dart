import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentService extends ChangeNotifier {
  bool _isProcessing = false;
  String? _error;

  bool get isProcessing => _isProcessing;
  String? get error => _error;

  Future<bool> processPayment({
    required String amount,
    required String currency,
    required String description,
  }) async {
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      // Create payment intent on your backend
      final response = await http.post(
        Uri.parse('YOUR_BACKEND_URL/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': amount,
          'currency': currency,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: jsonResponse['clientSecret'],
            merchantDisplayName: 'Your Store Name',
          ),
        );

        await Stripe.instance.presentPaymentSheet();
        _isProcessing = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to create payment intent');
      }
    } catch (e) {
      _error = e.toString();
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }
} 
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MidtransService {
  MidtransSDK? _midtrans;

  Future<void> initSDK() async {
    _midtrans = await MidtransSDK.init(
      config: MidtransConfig(
        clientKey: dotenv.env['MIDTRANS_CLIENT_KEY'] ?? "",
        merchantBaseUrl: "",
        colorTheme: ColorTheme(
          colorPrimary: Colors.blue,
          colorPrimaryDark: Colors.blue,
          colorSecondary: Colors.blue,
        ),
      ),
    );
    _midtrans?.setUIKitCustomSetting(
      skipCustomerDetailsPages: true,
    );
  }

  void setTransactionFinishedCallback(Function(TransactionResult) callback) {
    _midtrans?.setTransactionFinishedCallback(callback);
  }

  void startPaymentUiFlow(String token) {
    _midtrans?.startPaymentUiFlow(token: token);
  }

  void removeTransactionFinishedCallback() {
    _midtrans?.removeTransactionFinishedCallback();
  }

  Future<Map<String, dynamic>?> checkPaymentStatus(String orderId) async {
    final String baseUrl =
        "https://nextjs-midtrans-api-example-o2x4fdoph-farhan-mualifs-projects.vercel.app/api/status?order_id=$orderId";

    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Handle error response
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception occurred: $e');
      return null;
    }
  }
}

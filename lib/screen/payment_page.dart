import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:reservastion/screen/ThankyouPage.dart';
import 'package:reservastion/services/midtrans_services.dart';
import 'package:reservastion/services/token_services.dart';
import 'package:reservastion/utils/utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentPage extends StatefulWidget {
  final String orderId;

  const PaymentPage({Key? key, required this.orderId}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final MidtransService midtransService = MidtransService();
  bool _isLoading = false;
  Map<String, dynamic>? orderData;

  @override
  void initState() {
    super.initState();
    _initSDK();
    _loadOrderData();
  }

  void _initSDK() async {
    await midtransService.initSDK();
    midtransService.setTransactionFinishedCallback((result) async {
      debugPrint("Transaction Result: ${result.toJson()}");
      try {
        if (result.isTransactionCanceled) {
          _showToast("Transaksi dibatalkan", false);
          Navigator.of(context).pop();
          return;
        }

        final paymentStatusResponse = await midtransService.checkPaymentStatus(widget.orderId);
        if (paymentStatusResponse == null) {
          _showToast("Gagal memeriksa status pembayaran", true);
          Navigator.of(context).pop();
          return;
        }

        final transactionData = paymentStatusResponse['data'];
        final transactionStatus = transactionData['transaction_status'];

        // Update payment status in Firebase
        await _updatePaymentStatus(result.transactionId!, transactionStatus);

        switch (transactionStatus) {
          case 'settlement':
          case 'capture':
            _showToast("Pembayaran berhasil", false);
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThankYouPage(),
                ),
              );
            }
            break;
          
          case 'pending':
            _showToast("Pembayaran sedang diproses", false);
            if (mounted) {
              Navigator.of(context).pop();
            }
            break;
          
          default:
            _showToast("Status pembayaran: ${transactionData['status_message']}", true);
            Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint("Error in transaction callback: $e");
        _showToast("Terjadi kesalahan: ${e.toString()}", true);
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  Future<void> _loadOrderData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('order')
          .doc(widget.orderId)
          .get();
      
      if (doc.exists) {
        setState(() {
          orderData = doc.data();
        });
      }
    } catch (e) {
      debugPrint("Error loading order data: $e");
    }
  }

  Future<void> _updatePaymentStatus(String midtransId, String paymentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('order')
          .doc(widget.orderId)
          .update({
        'PaymentStatus': paymentStatus,
        'MidtransId': midtransId,
      });
    } catch (e) {
      debugPrint("Error updating payment status: $e");
    }
  }

  void _showToast(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String formatCurrency(num value) {
    final formatter = NumberFormat.decimalPattern();
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    if (orderData == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.grey[100]!, Colors.white],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Pembayaran',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Product Image
            Container(
              width: double.infinity,
              height: 220,
              child: Stack(
                children: [
                  // Background Image
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(orderData!['PacketImage'] ?? 'https://via.placeholder.com/400'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  // Content
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderData!['PacketName'] ?? 'Paket Makeup',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Rp ${formatCurrency(orderData!['TotalPrice'] ?? 0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Details Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.receipt_long, color: Colors.grey[700]),
                              ),
                              const SizedBox(width: 15),
                              const Text(
                                'Detail Pesanan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildInfoRow('Order ID', orderData!['OrderId']),
                              _buildInfoRow('Tanggal', orderData!['Date']),
                              _buildInfoRow('Waktu', orderData!['Time']),
                              _buildInfoRow('Alamat', orderData!['Address']),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Payment Button
                  Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() => _isLoading = true);
                              try {
                                final response = await http.post(
                                  Uri.parse("https://nextjs-midtrans-api-example-o2x4fdoph-farhan-mualifs-projects.vercel.app/api"),
                                  headers: {"Content-Type": "application/json"},
                                  body: jsonEncode({
                                    "order_id": widget.orderId,
                                    "gross_amount": orderData!['TotalPrice']
                                  })
                                );
                                
                                if (response.statusCode == 200) {
                                  final jsonResponse = jsonDecode(response.body);
                                  final token = jsonResponse['token'];
                                  midtransService.startPaymentUiFlow(token);
                                } else {
                                  throw Exception('Failed to get payment token');
                                }
                              } catch (e) {
                                _showToast("Gagal memulai pembayaran: $e", true);
                              } finally {
                                setState(() => _isLoading = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'BAYAR SEKARANG',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    midtransService.removeTransactionFinishedCallback();
    super.dispose();
  }
}

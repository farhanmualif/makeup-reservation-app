import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:reservastion/ThankyouPage.dart';
import 'package:reservastion/pending_screen.dart';
import 'package:reservastion/services/midtrans_services.dart';
import 'package:reservastion/services/token_services.dart';
import 'package:uuid/uuid.dart';

class ResponsePutData {
  String msg;
  String data;
  bool status;

  ResponsePutData({
    required this.msg,
    required this.data,
    required this.status,
  });
}

// ignore: must_be_immutable
class CheckoutPage extends StatefulWidget {
  CheckoutPage({super.key, required this.idPaket, required this.price});

  String? idPaket;
  double? price;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  var uuid = const Uuid();
  bool paymentSuccess = false;
  bool _isLoading = false;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final String userUid = FirebaseAuth.instance.currentUser!.uid;
  String? orderId;
  String? _paymentOption;
  final MidtransService midtransService = MidtransService();

  @override
  void initState() {
    super.initState();
    _initSDK();
  }

  void _initSDK() async {
    await midtransService.initSDK(); // Initialize MidtransService
    midtransService.setTransactionFinishedCallback((result) async {
      debugPrint("Transaction Result: ${result.toJson()}");
      try {
        // Handle cancelled transaction
        if (result.isTransactionCanceled) {
          _showToast("Transaksi dibatalkan", false);
          Navigator.of(context).pop();
          return;
        }

        // Check payment status using the order ID
        final paymentStatusResponse =
            await midtransService.checkPaymentStatus(orderId!);

        await _saveOrder(
            result.transactionId!, paymentStatusResponse?['status']);

        if (paymentStatusResponse != null &&
            paymentStatusResponse['status'] == 'success') {
          final transactionData = paymentStatusResponse['data'];
          final transactionStatus = transactionData['transaction_status'];

          // Handle different transaction statuses
          if (transactionStatus == 'settlement' ||
              transactionStatus == 'capture') {
            _showToast("Pembayaran berhasil", false);
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThankYouPage(),
                ),
              );
            }
          } else if (transactionStatus == 'pending') {
            _showToast("Pembayaran sedang diproses", false);
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => PendingScreen(
                    orderId: orderId!,
                    paymentStatus: transactionStatus,
                    paymentDetails: result.toJson(),
                  ),
                ),
              );
            }
          } else {
            _showToast(
                "Status pembayaran: ${transactionData['status_message']}",
                true);
            Navigator.of(context).pop();
          }
        } else {
          _showToast("Gagal memeriksa status pembayaran", true);
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

  void _showToast(String message, bool isError) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      timeInSecForIosWeb: 1,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  void dispose() {
    midtransService.removeTransactionFinishedCallback();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      final String formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('order')
          .where('Date', isEqualTo: "${formattedDate}T00:00:00.000")
          .get();
      if (snapshot.docs.isNotEmpty) {
        _showToast('Tanggal Sudah di booking, cari tanggal yang lain', true);
      } else {
        setState(() {
          _selectedDate = picked;
          _dateController.text = formattedDate;
        });
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text =
            '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<ResponsePutData> _saveOrder(
      String midtransId, String paymentStatus) async {
    if (_selectedDate != null &&
        _selectedTime != null &&
        _addressController.text.isNotEmpty &&
        _paymentOption != null) {
      double paidAmount =
          _paymentOption == 'full' ? widget.price! : widget.price! / 2;
      bool paidOff = _paymentOption == 'full';

      var order = FirebaseFirestore.instance.collection('order').doc(orderId);
      await order.set({
        'UserUid': userUid,
        'MidtransId': midtransId,
        'OrderId': orderId,
        'PacketId': widget.idPaket,
        "TotalPrice": widget.price,
        'PaidAmount': paidAmount,
        'PaymentStatus': paymentStatus,
        'Status': 'PENDING',
        'PaymentOption': _paymentOption,
        'PaidOff': paidOff,
        'Date': _selectedDate!.toIso8601String(),
        'Time':
            '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        'Address': _addressController.text,
        'CreatedAt': FieldValue.serverTimestamp(),
      });

      return ResponsePutData(
          msg: "berhasil insert data", data: order.id, status: true);
    } else {
      return ResponsePutData(
          msg: "Gagal insert data. Pastikan semua field terisi.",
          data: "",
          status: false);
    }
  }

  String formatCurrency(num value) {
    final formatter = NumberFormat.decimalPattern();
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TANTI MAKEUP STUDIO'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tentukan Jadwal',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    hintText: 'Pilih Tanggal',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: () => _selectTime(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: _timeController,
                  decoration: const InputDecoration(
                    hintText: 'Pilih Waktu',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _paymentOption,
              hint: const Text('Pilih Mode Pembayaran'),
              items: [
                DropdownMenuItem(
                  value: 'full',
                  child: Text('Bayar Penuh'),
                ),
                DropdownMenuItem(
                  value: 'half',
                  child: Text('Bayar Setengah'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _paymentOption = value;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'Alamat',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  var uid = const Uuid();
                  setState(() {
                    orderId = uid.v4();
                  });
                  try {
                    setState(() {
                      _isLoading = true;
                    });
                    double amountToPay = widget.price!;

                    if (_paymentOption == 'half') {
                      amountToPay /= 2;
                    }

                    final result = await TokenServices().getToken(
                      orderId: orderId!,
                      idPacket: widget.idPaket.toString(),
                      price: amountToPay,
                    );

                    if (result.isRight()) {
                      String? token = result.fold((l) => null, (r) => r.token);

                      if (token != null) {
                        midtransService.startPaymentUiFlow(token);
                      } else {
                        _showToast('Token cannot be null', true);
                      }
                    } else {
                      _showToast('Transaction Failed', true);
                    }
                  } catch (e) {
                    rethrow;
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(288, 51),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : const Text('LAKUKAN PEMBAYARAN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

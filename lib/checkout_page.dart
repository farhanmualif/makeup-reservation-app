import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:reservastion/ThankyouPage.dart';
import 'package:reservastion/paket.dart';
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

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  MidtransSDK? _midtrans;
  final String userUid = FirebaseAuth.instance.currentUser!.uid;
  String? orderId;

  @override
  void initState() {
    super.initState();
    _initSDK();
  }

  void _initSDK() async {
    _midtrans = await MidtransSDK.init(
      config: MidtransConfig(
        clientKey: "SB-Mid-client--_ZWw6ZvPAYWy51Y",
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
    _midtrans!.setTransactionFinishedCallback((result) async {
      var response = await _saveOrder();
      if (response.status == true) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ThankYouPage(),
            ));
      } else {
        _showToast("gagal melakukan order", true);
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
    _midtrans?.removeTransactionFinishedCallback();
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
      // Periksa apakah tanggal yang dipilih sudah ada di database
      final String formattedDate = DateFormat('yyyy-MM-dd').format(picked);

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('order')
          .where('Date', isEqualTo: "${formattedDate}T00:00:00.000")
          .get();
      if (snapshot.docs.isNotEmpty) {
        // Tanggal sudah ada di database, tampilkan pesan error
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

  Future<ResponsePutData> _saveOrder() async {
    if (_selectedDate != null &&
        _selectedTime != null &&
        _addressController.text.isNotEmpty) {
      // add custome order id
      var response =
          FirebaseFirestore.instance.collection('order').doc(orderId);
      await response.set({
        'UserUid': userUid,
        'PacketId': widget.idPaket,
        "TotalPrice": widget.price,
        'Date': _selectedDate!.toIso8601String(),
        'Time':
            '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        'Address': _addressController.text,
      });

      // Navigasi ke halaman lain setelah berhasil menyimpan order
      return ResponsePutData(
          msg: "berhasil insert data", data: response.id, status: true);
    } else {
      // Tampilkan pesan error jika ada field yang belum diisi

      return ResponsePutData(
          msg: "berhasil insert data", data: "", status: true);
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
                    final result = await TokenServices().getToken(
                      orderId: orderId!,
                      idPacket: widget.idPaket.toString(),
                      price: widget.price!,
                    );

                    if (result.isRight()) {
                      String? token = result.fold((l) => null, (r) => r.token);

                      if (token != null) {
                        _midtrans?.startPaymentUiFlow(
                          token: token,
                        );
                      } else {
                        _showToast('Token cannot be null', true);
                      }
                    } else {
                      _showToast('Transaction Failed', true);
                    }
                  } catch (e) {
                    rethrow;
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Warna latar belakang tombol
                  foregroundColor: Colors.white, // Warna teks tombol
                  minimumSize: const Size(288, 51), // Ukuran tombol
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0), // Bentuk tombol
                  ),
                ),
                child: const Text('LAKUKAN PEMBAYARAN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

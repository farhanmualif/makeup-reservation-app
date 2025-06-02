import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:reservastion/screen/ThankyouPage.dart';
import 'package:reservastion/screen/pending_screen.dart';
import 'package:reservastion/services/midtrans_services.dart';
import 'package:reservastion/services/token_services.dart';
import 'package:reservastion/utils/utils.dart';
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
  Set<DateTime> _bookedDates = {};
  Set<DateTime> _dayOffDates = {};

  @override
  void initState() {
    super.initState();
    _initSDK();
    _loadBookedAndDayOffDates();
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

  Future<void> _loadBookedAndDayOffDates() async {
    try {
      // Load booked dates
      final orderDocs =
          await FirebaseFirestore.instance.collection('order').get();
      _bookedDates = orderDocs.docs
          .map((doc) {
            final dateString = doc.data()['Date'] as String;
            final dateTime = DateTime.parse(dateString).toUtc();
            final status = doc.data()['Status'] as String;

            if (status == 'PENDING' || status == 'ACCEPT') {
              return DateTime(dateTime.year, dateTime.month, dateTime.day);
            } else {
              return null;
            }
          })
          .where((date) => date != null)
          .cast<DateTime>()
          .toSet();

      // Load day off dates
      final dayOffDocs =
          await FirebaseFirestore.instance.collection('day_off').get();
      _dayOffDates = dayOffDocs.docs.map((doc) {
        final dateString = doc.data()['Date'] as String;
        return DateTime.parse(dateString).toLocal();
      }).toSet();
    } catch (e) {
      debugPrint('Error loading dates: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      selectableDayPredicate: (DateTime date) {
        // Convert the date to match the format of booked and day off dates
        final dateToCheck = DateTime(date.year, date.month, date.day);

        // Check if the date is neither booked nor a day off
        return !_bookedDates.contains(dateToCheck) &&
            !_dayOffDates.contains(dateToCheck);
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'TANTI MAKEUP',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.grey[800],
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Form Pemesanan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Silahkan isi data pemesanan Anda',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jadwal Makeup',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDateField(),
                      const SizedBox(height: 16),
                      _buildTimeField(),
                      const SizedBox(height: 24),
                      const Text(
                        'Metode Pembayaran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPaymentOption(),
                      const SizedBox(height: 24),
                      const Text(
                        'Alamat Pemesan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAddressField(),
                      const SizedBox(height: 32),
                      _buildPaymentButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AbsorbPointer(
          child: TextField(
            controller: _dateController,
            decoration: InputDecoration(
              hintText: 'Pilih Tanggal',
              prefixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField() {
    return GestureDetector(
      onTap: () => _selectTime(context),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AbsorbPointer(
          child: TextField(
            controller: _timeController,
            decoration: InputDecoration(
              hintText: 'Pilih Waktu',
              prefixIcon: Icon(Icons.access_time, color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _paymentOption,
        hint: const Text('Pilih Mode Pembayaran'),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: const [
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
      ),
    );
  }

  Widget _buildAddressField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _addressController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Masukkan Alamat',
          prefixIcon: Icon(Icons.location_on, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () async {
                setState(() {
                  orderId = generateOrderId();
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
          backgroundColor: Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Lanjutkan Pembayaran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

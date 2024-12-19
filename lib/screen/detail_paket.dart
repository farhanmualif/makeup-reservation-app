import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reservastion/screen/checkout_page.dart';
import 'package:reservastion/screen/form_edit_packet.dart';
import 'package:reservastion/screen/paket.dart';
import 'package:reservastion/screen/admin_dashboard.dart';
import 'package:reservastion/utils/utils.dart';
import 'package:table_calendar/table_calendar.dart';

class DetailPaket extends StatefulWidget {
  final String paketId;

  const DetailPaket({super.key, required this.paketId});

  @override
  _DetailPaketState createState() => _DetailPaketState();
}

class _DetailPaketState extends State<DetailPaket> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentSnapshot? _paketSnapshot;
  User? user = FirebaseAuth.instance.currentUser;
  DateTime _focusedDay = DateTime.now();
  Set<DateTime> _bookedDates = {};
  Set<DateTime> _holidayDates = {}; // Tambahkan ini

  @override
  void initState() {
    super.initState();
    _getPaketData();
    _getOrderDate();
    _getHolidayDates(); // Tambahkan ini
  }

  Future<void> _getPaketData() async {
    final paketDoc =
        await _firestore.collection('paket_makeup').doc(widget.paketId).get();

    if (paketDoc.exists) {
      setState(() {
        _paketSnapshot = paketDoc;
      });
    }
  }

  Future<void> _getOrderDate() async {
    try {
      final orderDocs = await _firestore.collection('order').get();

      setState(() {
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
      });
      debugPrint('Booked dates: $_bookedDates');
    } catch (e) {
      debugPrint('Error fetching order dates: $e');
    }
  }

  // Tambahkan fungsi ini
  Future<void> _getHolidayDates() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('day_off').get();

      setState(() {
        _holidayDates = snapshot.docs.map((doc) {
          final dateString = doc['Date'] as String;
          final date = DateTime.parse(dateString).toLocal();
          return DateTime(date.year, date.month, date.day);
        }).toSet();
      });
      debugPrint('Holiday dates loaded: $_holidayDates');
    } catch (e) {
      debugPrint('Error fetching holiday dates: $e');
    }
  }

  Future<void> _deleteProduct() async {
    try {
      await FirebaseFirestore.instance
          .collection('paket_makeup')
          .doc(widget.paketId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paket berhasil dihapus'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const PaketPage(),
        ),
      );
    } catch (e) {
      print('Error deleting product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat menghapus paket'),
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Apakah Anda yakin ingin menghapus paket ini?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Hapus'),
              onPressed: () {
                _deleteProduct();
                Navigator.pushReplacementNamed(context, '/paket');
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> checkRoleUser() async {
    try {
      var findUser = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      return findUser.get("rool");
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_paketSnapshot == null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('TANTI MAKEUP'),
          backgroundColor: Colors.grey[800],
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final namapaket = _paketSnapshot!.get('Name');
    final id = _paketSnapshot!.id;
    final harga = _paketSnapshot!.get('Price');
    final gambar = _paketSnapshot!.get('Image');
    final deskripsi = _paketSnapshot!.get('Description');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.grey[800],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    gambar,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      namapaket,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        formatPrice(harga),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Deskripsi Paket",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        deskripsi,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FutureBuilder<String>(
                      future: checkRoleUser(),
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          final role = snapshot.data!;
                          return role == 'user'
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Jadwal Tersedia",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            spreadRadius: 1,
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: TableCalendar(
                                        firstDay: DateTime.utc(2010, 10, 16),
                                        lastDay: DateTime.utc(2030, 3, 14),
                                        focusedDay: _focusedDay,
                                        calendarFormat: CalendarFormat.month,
                                        calendarStyle: CalendarStyle(
                                          selectedTextStyle: const TextStyle(
                                              color: Colors.white),
                                          todayDecoration: BoxDecoration(
                                            color: Colors.grey[400],
                                            shape: BoxShape.circle,
                                          ),
                                          disabledTextStyle: const TextStyle(
                                              color: Colors.grey),
                                          disabledDecoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        headerStyle: const HeaderStyle(
                                          formatButtonVisible: false,
                                          titleCentered: true,
                                        ),
                                        enabledDayPredicate: (day) {
                                          final dateWithoutTime = DateTime(
                                              day.year, day.month, day.day);
                                          final isBooked = _bookedDates
                                              .contains(dateWithoutTime);
                                          final isHoliday = _holidayDates
                                              .contains(dateWithoutTime);
                                          return !isBooked && !isHoliday;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CheckoutPage(
                                                idPaket: id,
                                                price: double.parse(
                                                    harga.replaceAll(
                                                        RegExp(r'[^0-9]'), '')),
                                              ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[800],
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                          'Pesan Sekarang',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FormEditPacket(
                                                product: Product(
                                                  id: id,
                                                  name: namapaket,
                                                  price: double.parse(
                                                      harga.replaceAll(
                                                          RegExp(r'[^0-9]'),
                                                          '')),
                                                  deskripsi: deskripsi,
                                                  imageUrl: gambar,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[800],
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text('Edit Paket'),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed:
                                            _showDeleteConfirmationDialog,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red[400],
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text('Hapus Paket'),
                                      ),
                                    ),
                                  ],
                                );
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UnorderedList extends StatelessWidget {
  final List<String> items;

  const UnorderedList(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Text('• $item')).toList(),
    );
  }
}

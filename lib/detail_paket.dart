import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reservastion/checkout_page.dart';
import 'package:reservastion/form_edit_packet.dart';
import 'package:reservastion/paket.dart';
import 'package:reservastion/screen/admin_dashboard.dart';
import 'package:table_calendar/table_calendar.dart';

class DetailPaket extends StatefulWidget {
  final String paketId;

  const DetailPaket({super.key, required this.paketId});

  @override
  // ignore: library_private_types_in_public_api
  _DetailPaketState createState() => _DetailPaketState();
}

class _DetailPaketState extends State<DetailPaket> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentSnapshot? _paketSnapshot;
  User? user = FirebaseAuth.instance.currentUser;
  DateTime _focusedDay = DateTime.now();
  Set<DateTime> _bookedDates = {};

  @override
  void initState() {
    super.initState();
    _getPaketData();
    _getOrderDate();
  }

  Future<void> _getPaketData() async {
    final paketDoc =
        await _firestore.collection('paket_makeup').doc(widget.paketId).get();

    if (paketDoc.exists) {
      setState(() {
        _paketSnapshot = paketDoc;
      });
    } else {
      // Tangani jika dokumen tidak ditemukan
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
              final status = doc.data()['Status'] as String; // Ambil status

              // Hanya tambahkan tanggal ke _bookedDates jika status adalah 'PENDING' atau 'ACCEPT'
              if (status == 'PENDING' || status == 'ACCEPT') {
                return DateTime(dateTime.year, dateTime.month, dateTime.day);
              } else {
                return null; // Kembalikan null jika statusnya 'FINISHED' atau 'DENIED'
              }
            })
            .where((date) => date != null) // Hapus null
            .cast<DateTime>()
            .toSet();
      });
      debugPrint('Booked dates: $_bookedDates');
    } catch (e) {
      debugPrint('Error fetching order dates: $e');
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
      barrierDismissible: false, // User must tap button to dismiss the dialog
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
        backgroundColor: Colors.grey[300],
        appBar: AppBar(
          title: const Text('TANTI MAKEUP STUDIO'),
          backgroundColor: Colors.grey[300],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final namapaket = _paketSnapshot!.get('Name');
    final id = _paketSnapshot!.id;
    final harga = _paketSnapshot!.get('Price');
    final gambar = _paketSnapshot!.get('Image');
    final deskripsi = _paketSnapshot!.get('Description');

    Product prod = Product(
        id: id,
        name: namapaket,
        price: double.tryParse(harga) ?? 0.0,
        deskripsi: deskripsi, // Menggunakan 0.0 jika harga tidak valid
        imageUrl: gambar);

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('TANTI MAKEUP STUDIO'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            color: const Color(0x00cacaca),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Home / Detail',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Image.network(
                  gambar,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 16.0),
                Text(
                  namapaket,
                  style: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'IDR $harga',
                  style: const TextStyle(
                    fontSize: 18.0,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16.0),
                const Text("deskripsi:"),
                Text(deskripsi),
                const SizedBox(height: 16.0),
                FutureBuilder<String>(
                  future: checkRoleUser(),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      final role = snapshot.data!;
                      return role == 'user'
                          ? Center(
                              child: Column(
                                children: [
                                  const Text("Tersedia Pada Tanggal:",
                                      style: TextStyle(fontSize: 20)),
                                  Column(
                                    children: [
                                      TableCalendar(
                                        firstDay: DateTime.utc(2010, 10, 16),
                                        lastDay: DateTime.utc(2030, 3, 14),
                                        focusedDay: _focusedDay,
                                        calendarFormat: CalendarFormat.month,
                                        calendarStyle: CalendarStyle(
                                          selectedTextStyle:
                                              TextStyle(color: Colors.white),
                                          disabledTextStyle:
                                              TextStyle(color: Colors.grey),
                                          disabledDecoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.3),
                                            shape: BoxShape.rectangle,
                                            borderRadius:
                                                BorderRadius.circular(5.0),
                                          ),
                                        ),
                                        headerStyle: HeaderStyle(
                                          formatButtonVisible: false,
                                          titleCentered: true,
                                        ),
                                        enabledDayPredicate: (day) {
                                          return !_bookedDates.contains(
                                              DateTime(day.year, day.month,
                                                  day.day));
                                        },
                                      ),
                                      const Text(
                                          "*Tanggal yang ditandai abu-abu tidak tersedia"),
                                    ],
                                  ),
                                  SizedBox(height: 30),
                                  ElevatedButton(
                                    onPressed: () {
                                      final idpaket = _paketSnapshot!.id;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return CheckoutPage(
                                              idPaket: idpaket,
                                              price: double.parse(
                                                  harga.replaceAll(',', '')),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(288, 51),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    child: const Text('PILIH'),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                const SizedBox(
                                  height: 18,
                                ),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FormEditPacket(
                                            product: prod,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(288, 51),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    child: const Text('EDIT'),
                                  ),
                                ),
                                const SizedBox(
                                  height: 6,
                                ),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: _showDeleteConfirmationDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(288, 51),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    child: const Text('HAPUS'),
                                  ),
                                )
                              ],
                            );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
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

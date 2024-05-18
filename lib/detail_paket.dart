import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reservastion/checkout_page.dart';
import 'package:reservastion/form_edit_packet.dart';
import 'package:reservastion/paket.dart';
import 'package:reservastion/screen/admin_dashboard.dart';

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

  @override
  void initState() {
    super.initState();
    _getPaketData();
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
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
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
                Navigator.of(context).pop();
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
        appBar: AppBar(
          title: const Text('TANTI MAKEUP STUDIO'),
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
        id: id, name: namapaket, price: double.parse(harga), imageUrl: gambar);

    return Scaffold(
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
                const SizedBox(height: 8.0),
                const SizedBox(height: 16.0),
                checkRoleUser() == "user"
                    ? Center(
                        child: ElevatedButton(
                          onPressed: () {
                            final idpaket = _paketSnapshot!.id;
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CheckoutPage(
                                          idPaket: idpaket,
                                          price: int.parse(harga),
                                        )));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.black, // Warna latar belakang tombol
                            foregroundColor: Colors.white, // Warna teks tombol
                            minimumSize: const Size(288, 51), // Ukuran tombol
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8.0), // Bentuk tombol
                            ),
                          ),
                          child: const Text('PILIH'),
                        ),
                      )
                    : Column(
                        children: [
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                final idpaket = _paketSnapshot!.id;

                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => FormEditPacket(
                                              product: prod,
                                            )));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.black, // Warna latar belakang tombol
                                foregroundColor:
                                    Colors.white, // Warna teks tombol
                                minimumSize:
                                    const Size(288, 51), // Ukuran tombol
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      8.0), // Bentuk tombol
                                ),
                              ),
                              child: const Text('UPDATE'),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Center(
                            child: ElevatedButton(
                              onPressed: _showDeleteConfirmationDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.red, // Warna latar belakang tombol
                                foregroundColor:
                                    Colors.white, // Warna teks tombol
                                minimumSize:
                                    const Size(288, 51), // Ukuran tombol
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      8.0), // Bentuk tombol
                                ),
                              ),
                              child: const Text('DELETE'),
                            ),
                          )
                        ],
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

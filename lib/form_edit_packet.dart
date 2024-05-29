import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:reservastion/root_page.dart';
import 'package:reservastion/screen/admin_dashboard.dart';

class FormEditPacket extends StatefulWidget {
  final Product product;

  const FormEditPacket({super.key, required this.product});

  @override
  // ignore: library_private_types_in_public_api
  _FormEditPacketState createState() => _FormEditPacketState();
}

class _FormEditPacketState extends State<FormEditPacket> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _hargaController;
  late TextEditingController _deskripsiController;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.product.name);
    _deskripsiController =
        TextEditingController(text: widget.product.deskripsi);
    _hargaController =
        TextEditingController(text: widget.product.price.toString());
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future _submitForm() async {
    try {
      if (_formKey.currentState!.validate()) {
        final updatedData = {
          'Name': _namaController.text,
          'Price': _hargaController.text,
          'Description': _deskripsiController.text
        };

        await FirebaseFirestore.instance
            .collection('paket_makeup')
            .doc(widget.product.id)
            .update(updatedData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paket berhasil diperbarui'),
          ),
        );

        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const RootPage(),
            ));
      }
    } catch (e) {
      return Exception(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Paket'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Paket',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama Paket tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _hargaController,
                decoration: const InputDecoration(
                  labelText: 'Harga Paket',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga Paket tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.black, // Warna latar belakang tombol
                    foregroundColor: Colors.white, // Warna teks tombol
                    minimumSize: const Size(288, 51), // Ukuran tombol
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0), // Bentuk tombol
                    ),
                  ),
                  child: const Text('Update Paket')),
            ],
          ),
        ),
      ),
    );
  }
}

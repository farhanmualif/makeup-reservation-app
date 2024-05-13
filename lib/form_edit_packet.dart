import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:reservastion/screen/dashboard_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditPaketForm extends StatefulWidget {
  final Product product;

  const EditPaketForm({super.key, required this.product});

  @override
  // ignore: library_private_types_in_public_api
  _EditPaketFormState createState() => _EditPaketFormState();
}

class _EditPaketFormState extends State<EditPaketForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _hargaController;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.product.name);
    _hargaController =
        TextEditingController(text: widget.product.price.toString());
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'nama': _namaController.text,
        'harga': _hargaController.text,
        'gambar': widget.product.imageUrl,
      };

      await FirebaseFirestore.instance
          .collection('products_packet')
          .doc(widget.product.id)
          .update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paket berhasil diperbarui'),
        ),
      );

      Navigator.pop(context);
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
                  labelText: 'Harga',
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
                child: const Text('Update Paket'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

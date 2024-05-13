import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

class AddPaketForm extends StatefulWidget {
  const AddPaketForm({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddPaketFormState createState() => _AddPaketFormState();
}

class _AddPaketFormState extends State<AddPaketForm> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _hargaController = TextEditingController();
  File? _imageFile;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> _selectImage() async {
    // Meminta izin akses galeri

    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final imageTemp = File(image.path);
      setState(() => _imageFile = imageTemp);
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _imageFile != null) {
      final nama = _namaController.text;
      final harga = _hargaController.text;

      if (_imageFile == null) return;
      final fileName = path.basename(_imageFile!.path);
      final destination = 'files/$fileName';

      try {
        final ref = firebase_storage.FirebaseStorage.instance
            .ref(destination)
            .child('file/');
        await ref.putFile(_imageFile!);
      } catch (e) {
        print('error occured');
      }

      // Tambahkan data paket ke Cloud Firestore
      await _firestore.collection('paket_makeup').add({
        'nama': nama,
        'harga': harga,
        'gambar': fileName,
      });

      // Reset form setelah berhasil menambahkan paket
      _formKey.currentState!.reset();
      _imageFile = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paket berhasil ditambahkan'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi semua field dan pilih gambar'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Paket'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _selectImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _imageFile == null
                      ? const Center(
                          child: Text('Pilih Gambar'),
                        )
                      : Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Tambah Paket'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

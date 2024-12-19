import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeletePaketDialog extends StatelessWidget {
  final String productId;

  const DeletePaketDialog({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hapus Paket'),
      content: const Text('Apakah Anda yakin ingin menghapus paket ini?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            FirebaseFirestore.instance
                .collection('products_packet')
                .doc(productId)
                .delete();
            Navigator.pop(context);
          },
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}

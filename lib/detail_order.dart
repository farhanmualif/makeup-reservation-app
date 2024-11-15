import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reservastion/model/packet_model.dart';
import 'package:reservastion/model/user_model.dart';
import 'package:reservastion/model/order_model.dart';
import 'package:intl/intl.dart';
import 'package:reservastion/utils/utils.dart';

class DetailOrder extends StatefulWidget {
  final String orderId;

  const DetailOrder({Key? key, required this.orderId}) : super(key: key);

  @override
  State<DetailOrder> createState() => _DetailOrderState();
}

class _DetailOrderState extends State<DetailOrder> {
  bool _isLoading = false;

  Future<void> _updateOrderStatus(
      BuildContext context, String orderId, String status) async {
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('order').doc(orderId).update({
        'Status': status,
      });

      if (!mounted) return;

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(status == 'ACCEPT'
              ? 'Berhasil Menyetujui Pemesanan'
              : 'Berhasil Menolak Pemesanan'),
          backgroundColor: status == 'ACCEPT' ? Colors.green : Colors.red,
        ),
      );

      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _getOrderDetails(String orderId) async {
    final orderDoc =
        await FirebaseFirestore.instance.collection('order').doc(orderId).get();

    if (!orderDoc.exists) {
      throw Exception('Order not found');
    }

    final orderData = OrderModel.fromMap(orderDoc.data()!);

    // Get user data
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(orderData.userUid)
        .get();
    final userData = User.fromMap(userDoc.data()!);

    // Get packet data
    final packetDoc = await FirebaseFirestore.instance
        .collection('paket_makeup')
        .doc(orderData.packetId)
        .get();
    final packetData = Packet.fromMap(packetDoc.data()!);

    return {
      'order': orderData,
      'user': userData,
      'packet': packetData,
    };
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: AppBar(
              title: const Text('Detail Pesanan'),
            ),
            body: FutureBuilder<Map<String, dynamic>>(
              future: _getOrderDetails(widget.orderId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orderData = snapshot.data!['order'] as OrderModel;
                final userData = snapshot.data!['user'] as User;
                final packetData = snapshot.data!['packet'] as Packet;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Package Image and Details
                      Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (packetData.image.isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4.0),
                                ),
                                child: Image.network(
                                  packetData.image,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    packetData.name,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    packetData.description,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    formatPrice(packetData.price),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Customer Information
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Informasi Pemesan',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow('Nama', userData.fullName),
                              _buildInfoRow('Email', userData.email),
                              _buildInfoRow('Alamat', orderData.address),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Order Details
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detail Pesanan',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                  'Tanggal',
                                  DateFormat('dd MMMM yyyy')
                                      .format(DateTime.parse(orderData.date))),
                              _buildInfoRow('Waktu', orderData.time),
                              _buildInfoRow(
                                  'Status',
                                  orderData.status == "PENDING"
                                      ? "Menunggu Persetujuan"
                                      : orderData.status == "ACCEPT"
                                          ? "Disetujui"
                                          : orderData.status == "DENIED"
                                              ? "Ditolak"
                                              : orderData.status == 'FINISHED'
                                                  ? "Selesai"
                                                  : "Status Tidak Valid"),
                              _buildInfoRow('Total Pembayaran',
                                  formatPrice(orderData.totalPrice.toString())),
                              _buildInfoRow(
                                  'Status Pembayaran',
                                  orderData.paymentStatus == "pending"
                                      ? "Menunggu Pembayaran"
                                      : "Lunas"),
                              const SizedBox(height: 20),
                              if (orderData.status == 'PENDING') ...[
                                SizedBox(
                                  width: 500,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _updateOrderStatus(
                                          context, widget.orderId, 'ACCEPT');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      textStyle: const TextStyle(fontSize: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Setujui',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: 500,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _updateOrderStatus(
                                          context, widget.orderId, 'DENIED');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      textStyle: const TextStyle(fontSize: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Tolak',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else if (orderData.status == 'ACCEPT') ...[
                                SizedBox(
                                  width: 500,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _updateOrderStatus(
                                          context, widget.orderId, 'FINISHED');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      textStyle: const TextStyle(fontSize: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Selesai',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

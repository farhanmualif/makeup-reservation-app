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
      // Periksa apakah dokumen ada
      final docSnapshot = await FirebaseFirestore.instance
          .collection('order')
          .doc(orderId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Order tidak ditemukan');
      }

      // Lakukan update status
      await FirebaseFirestore.instance.collection('order').doc(orderId).update({
        'Status': status,
        'UpdatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      String message;
      if (status == 'ACCEPT') {
        message = 'Berhasil Menyetujui Pemesanan';
      } else if (status == 'DENIED') {
        message = 'Berhasil Menolak Pemesanan';
      } else {
        message = 'Berhasil Mengubah Status Pesanan';
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: (status == 'ACCEPT' || status == 'FINISHED' || status == 'DENIED')
              ? Colors.green
              : Colors.red,
        ),
      );

      Navigator.of(context).pop();
      return;
    } catch (e) {
      print('Error updating status: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
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
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
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
                  child: Column(
                    children: [
                      // Header Section
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
                              'Detail Pesanan',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(orderData.status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getStatusText(orderData.status),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Paket Section
                            _buildSection(
                              'Paket Makeup',
                              [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(
                                    packetData.image,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  packetData.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  packetData.description,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  formatPrice(packetData.price),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Customer Section
                            _buildSection(
                              'Informasi Pelanggan',
                              [
                                _buildInfoRow('Nama', userData.fullName),
                                _buildInfoRow('Email', userData.email),
                                _buildInfoRow('Alamat', orderData.address),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Order Details Section
                            _buildSection(
                              'Detail Pesanan',
                              [
                                _buildInfoRow(
                                    'Tanggal',
                                    DateFormat('dd MMMM yyyy').format(
                                        DateTime.parse(orderData.date))),
                                _buildInfoRow('Waktu', orderData.time),
                                _buildInfoRow(
                                    'Total Pembayaran',
                                    formatPrice((orderData.totalPrice as double)
                                        .toInt()
                                        .toString())),
                                _buildInfoRow(
                                    'Status Pembayaran',
                                    orderData.paymentStatus == "pending"
                                        ? "Menunggu Pembayaran"
                                        : "Lunas"),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Action Buttons
                            if (orderData.status == 'PENDING') ...[
                              _buildActionButton(
                                'Setujui Pesanan',
                                Colors.green,
                                () => _updateOrderStatus(
                                    context, widget.orderId, 'ACCEPT'),
                              ),
                              const SizedBox(height: 12),
                              _buildActionButton(
                                'Tolak Pesanan',
                                Colors.red,
                                () => _updateOrderStatus(
                                    context, widget.orderId, 'DENIED'),
                              ),
                            ] else if (orderData.status == 'ACCEPT') ...[
                              _buildActionButton(
                                'Selesaikan Pesanan',
                                Colors.blue,
                                () => _updateOrderStatus(
                                    context, widget.orderId, 'FINISHED'),
                              ),
                            ],
                          ],
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

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'MENUNGGU PERSETUJUAN';
      case 'ACCEPT':
        return 'DITERIMA';
      case 'DENIED':
        return 'DITOLAK';
      case 'FINISHED':
        return 'SELESAI';
      default:
        return 'MENUNGGU PERSETUJUAN';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPT':
        return Colors.green;
      case 'DENIED':
        return Colors.red;
      case 'FINISHED':
        return Colors.blue;
      default:
        return Colors.yellow;
    }
  }
}

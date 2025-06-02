import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reservastion/screen/admin/detail_order.dart';
import 'package:reservastion/model/packet_model.dart';
import 'package:reservastion/model/user_model.dart';
import 'package:reservastion/model/order_model.dart';
import 'package:intl/intl.dart'; // Tambahkan import ini
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:reservastion/utils/utils.dart';

class OrderIn extends StatefulWidget {
  const OrderIn({super.key});

  @override
  State<OrderIn> createState() => _OrderInState();
}

class _OrderInState extends State<OrderIn> {
  final CollectionReference historiPemesanan =
      FirebaseFirestore.instance.collection('order');
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference packet =
      FirebaseFirestore.instance.collection('paket_makeup');
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  // Fungsi untuk memformat tanggal
  String formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      return date; // Kembalikan format asli jika parsing gagal
    }
  }

  Future<User> getDataUser(String userUid) async {
    final snapshot = await users.doc(userUid).get();
    if (snapshot.exists) {
      return User.fromMap(snapshot.data() as Map<String, dynamic>);
    }
    return User(email: '', fullName: '');
  }

  Future<Packet> getPacketMakeup(String packetId) async {
    final snapshot = await packet.doc(packetId).get();
    if (snapshot.exists) {
      return Packet.fromMap(snapshot.data() as Map<String, dynamic>);
    }
    return Packet(name: '', description: '', image: '', price: '');
  }

  void _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() {});
    _refreshController.refreshCompleted();
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
      body: SmartRefresher(
        enablePullDown: true,
        header: const WaterDropHeader(),
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: StreamBuilder<QuerySnapshot>(
          stream: historiPemesanan.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Sort orders: PENDING first, then by CreatedAt
            final pemesanan = snapshot.data!.docs;
            pemesanan.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;

              final aStatus = aData['Status'] as String;
              final bStatus = bData['Status'] as String;

              // If one is PENDING and the other isn't, PENDING comes first
              if (aStatus == 'PENDING' && bStatus != 'PENDING') return -1;
              if (bStatus == 'PENDING' && aStatus != 'PENDING') return 1;

              // If both have same status, sort by CreatedAt
              final aTime = aData['CreatedAt'] as Timestamp?;
              final bTime = bData['CreatedAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime); // Descending order (newest first)
            });

            final pendingOrders = pemesanan.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['Status']?.toString().toUpperCase() == 'PENDING';
            }).length;

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Orderan Masuk',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$pendingOrders pemesanan menunggu persetujuan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pemesanan.length,
                    itemBuilder: (context, index) {
                      final order = OrderModel.fromMap(
                          pemesanan[index].data() as Map<String, dynamic>);

                      return FutureBuilder(
                        future: Future.wait([
                          getDataUser(order.userUid),
                          getPacketMakeup(order.packetId),
                        ]),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }

                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final userData = snapshot.data![0] as User;
                          final packetData = snapshot.data![1] as Packet;
                          final formattedDate = formatDate(order.date);

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailOrder(
                                    orderId: pemesanan[index].id,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
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
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: (packetData.image != null &&
                                                  packetData.image.isNotEmpty &&
                                                  Uri.tryParse(packetData.image)
                                                          ?.hasAbsolutePath ==
                                                      true &&
                                                  (packetData.image
                                                          .startsWith('http') ||
                                                      packetData.image
                                                          .startsWith('https')))
                                              ? Image.network(
                                                  packetData.image,
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.network(
                                                  "https://www.shutterstock.com/image-vector/default-ui-image-placeholder-wireframes-600nw-1037719192.jpg",
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                userData.fullName,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                packetData.name,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                      order.status),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  _getStatusText(order.status),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        _buildInfoRow('Alamat', order.address),
                                        _buildInfoRow('Tanggal',
                                            '$formattedDate - ${order.time}'),
                                        _buildInfoRow(
                                          'Total',
                                          formatPrice((order.totalPrice)
                                              .toInt()
                                              .toString()),
                                          isLast: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
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
        return Colors.grey;
    }
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

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (!isLast) const SizedBox(height: 12),
          if (!isLast)
            Divider(
              color: Colors.grey[200],
              height: 1,
            ),
        ],
      ),
    );
  }
}

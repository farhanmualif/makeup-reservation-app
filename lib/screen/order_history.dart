import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reservastion/screen/payment_page.dart';
import 'package:reservastion/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderHistory extends StatefulWidget {
  OrderHistory({super.key});

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  final CollectionReference orderHistory =
      FirebaseFirestore.instance.collection('order');

  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  final CollectionReference packet =
      FirebaseFirestore.instance.collection('paket_makeup');

  final User? currentUser = FirebaseAuth.instance.currentUser;

  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  Future<Map<String, dynamic>> getDataUser(String userId) async {
    final snapshot = await users.doc(userId).get();
    if (snapshot.exists) {
      return snapshot.data() as Map<String, dynamic>;
    }
    return {};
  }

  Future<Map<String, dynamic>> getPacketMakeup(String packetId) async {
    final snapshot = await packet.doc(packetId).get();

    if (snapshot.exists) {
      return snapshot.data() as Map<String, dynamic>;
    }
    return {};
  }

  void _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() {});
    _refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
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
          stream: orderHistory
              .where('UserUid', isEqualTo: currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Sort the documents by Status (ACCEPT first) and CreatedAt
            final pemesanan = snapshot.data!.docs;
            pemesanan.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;

              final aStatus = aData['Status'] as String;
              final bStatus = bData['Status'] as String;

              // If one is ACCEPT, it should come first
              if (aStatus == 'ACCEPT' && bStatus != 'ACCEPT') return -1;
              if (bStatus == 'ACCEPT' && aStatus != 'ACCEPT') return 1;

              // If neither is ACCEPT, PENDING comes before REJECT
              if (aStatus == 'PENDING' && bStatus == 'REJECT') return -1;
              if (bStatus == 'PENDING' && aStatus == 'REJECT') return 1;

              // If both have same status, sort by CreatedAt
              final aTime = aData['CreatedAt'] as Timestamp?;
              final bTime = bData['CreatedAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime); // Descending order (newest first)
            });

            if (pemesanan.isEmpty) {
              return const Center(
                child: Text(
                  'Belum ada riwayat pemesanan',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              );
            }

            print(
                "cek pemesanan: ${pemesanan.map((doc) => doc.data()).toList()}");

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
                        'Riwayat Pemesanan',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${pemesanan.length} pesanan',
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
                      final data =
                          pemesanan[index].data() as Map<String, dynamic>;
                      final idPemesanan = pemesanan[index].id;
                      final userId = data['UserUid'];
                      final packetId = data['PacketId'];

                      return FutureBuilder<Map<String, dynamic>>(
                        future: getDataUser(userId),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.hasData) {
                            final dataUser = userSnapshot.data!;
                            return FutureBuilder<Map<String, dynamic>>(
                              future: getPacketMakeup(packetId),
                              builder: (context, packetSnapshot) {
                                if (packetSnapshot.hasData) {
                                  final dataPacket = packetSnapshot.data!;
                                  debugPrint(
                                      'Raw TotalPrice: ${data['TotalPrice']}');
                                  debugPrint(
                                      'TotalPrice Type: ${data['TotalPrice'].runtimeType}');
                                  final totalPrice =
                                      (data['TotalPrice'] as double).toInt();
                                  debugPrint(
                                      'Converted TotalPrice: $totalPrice');
                                  return Container(
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
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child:
                                                    dataPacket['Image'] != null
                                                        ? Image.network(
                                                            dataPacket['Image'],
                                                            width: 80,
                                                            height: 80,
                                                            fit: BoxFit.cover,
                                                          )
                                                        : Image.network(
                                                            'https://www.shutterstock.com/image-vector/default-ui-image-placeholder-wireframes-600nw-1037719192.jpg',
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
                                                      dataPacket['Name'] ??
                                                          'Paket Silver',
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: _getStatusColor(
                                                            data['Status']),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Text(
                                                        _getStatusText(
                                                            data['Status'] ??
                                                                'PENDING'),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
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
                                              _buildInfoRow(
                                                  'ID Pemesanan', idPemesanan),
                                              _buildInfoRow('Nama Pemesan',
                                                  dataUser['fullname'] ?? ''),
                                              _buildInfoRow('Email',
                                                  dataUser['email'] ?? ''),
                                              _buildInfoRow('No. Telepon',
                                                  dataUser['phone'] ?? ''),
                                              _buildInfoRow(
                                                  'Alamat', data['Address']),
                                              _buildInfoRow(
                                                'Total Pembayaran',
                                                formatPrice(
                                                    totalPrice.toString()),
                                                isLast: true,
                                              ),
                                              if (data['Status'] == 'ACCEPT' &&
                                                  (data['PaymentStatus'] ==
                                                          null ||
                                                      data['PaymentStatus'] ==
                                                          'pending' ||
                                                      data['PaymentStatus'] ==
                                                          '')) ...[
                                                const SizedBox(height: 10),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            PaymentPage(
                                                          orderId:
                                                              pemesanan[index]
                                                                  .id,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.grey[800],
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Bayar Sekarang',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                            );
                          }
                          return const Center(
                              child: CircularProgressIndicator());
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

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
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

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'PROSES';
      case 'ACCEPT':
        return 'DITERIMA';
      case 'DENIED':
        return 'DITOLAK';
      case 'FINISHED':
        return 'SELESAI';
      default:
        return 'PROSES';
    }
  }
}

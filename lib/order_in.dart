import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reservastion/detail_order.dart';
import 'package:reservastion/model/packet_model.dart';
import 'package:reservastion/model/user_model.dart';
import 'package:reservastion/model/order_model.dart';
import 'package:intl/intl.dart'; // Tambahkan import ini

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History Pemesanan'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: historiPemesanan.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pemesanan = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pemesanan.length,
            itemBuilder: (context, index) {
              final order = OrderModel.fromMap(
                  pemesanan[index].data() as Map<String, dynamic>);

              if (order.userUid.isEmpty || order.packetId.isEmpty) {
                return const Center(child: Text('Invalid order data.'));
              }

              return FutureBuilder(
                future: Future.wait([
                  getDataUser(order.userUid),
                  getPacketMakeup(order.packetId),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
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
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (packetData.image.isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4.0),
                                  bottomLeft: Radius.circular(4.0),
                                ),
                                child: SizedBox(
                                  width: 120,
                                  child: Image.network(
                                    packetData.image,
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
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error_outline),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (userData.fullName.isNotEmpty)
                                      Text(
                                        userData.fullName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                    const SizedBox(height: 4),

                                    if (packetData.name.isNotEmpty)
                                      Text(
                                        packetData.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),

                                    const SizedBox(height: 4),

                                    Text(
                                      'Alamat: ${order.address}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    const SizedBox(height: 4),
                                    Text(
                                      'Status: ${order.status == "PENDING" ? "Menunggu Persetujuan" : order.status == "ACCEPT" ? "Disetujui" : order.status == "DENIED" ? "Ditolak" : order.status == 'FINISHED' ? "Selesai" : "Status Tidak Diketahui"}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    const SizedBox(height: 4),

                                    // Menggunakan tanggal yang sudah diformat
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$formattedDate - ${order.time}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      'Rp ${order.totalPrice}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<Map<String, dynamic>> getDataUser(String userUid) async {
    final snapshot = await users.doc(userUid).get();
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

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 1.7,
            ),
            itemCount: pemesanan.length,
            itemBuilder: (context, index) {
              final order = pemesanan[index].data() as Map<String, dynamic>;
              final userUid = order['UserUid'];
              final packetId = order['PacketId'];

              return FutureBuilder(
                future: Future.wait([
                  getDataUser(userUid),
                  getPacketMakeup(packetId),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userData = snapshot.data![0] as Map<String, dynamic>;
                  final packetData = snapshot.data![1] as Map<String, dynamic>;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Alamat : ${order['Address']}'),
                          Text('Tanggal Order : ${order['Date']}'),
                          Text('ID Paket : $packetId'),
                          Text('Waktu : ${order['Time']}'),
                          Text('Total Harga : ${order['TotalPrice']}'),
                          Text('User ID : $userUid'),
                          if (userData.isNotEmpty) ...[
                            Text('User Email : ${userData['email']}'),
                            Text('User FullName : ${userData['fullname']}'),
                          ],
                          if (packetData.isNotEmpty) ...[
                            Text('Nama Paket : ${packetData['Name']}'),
                          ],
                        ],
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

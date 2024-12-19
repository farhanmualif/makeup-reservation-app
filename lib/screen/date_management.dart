import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class DateManagement extends StatefulWidget {
  const DateManagement({super.key});

  @override
  State<DateManagement> createState() => _DateManagementState();
}

class _DateManagementState extends State<DateManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? _selectedDate;

  // Variabel dalam bahasa Inggris
  final TextEditingController _informationController = TextEditingController();

  // Tambahkan RefreshController
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  Set<DateTime> _blockedDates = {};

  @override
  void initState() {
    super.initState();
    _loadBlockedDates();
  }

  Future<void> _loadBlockedDates() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('day_off').get();

      setState(() {
        _blockedDates = snapshot.docs.map((doc) {
          final dateString = doc['Date'] as String;
          return DateTime.parse(dateString);
        }).toSet();
      });
    } catch (e) {
      print('Error loading blocked dates: $e');
    }
  }

  // Tambahkan fungsi onRefresh
  void _onRefresh() async {
    await _loadBlockedDates();
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() {});
    _refreshController.refreshCompleted();
  }

  Future<void> _showAddHolidayModal() {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tambah Hari Libur',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(DateTime.now().year + 2),
                          selectableDayPredicate: (DateTime date) {
                            final dateWithoutTime =
                                DateTime(date.year, date.month, date.day);
                            return !_blockedDates.contains(dateWithoutTime);
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate == null
                                  ? 'Pilih Tanggal'
                                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                              style: TextStyle(
                                color: _selectedDate == null
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _informationController,
                      decoration: InputDecoration(
                        hintText: 'Keterangan (Opsional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          if (_selectedDate != null) {
                            try {
                              String formattedDate =
                                  "${_selectedDate!.toIso8601String().split('T')[0]}T00:00:00.000";

                              await _firestore.collection('day_off').add({
                                'Date': formattedDate,
                                'Information': _informationController.text,
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                              if (!mounted) return;

                              // Simpan teks keterangan sebelum clear
                              final information = _informationController.text;

                              // Clear controller dan selected date
                              _informationController.clear();
                              setState(() {
                                _selectedDate = null;
                              });

                              // Tutup modal
                              Navigator.pop(context);

                              // Tampilkan snackbar setelah modal tertutup
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Hari libur berhasil ditambahkan'),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              // Refresh data
                              await _loadBlockedDates();
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gagal menambahkan hari libur'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Silakan pilih tanggal terlebih dahulu'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteDate(String docId) async {
    await _firestore.collection('day_off').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Kelola Hari Libur'),
        backgroundColor: Colors.grey[300],
        elevation: 0.5,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: _showAddHolidayModal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SmartRefresher(
        enablePullDown: true,
        header: const WaterDropHeader(),
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('day_off')
              .orderBy('Date', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final documents = snapshot.data!.docs;

            if (documents.isEmpty) {
              return const Center(
                child: Text(
                  'Data belum tersedia',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                final dateString = doc['Date'] as String;
                final tanggal = DateTime.parse(dateString);

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      '${tanggal.day}/${tanggal.month}/${tanggal.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: doc['Information'] != null &&
                            doc['Information'].toString().isNotEmpty
                        ? Text(doc['Information'])
                        : const Text(
                            'Tidak ada keterangan',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteDate(doc.id),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _informationController.dispose();
    _refreshController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TrackingPengeluaranPage extends StatefulWidget {
  const TrackingPengeluaranPage({Key? key}) : super(key: key);

  @override
  State<TrackingPengeluaranPage> createState() =>
      _TrackingPengeluaranPageState();
}

class _TrackingPengeluaranPageState extends State<TrackingPengeluaranPage> {
  final user = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot> getPengeluaranStream() {
    if (user == null) {
      throw Exception('User belum login');
    }

    return FirebaseFirestore.instance
        .collection('pengeluaran')
        .where('uid', isEqualTo: user!.uid)
        //.orderBy('timestamp', descending: true)
        .snapshots();
  }

  double getTotalPengeluaran(QuerySnapshot snapshot) {
    return snapshot.docs.fold(0.0, (total, doc) {
      final data = doc.data() as Map<String, dynamic>;
      return total + (data['jumlah'] ?? 0).toDouble();
    });
  }

  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Color getKategoriColor(String kategori) {
    final colors = {
      'Makanan': Colors.redAccent,
      'Transportasi': Colors.blueAccent,
      'Hiburan': Colors.purpleAccent,
      'Belanja': Colors.teal,
      'Lainnya': Colors.grey,
    };
    return colors[kategori] ?? Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: const Text('Tracking Pengeluaran'),
        elevation: 4,
        shadowColor: Colors.deepOrange.shade200,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getPengeluaranStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final pengeluaranList = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Pengeluaran
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.deepOrange.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bar_chart,
                          size: 32,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Total Pengeluaran Bulan Ini",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatCurrency(
                                getTotalPengeluaran(snapshot.data!),
                              ),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  "Riwayat Pengeluaran",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // List Pengeluaran
                Expanded(
                  child: pengeluaranList.isEmpty
                      ? const Center(child: Text('Belum ada data pengeluaran'))
                      : ListView.builder(
                          itemCount: pengeluaranList.length,
                          itemBuilder: (context, index) {
                            final data =
                                pengeluaranList[index].data()
                                    as Map<String, dynamic>;

                            final jumlah = (data['jumlah'] ?? 0).toDouble();
                            final kategori = data['kategori'] ?? 'Lainnya';
                            final catatan = data['keterangan'] ?? '-';
                            final tanggal = (data['timestamp'] as Timestamp?)
                                ?.toDate();

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: getKategoriColor(kategori),
                                  child: const Icon(
                                    Icons.money,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  kategori,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(catatan),
                                    const SizedBox(height: 4),
                                    if (tanggal != null)
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy',
                                        ).format(tanggal),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Text(
                                  formatCurrency(jumlah),
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

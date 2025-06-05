import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import 'login_page.dart';
import 'profile_page.dart';
import 'tambah_pemasukan_page.dart';
import 'catat_pengeluaran_page.dart';
import 'tracking_pengeluaran_page.dart';
import 'kelola_kategori_page.dart';
//import 'rencana_pengeluaran_page.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final auth = FirebaseAuth.instance;
  int _selectedIndex = 0;

  num totalPemasukan = 0;
  num totalPengeluaran = 0;

  @override
  void initState() {
    super.initState();
    fetchSummary();
  }

  Future<void> fetchSummary() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final awalBulan = DateTime(now.year, now.month, 1);

    try {
      final pemasukanSnapshot = await FirebaseFirestore.instance
          .collection('pemasukan')
          .where('uid', isEqualTo: uid)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(awalBulan),
          )
          .get();

      final pengeluaranSnapshot = await FirebaseFirestore.instance
          .collection('pengeluaran')
          .where('uid', isEqualTo: uid)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(awalBulan),
          )
          .get();

      num pemasukan = 0;
      for (var doc in pemasukanSnapshot.docs) {
        final jumlah = doc.data()['jumlah'];
        if (jumlah is num) pemasukan += jumlah;
      }

      num pengeluaran = 0;
      for (var doc in pengeluaranSnapshot.docs) {
        final jumlah = doc.data()['jumlah'];
        if (jumlah is num) pengeluaran += jumlah;
      }

      setState(() {
        totalPemasukan = pemasukan;
        totalPengeluaran = pengeluaran;
      });
    } catch (e) {
      print("Gagal mengambil ringkasan: $e");
    }
  }

  num get sisaSaldo => totalPemasukan - totalPengeluaran;
  num get selisih => (totalPemasukan - totalPengeluaran).abs();

  List<Widget> _widgetOptions() => [
    _buildDashboard(),
    TambahPemasukanPage(),
    CatatPengeluaranPage(),
    TrackingPengeluaranPage(),
    ManageCategoryPage(),
    ProfilePage(),
  ];

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: fetchSummary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Bulan Ini',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  'Pemasukan',
                  'Rp ${totalPemasukan.toStringAsFixed(0)}',
                  Colors.green,
                ),
                _buildStatCard(
                  'Pengeluaran',
                  'Rp ${totalPengeluaran.toStringAsFixed(0)}',
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPieChart(),
            const SizedBox(height: 20),
            _buildBalanceCard(),
            const SizedBox(height: 30),
            const Text(
              'Menu Cepat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth < 400 ? 3 : 4;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                  children: [
                    _buildMenuButton(Icons.add_circle, 'Tambah Uang', 1),
                    _buildMenuButton(
                      Icons.remove_circle,
                      'Catat Pengeluaran',
                      2,
                    ),
                    _buildMenuButton(Icons.analytics, 'Tracking', 3),
                    _buildMenuButton(Icons.category, 'Kategori', 4),
                    _buildMenuButton(Icons.list_alt, 'Rencana', 5),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    if (totalPemasukan + totalPengeluaran == 0) {
      return const Text('Belum ada data untuk ditampilkan pada pie chart.');
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  color: Colors.green,
                  value: totalPemasukan.toDouble(),
                  title: 'Pemasukan',
                  radius: 60,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.red,
                  value: totalPengeluaran.toDouble(),
                  title: 'Pengeluaran',
                  radius: 60,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      child: Card(
        color: Colors.orange[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Sisa Saldo Bulan Ini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rp ${sisaSaldo.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selisih Pemasukan & Pengeluaran: Rp ${selisih.toStringAsFixed(0)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 150,
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 16, color: color)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(IconData icon, String label, int index) {
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.orange[100],
            child: Icon(icon, color: Colors.orange[800], size: 28),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('Kelola Uang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: _widgetOptions()[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Pemasukan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money_off),
            label: 'Pengeluaran',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Tracking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Kategori',
          ),
          //BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Rencana'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  void logout(BuildContext context) async {
    await auth.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }
}

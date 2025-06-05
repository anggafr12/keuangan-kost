import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TambahPemasukanPage extends StatefulWidget {
  const TambahPemasukanPage({super.key});

  @override
  State<TambahPemasukanPage> createState() => _TambahPemasukanPageState();
}

class _TambahPemasukanPageState extends State<TambahPemasukanPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _simpanPemasukan() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("User belum login");

        final doc = {
          'uid': user.uid,
          'jumlah': int.parse(_jumlahController.text),
          'keterangan': _keteranganController.text,
          'timestamp': Timestamp.fromDate(_selectedDate),
          'created_at': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance.collection('pemasukan').add(doc);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pemasukan berhasil disimpan')),
          );
          _jumlahController.clear();
          _keteranganController.clear();
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    Stream<QuerySnapshot>? pemasukanStream;
    if (user != null) {
      pemasukanStream = FirebaseFirestore.instance
          .collection('pemasukan')
          .where('uid', isEqualTo: user.uid)
          //.orderBy('timestamp', descending: true)
          .snapshots();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Pemasukan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _jumlahController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Pemasukan',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _keteranganController,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan (opsional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tanggal: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _selectDate(context),
                        child: const Text('Pilih Tanggal'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _simpanPemasukan,
                    icon: const Icon(Icons.save),
                    label: Text(_isLoading ? 'Menyimpan...' : 'Simpan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Riwayat Pemasukan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (pemasukanStream == null)
              const Text("Silakan login untuk melihat data."),
            if (pemasukanStream != null)
              StreamBuilder<QuerySnapshot>(
                stream: pemasukanStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text("Terjadi kesalahan: ${snapshot.error}");
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text("Belum ada pemasukan.");
                  }

                  final pemasukanList = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: pemasukanList.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final data =
                          pemasukanList[index].data() as Map<String, dynamic>;
                      final jumlah = data['jumlah'] ?? 0;
                      final keterangan = data['keterangan'] ?? '';
                      final tanggal = (data['timestamp'] as Timestamp).toDate();

                      return Card(
                        child: ListTile(
                          title: Text("Rp ${jumlah.toString()}"),
                          subtitle: Text(keterangan),
                          trailing: Text(
                            "${tanggal.day}/${tanggal.month}/${tanggal.year}",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

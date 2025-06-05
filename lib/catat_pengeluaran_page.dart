import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CatatPengeluaranPage extends StatefulWidget {
  const CatatPengeluaranPage({Key? key}) : super(key: key);

  @override
  State<CatatPengeluaranPage> createState() => _CatatPengeluaranPageState();
}

class _CatatPengeluaranPageState extends State<CatatPengeluaranPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  DateTime? _tanggal;
  String? _selectedKategori;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _kategoriList = [];

  @override
  void initState() {
    super.initState();
    _fetchKategori();
  }

  Future<void> _fetchKategori() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('uid', isEqualTo: uid)
          .get();

      final kategoriNames = snapshot.docs
          .map((doc) => doc['name'] as String)
          .toList();

      setState(() {
        _kategoriList = kategoriNames;
      });
    } catch (e) {
      setState(() {
        _kategoriList = [];
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat kategori: $e')));
    }
  }

  Future<void> _simpanPengeluaran() async {
    if (_formKey.currentState!.validate() &&
        _tanggal != null &&
        _selectedKategori != null) {
      final kategori = _selectedKategori!;
      final jumlah = double.tryParse(_jumlahController.text) ?? 0;
      final catatan = _catatanController.text;

      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      try {
        await _firestore.collection('pengeluaran').add({
          'uid': uid,
          'kategori': kategori,
          'jumlah': jumlah,
          'keterangan': catatan,
          'created_at': DateTime.now(),
          'timestamp': _tanggal,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pengeluaran berhasil dicatat")),
        );

        _formKey.currentState!.reset();
        _jumlahController.clear(); // ✅ Ini baris untuk mengosongkan nominal
        _catatanController.clear();
        setState(() {
          _tanggal = null;
          _selectedKategori = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan pengeluaran: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon lengkapi semua data")),
      );
    }
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text("Catat Pengeluaran"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                items: _kategoriList
                    .map(
                      (kategori) => DropdownMenuItem(
                        value: kategori,
                        child: Text(kategori),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedKategori = val),
                decoration: InputDecoration(
                  labelText: "Kategori Pengeluaran",
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Wajib dipilih" : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _jumlahController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Jumlah (Rp)",
                  prefixIcon: const Icon(Icons.money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Wajib diisi" : null,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      _tanggal == null
                          ? "Tanggal: Belum dipilih"
                          : "Tanggal: ${DateFormat('dd MMM yyyy').format(_tanggal!)}",
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() => _tanggal = pickedDate);
                      }
                    },
                    child: const Text("Pilih Tanggal"),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _catatanController,
                decoration: InputDecoration(
                  labelText: "Catatan (opsional)",
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Simpan Pengeluaran"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _simpanPengeluaran,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

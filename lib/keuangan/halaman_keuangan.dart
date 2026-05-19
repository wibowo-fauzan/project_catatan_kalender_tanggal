import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ribuan_input_formatter.dart';
import 'detail_history_keuangan.dart';

class HalamanKeuangan extends StatefulWidget {
  const HalamanKeuangan({super.key});
  @override
  State<HalamanKeuangan> createState() => _HalamanKeuanganState();
}

class _HalamanKeuanganState extends State<HalamanKeuangan> {
  List<Map<String, dynamic>> _dataTarget = [];

  @override
  void initState() {
    super.initState();
    _loadKeuangan();
  }

  _loadKeuangan() async {
    final prefs = await SharedPreferences.getInstance();
    final res = prefs.getString('agenda_v7');
    if (res != null) {
      List<dynamic> decoded = json.decode(res);
      setState(() {
        _dataTarget = decoded.map((e) => Map<String, dynamic>.from(e)).where((item) => item['is_keuangan'] == true).toList();
      });
    }
  }

  _saveKeuangan() async {
    final prefs = await SharedPreferences.getInstance();
    final res = prefs.getString('agenda_v7');
    List<Map<String, dynamic>> dataTotal = [];
    if (res != null) {
      dataTotal = List<Map<String, dynamic>>.from(json.decode(res));
    }
    dataTotal.removeWhere((element) => element['is_keuangan'] == true);
    dataTotal.addAll(_dataTarget);
    await prefs.setString('agenda_v7', json.encode(dataTotal));
  }

  double _hitungPersentaseProgress(String nominalStr, String? terkumpulStr) {
    // Hilangkan titik pemisah ribuan agar bisa dihitung secara matematis
    int nominal = int.tryParse(nominalStr.replaceAll('.', '').replaceAll(',', '')) ?? 1;
    int terkumpul = int.tryParse((terkumpulStr ?? "0").replaceAll('.', '').replaceAll(',', '')) ?? 0;
    if (nominal == 0) return 0.0;
    double progress = terkumpul / nominal;
    return progress.clamp(0.0, 1.0); // Mencegah progress melebihi 100% atau minus
  }

  String _hitungSimulasi(String tglTargetStr, String nominalStr, String? terkumpulStr) {
    try {
      DateTime tglTarget = DateFormat('dd MMM yyyy', 'id_ID').parse(tglTargetStr);
      DateTime hariIni = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      
      int sisaHari = tglTarget.difference(hariIni).inDays;
      if (sisaHari <= 0) sisaHari = 1;
      
      int nominal = int.tryParse(nominalStr.replaceAll('.', '').replaceAll(',', '')) ?? 0;
      int terkumpul = int.tryParse((terkumpulStr ?? "0").replaceAll('.', '').replaceAll(',', '')) ?? 0;
      
      int sisaTarget = nominal - terkumpul;
      if (sisaTarget <= 0) {
        return "Selamat! Target tabungan Anda sudah terpenuhi 🎉";
      }

      int tabunganPerHari = (sisaTarget / sisaHari).round();
      return "Sisa waktu $sisaHari Hari lagi. Kekurangan Rp ${NumberFormat('#,###', 'id_ID').format(sisaTarget)}. Anda perlu menabung ±Rp ${NumberFormat('#,###', 'id_ID').format(tabunganPerHari)} /hari.";
    } catch (e) {
      return "Gagal menghitung simulasi.";
    }
  }

  _tambahTargetDialog() {
    final judulController = TextEditingController();
    final nominalController = TextEditingController();
    DateTime tglTerpilih = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Buat Target Menabung", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: judulController, decoration: const InputDecoration(labelText: "Nama Target")),
                const SizedBox(height: 12),
                TextField(
                  controller: nominalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, RibuanInputFormatter()],
                  decoration: const InputDecoration(labelText: "Nominal Target (Rp)"),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Target Selesai:", style: TextStyle(fontWeight: FontWeight.w500)),
                    TextButton.icon(
                      onPressed: () async {
                        final d = await showDatePicker(context: context, initialDate: tglTerpilih, firstDate: DateTime.now(), lastDate: DateTime(2030), locale: const Locale('id', 'ID'));
                        if (d != null) setDialogState(() => tglTerpilih = d);
                      },
                      icon: const Icon(Icons.date_range_rounded, size: 18),
                      label: Text(DateFormat('dd MMM yyyy', 'id_ID').format(tglTerpilih)),
                    )
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                if (judulController.text.isNotEmpty && nominalController.text.isNotEmpty) {
                  setState(() {
                    _dataTarget.insert(0, {
                      'judul': judulController.text,
                      'nominal': nominalController.text, 
                      'terkumpul': "0", 
                      'tgl': DateFormat('dd MMM yyyy', 'id_ID').format(tglTerpilih),
                      'jam': "00:00",
                      'is_keuangan': true,
                      'history': []
                    });
                  });
                  await _saveKeuangan();
                  if (mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              child: const Text("Simpan Target"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _loadKeuangan(); // Memaksa tab tabungan sinkronisasi data secara otomatis tiap berganti tab

    return Scaffold(
      appBar: AppBar(
        title: const Text("Target Keuangan", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _dataTarget.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey.shade300), const SizedBox(height: 10), Text("Belum ada target menabung", style: TextStyle(color: Colors.grey.shade500))]))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _dataTarget.length,
              itemBuilder: (context, i) {
                final item = _dataTarget[i];
                double persenProgress = _hitungPersentaseProgress(item['nominal'], item['terkumpul']);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HalamanDetailHistoryKeuangan(
                              targetData: item,
                              onUpdate: (dataBaru) async {
                                setState(() {
                                  _dataTarget[i] = dataBaru;
                                });
                                await _saveKeuangan();
                              },
                            ),
                          ),
                        );
                        _loadKeuangan();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(item['judul'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1A1C24)))),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () async {
                                    setState(() => _dataTarget.removeAt(i));
                                    await _saveKeuangan();
                                  },
                                )
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text("Sudah Terkumpul", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  Text("Rp ${item['terkumpul'] ?? '0'}", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2E7D32), fontSize: 18)),
                                ]),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  const Text("Target Dana", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  Text("Rp ${item['nominal']}", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.blueGrey.shade700, fontSize: 14)),
                                ]),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: persenProgress,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey.shade100,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text("${(persenProgress * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)))
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text("Hingga Tanggal: ${item['tgl']}", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
                              child: Row(
                                children: [
                                  const Icon(Icons.wb_incandescent_outlined, size: 16, color: Colors.amber),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_hitungSimulasi(item['tgl'], item['nominal'], item['terkumpul']), style: const TextStyle(color: Color(0xFF5D4037), fontSize: 12, fontWeight: FontWeight.w500))),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_keuangan_unique',
        onPressed: _tambahTargetDialog,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_card_rounded),
        label: const Text("Target Baru"),
        elevation: 4,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'ribuan_input_formatter.dart';

class HalamanDetailHistoryKeuangan extends StatefulWidget {
  final Map<String, dynamic> targetData;
  final Function(Map<String, dynamic>) onUpdate;

  const HalamanDetailHistoryKeuangan({super.key, required this.targetData, required this.onUpdate});

  @override
  State<HalamanDetailHistoryKeuangan> createState() => _HalamanDetailHistoryKeuanganState();
}

class _HalamanDetailHistoryKeuanganState extends State<HalamanDetailHistoryKeuangan> {
  late Map<String, dynamic> _data;
  final _inputUangC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.targetData);
    if (_data['history'] == null) {
      _data['history'] = [];
    }
  }

  int _hitungSisaKekurangan() {
    int nominal = int.tryParse(_data['nominal'].toString().replaceAll('.', '')) ?? 0;
    int terkumpul = int.tryParse((_data['terkumpul'] ?? "0").toString().replaceAll('.', '')) ?? 0;
    int sisa = nominal - terkumpul;
    return sisa < 0 ? 0 : sisa;
  }

  void _prosesMutasiTabungan({required bool isTambah}) {
    int uangLama = int.parse((_data['terkumpul'] ?? "0").toString().replaceAll('.', ''));

    if (!isTambah && uangLama <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Saldo tabungan kosong! Tidak ada dana yang bisa diambil."),
          backgroundColor: Colors.redAccent,
        )
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          isTambah ? "Input Uang Tabungan" : "Ambil Uang Tabungan", 
          style: TextStyle(fontWeight: FontWeight.bold, color: isTambah ? const Color(0xFF2E7D32) : Colors.deepOrange)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTambah 
                ? "Masukkan jumlah uang untuk mengisi target tabungan ini:" 
                : "Masukkan nominal uang tabungan yang terpakai / ditarik:", 
              style: const TextStyle(fontSize: 13, color: Colors.grey)
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _inputUangC,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                RibuanInputFormatter()
              ],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: "Jumlah Uang (Rp)",
                hintText: "Contoh: 50.000",
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: isTambah ? const Color(0xFF2E7D32) : Colors.deepOrange)
                )
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () { _inputUangC.clear(); Navigator.pop(context); }, child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (_inputUangC.text.isNotEmpty) {
                int uangInput = int.parse(_inputUangC.text.replaceAll('.', ''));
                
                if (!isTambah && uangInput > uangLama) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal! Penarikan (Rp ${_inputUangC.text}) melebihi total tabungan saat ini (Rp ${_data['terkumpul']})."),
                      backgroundColor: Colors.redAccent,
                    )
                  );
                  return;
                }

                int totalBaru = isTambah ? (uangLama + uangInput) : (uangLama - uangInput);
                if (totalBaru < 0) totalBaru = 0;

                int nominalTarget = int.tryParse(_data['nominal'].toString().replaceAll('.', '')) ?? 0;
                int sisaBaru = nominalTarget - totalBaru;
                if (sisaBaru < 0) sisaBaru = 0;

                String waktuSekarang = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

                setState(() {
                  _data['terkumpul'] = NumberFormat('#,###', 'id_ID').format(totalBaru);
                  
                  List historyList = List.from(_data['history']);
                  historyList.insert(0, {
                    'waktu': waktuSekarang,
                    'jumlah': _inputUangC.text,
                    'is_tambah': isTambah, 
                    'sisa_saat_itu': sisaBaru
                  });
                  _data['history'] = historyList;
                });

                widget.onUpdate(_data);
                _inputUangC.clear();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isTambah ? const Color(0xFF2E7D32) : Colors.deepOrange, 
              foregroundColor: Colors.white
            ),
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int sisaKekurangan = _hitungSisaKekurangan();
    List riwayatLog = _data['history'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(_data['judul'], style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Status Perkembangan Saldo", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Sasaran:"),
                    Text("Rp ${_data['nominal']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Sudah Terkumpul:", style: TextStyle(color: Color(0xFF2E7D32))),
                    Text("Rp ${_data['terkumpul']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Sisa Kekurangan:", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    Text("Rp ${NumberFormat('#,###', 'id_ID').format(sisaKekurangan)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 6),
                Text("Batas Akhir: ${_data['tgl']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Riwayat Pembayaran (History)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
                Text("${riwayatLog.length} Transaksi", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),

          Expanded(
            child: riwayatLog.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 50, color: Colors.grey.shade300),
                        const SizedBox(height: 6),
                        Text("Belum ada riwayat pembayaran / input.", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: riwayatLog.length,
                    itemBuilder: (context, idx) {
                      final log = riwayatLog[idx];
                      bool statusMasuk = log['is_tambah'] ?? true;

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusMasuk ? const Color(0xFF2E7D32).withOpacity(0.1) : Colors.red.withOpacity(0.1), 
                              shape: BoxShape.circle
                            ),
                            child: Icon(
                              statusMasuk ? Icons.add_chart_rounded : Icons.unarchive_rounded, 
                              color: statusMasuk ? const Color(0xFF2E7D32) : Colors.redAccent, 
                              size: 20
                            ),
                          ),
                          title: Text(
                            statusMasuk ? "+ Rp ${log['jumlah']}" : "- Rp ${log['jumlah']}", 
                            style: TextStyle(fontWeight: FontWeight.bold, color: statusMasuk ? const Color(0xFF2E7D32) : Colors.redAccent)
                          ),
                          subtitle: Text("Waktu: ${log['waktu']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("Sisa Target Saat Itu:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text("Rp ${NumberFormat('#,###', 'id_ID').format(log['sisa_saat_itu'] ?? 0)}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => _prosesMutasiTabungan(isTambah: false),
                        icon: const Icon(Icons.money_off_csred_rounded, color: Colors.deepOrange),
                        label: const Text("Ambil Dana", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.deepOrange)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.deepOrange, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _prosesMutasiTabungan(isTambah: true),
                        icon: const Icon(Icons.assignment_turned_in_rounded),
                        label: const Text("Menabung", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
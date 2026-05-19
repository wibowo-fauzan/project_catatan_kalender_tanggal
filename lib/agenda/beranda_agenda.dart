import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../fungsi_pesan.dart';
import 'halaman_editor.dart';

class BerandaAgenda extends StatefulWidget {
  const BerandaAgenda({super.key});
  @override
  State<BerandaAgenda> createState() => _BerandaAgendaState();
}

class _BerandaAgendaState extends State<BerandaAgenda> {
  List<Map<String, dynamic>> _data = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  _load() async {
    final prefs = await SharedPreferences.getInstance();
    final res = prefs.getString('agenda_v7');
    if (res != null) {
      List<dynamic> decoded = json.decode(res);
      setState(() => _data = decoded.map((e) => Map<String, dynamic>.from(e)).where((item) => item['is_keuangan'] != true).toList());
    }
  }

  _save() async {
    final prefs = await SharedPreferences.getInstance();
    final res = prefs.getString('agenda_v7');
    List<Map<String, dynamic>> dataTotal = [];
    if (res != null) {
      dataTotal = List<Map<String, dynamic>>.from(json.decode(res));
    }
    // Hapus data lama non-keuangan agar tidak duplikat
    dataTotal.removeWhere((element) => element['is_keuangan'] != true);
    dataTotal.addAll(_data);
    await prefs.setString('agenda_v7', json.encode(dataTotal));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Catatan", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _data.isEmpty 
        ? Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.note_add_outlined, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text("Belum ada agenda", style: TextStyle(color: Colors.grey.shade500)),
            ],
          )) 
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: _data.length,
            itemBuilder: (context, i) => _buildAnimatedCard(_data[i], i),
          ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_agenda_unique',
        onPressed: () => _keEditor(),
        backgroundColor: Colors.indigoAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Agenda Baru"),
        elevation: 4,
      ),
    );
  }

  Widget _buildAnimatedCard(Map<String, dynamic> item, int i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        title: Text(item['judul'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text("${item['tgl']} • ${item['jam']}", style: TextStyle(color: Colors.grey.shade600)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Colors.blueGrey, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: buatPesan(item)));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Disalin ke clipboard")));
              }
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.indigoAccent, size: 18),
              onPressed: () => Share.share(buatPesan(item))
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
              onPressed: () {
                setState(() => _data.removeAt(i));
                _save();
              }
            ),
          ],
        ),
        onTap: () => _keEditor(index: i),
      ),
    );
  }

  _keEditor({int? index}) async {
    final hasil = await Navigator.push(context, MaterialPageRoute(builder: (context) => HalamanEditor(dataAwal: index != null ? _data[index] : null)));
    if (hasil != null) {
      setState(() {
        if (index != null) _data[index] = hasil;
        else _data.insert(0, hasil);
      });
      await _save();
    }
  }
}
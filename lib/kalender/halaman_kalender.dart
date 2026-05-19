import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../fungsi_pesan.dart';

class HalamanKalender extends StatefulWidget {
  const HalamanKalender({super.key});
  @override
  State<HalamanKalender> createState() => _HalamanKalenderState();
}

class _HalamanKalenderState extends State<HalamanKalender> {
  Map<DateTime, List<dynamic>> _events = {};
  DateTime _foc = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  _load() async {
    final prefs = await SharedPreferences.getInstance();
    final res = prefs.getString('agenda_v7');
    if (res != null) {
      final List data = json.decode(res);
      Map<DateTime, List<dynamic>> temp = {};
      for (var item in data) {
        try {
          DateTime t = DateFormat('dd MMM yyyy', 'id_ID').parse(item['tgl']);
          DateTime key = DateTime(t.year, t.month, t.day);
          if (temp[key] == null) temp[key] = [];
          temp[key]!.add(item);
        } catch (e) {
          // Tangkap error parser tanggal jika ada format yang tidak sesuai
        }
      }
      setState(() => _events = temp);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Memaksa kalender membaca ulang data setiap kali render agar sinkron dengan tab lain
    _load(); 
    
    final tglKey = DateTime(_foc.year, _foc.month, _foc.day);
    final agendaHariIni = _events[tglKey] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Timeline Saya"), backgroundColor: Colors.white, elevation: 0),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
            child: TableCalendar(
              locale: 'id_ID',
              firstDay: DateTime(2024), lastDay: DateTime(2030), focusedDay: _foc,
              eventLoader: (day) => _events[DateTime(day.year, day.month, day.day)] ?? [],
              selectedDayPredicate: (day) => isSameDay(_foc, day),
              onDaySelected: (sel, foc) => setState(() => _foc = sel),
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(color: Colors.indigoAccent, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: Colors.indigoAccent.withOpacity(0.2), shape: BoxShape.circle),
                todayTextStyle: const TextStyle(color: Colors.indigoAccent),
                markerDecoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
              child: agendaHariIni.isEmpty 
              ? const Center(child: Text("Santai, tidak ada agenda hari ini."))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: agendaHariIni.length,
                  itemBuilder: (context, i) => InkWell(
                    onTap: () => _lihatDetail(agendaHariIni[i]),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade100), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          Container(
                            width: 4, 
                            height: 40, 
                            decoration: BoxDecoration(
                              color: agendaHariIni[i]['is_keuangan'] == true ? Colors.green : Colors.orangeAccent, 
                              borderRadius: BorderRadius.circular(10)
                            )
                          ),
                          const SizedBox(width: 15),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(agendaHariIni[i]['judul'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(
                              agendaHariIni[i]['is_keuangan'] == true 
                                  ? "Target Tabungan: Rp ${agendaHariIni[i]['nominal']}" 
                                  : agendaHariIni[i]['jam'], 
                              style: TextStyle(color: Colors.grey.shade500)
                            ),
                          ])),
                          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
            ),
          )
        ],
      ),
    );
  }

  void _lihatDetail(Map<String, dynamic> item) {
    bool isKeuangan = item['is_keuangan'] == true;
    String deskripsiTarget = "";
    
    if (isKeuangan) {
      try {
        DateTime tglTarget = DateFormat('dd MMM yyyy', 'id_ID').parse(item['tgl']);
        DateTime hariIni = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        int sisaHari = tglTarget.difference(hariIni).inDays;
        if(sisaHari <= 0) sisaHari = 1;
        
        int nominal = int.tryParse(item['nominal'].toString().replaceAll('.', '')) ?? 0;
        int terkumpul = int.tryParse((item['terkumpul'] ?? "0").toString().replaceAll('.', '')) ?? 0;
        int sisaTarget = nominal - terkumpul;
        if (sisaTarget < 0) sisaTarget = 0;

        int perHari = (sisaTarget / sisaHari).round();
        int perBulan = (sisaTarget / (sisaHari / 30 > 0 ? sisaHari / 30 : 1)).round();
        
        deskripsiTarget = "Detail Perkembangan Tabungan:\n"
            "💰 Total Target: Rp ${item['nominal']}\n"
            "💵 Sudah Masuk: Rp ${item['terkumpul'] ?? '0'}\n"
            "📉 Sisa Kekurangan: Rp ${NumberFormat('#,###', 'id_ID').format(sisaTarget)}\n\n"
            "Sisa waktu dalam $sisaHari hari lagi, minimal uang yang wajib disisihkan:\n"
            "💵 Rp ${NumberFormat('#,###', 'id_ID').format(perHari)} / hari\n"
            "📅 Rp ${NumberFormat('#,###', 'id_ID').format(perBulan)} / bulan";
      } catch (e) {
        deskripsiTarget = "Gagal memproses hitungan target keuangan.";
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 25),
            Text(item['judul'], style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isKeuangan ? Colors.green.shade700 : Colors.indigo)),
            const SizedBox(height: 10),
            Row(children: [
              Icon(isKeuangan ? Icons.flag_rounded : Icons.timer_outlined, size: 16, color: Colors.grey.shade50),
              const SizedBox(width: 5),
              Text(isKeuangan ? "Target Jatuh Tempo: ${item['tgl']}" : "${item['tgl']} | ${item['jam']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            ]),
            const Divider(height: 40),
            Expanded(child: SingleChildScrollView(
              child: isKeuangan 
                ? Text(deskripsiTarget, style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w500))
                : Text(quill.Document.fromJson(jsonDecode(item['konten'])).toPlainText(), style: const TextStyle(fontSize: 16, height: 1.5)),
            )),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Share.share(buatPesan(item)), 
                    icon: const Icon(Icons.share_rounded), 
                    label: const Text("Bagikan"), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isKeuangan ? Colors.green : Colors.indigoAccent, 
                      foregroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(vertical: 15), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    )
                  )
                ),
                const SizedBox(width: 10),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
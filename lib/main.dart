import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';

void main() {
  runApp(const AplikasiAgendaPro());
}

class AplikasiAgendaPro extends StatelessWidget {
  const AplikasiAgendaPro({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        fontFamily: 'Roboto',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        quill.FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      locale: const Locale('id', 'ID'),
      home: const NavigasiUtama(),
    );
  }
}

class NavigasiUtama extends StatefulWidget {
  const NavigasiUtama({super.key});
  @override
  State<NavigasiUtama> createState() => _NavigasiUtamaState();
}

class _NavigasiUtamaState extends State<NavigasiUtama> {
  int _indexSekarang = 0;
  
  Widget _dapatkanHalaman(int index) {
    switch (index) {
      case 0:
        return const BerandaAgenda();
      case 1:
        return const HalamanKalender();
      case 2:
        return const HalamanKeuangan();
      default:
        return const BerandaAgenda();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indexSekarang,
        children: [
          _dapatkanHalaman(0),
          _dapatkanHalaman(1),
          _dapatkanHalaman(2),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _indexSekarang,
          onTap: (i) => setState(() => _indexSekarang = i),
          selectedItemColor: Colors.indigoAccent,
          unselectedItemColor: Colors.grey.shade400,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_mosaic_rounded), label: "Agenda"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: "Kalender"),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: "Keuangan"),
          ],
        ),
      ),
    );
  }
}

String buatPesan(Map<String, dynamic> item) {
  if (item['is_keuangan'] == true) {
    int nominal = int.tryParse(item['nominal'].toString().replaceAll('.', '')) ?? 0;
    int terkumpul = int.tryParse((item['terkumpul'] ?? "0").toString().replaceAll('.', '')) ?? 0;
    int sisa = nominal - terkumpul;
    if (sisa < 0) sisa = 0;
    
    return "📢 *TARGET KEUANGAN* 📢\n\n📌 *Target:* ${item['judul']}\n🗓️ Jatuh Tempo: ${item['tgl']}\n💰 Nominal Target: Rp ${item['nominal']}\n💵 Sudah Terkumpul: Rp ${item['terkumpul'] ?? '0'}\n📉 Sisa Kekurangan: Rp ${NumberFormat('#,###', 'id_ID').format(sisa)}\n\n💡 _Simulasi Otomatis Aplikasi_";
  }
  final doc = quill.Document.fromJson(jsonDecode(item['konten']));
  return "📢 *AGENDA* 📢\n\n📌 *${item['judul']}*\n🗓️ ${item['tgl']} | ⏰ ${item['jam']}\n\n📝 *Isi:* \n${doc.toPlainText().trim()}";
}

// --- HALAMAN 1: AGENDA ---
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
        surfaceTintColor: Colors.transparent,
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
        heroTag: 'fab_agenda_unique', // Memberikan tag unik agar tidak bentrok hero animation
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
        boxShadow: [
          BoxShadow(color: Colors.indigo.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            title: Text(item['judul'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3142))),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.indigo.shade300),
                  const SizedBox(width: 5),
                  Text("${item['tgl']} • ${item['jam']}", style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _actionBtn(Icons.copy_rounded, Colors.blueGrey, () {
                      Clipboard.setData(ClipboardData(text: buatPesan(item)));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Disalin ke clipboard")));
                    }),
                    _actionBtn(Icons.share_rounded, Colors.indigoAccent, () => Share.share(buatPesan(item))),
                    _actionBtn(Icons.delete_outline_rounded, Colors.redAccent, () {
                      setState(() => _data.removeAt(i));
                      _save();
                    }),
                  ],
                ),
              ],
            ),
            onTap: () => _keEditor(index: i),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback fn) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, size: 18, color: color), onPressed: fn),
    );
  }

  _keEditor({int? index}) async {
    final hasil = await Navigator.push(context, MaterialPageRoute(builder: (context) => HalamanEditor(dataAwal: index != null ? _data[index] : null)));
    if (hasil != null) {
      setState(() {
        if (index != null) _data[index] = hasil;
        else _data.insert(0, hasil);
      });
      _save();
    }
  }
}

// --- HALAMAN 2: KALENDER ---
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
        DateTime t = DateFormat('dd MMM yyyy', 'id_ID').parse(item['tgl']);
        DateTime key = DateTime(t.year, t.month, t.day);
        if (temp[key] == null) temp[key] = [];
        temp[key]!.add(item);
      }
      setState(() => _events = temp);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                todayDecoration: BoxDecoration(
                  color: Colors.indigoAccent.withOpacity(0.2), 
                  shape: BoxShape.circle, 
                ),
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
                              color: agendaHariIni[i]['is_keuangan'] == true ? Colors.greenAccent : Colors.orangeAccent, 
                              borderRadius: BorderRadius.circular(10)
                            )
                          ),
                          const SizedBox(width: 15),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              agendaHariIni[i]['judul'], 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis
                            ),
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
              Icon(isKeuangan ? Icons.flag_rounded : Icons.timer_outlined, size: 16, color: Colors.grey.shade500),
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
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded), style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// --- HALAMAN EDITOR ---
class HalamanEditor extends StatefulWidget {
  final Map<String, dynamic>? dataAwal;
  const HalamanEditor({super.key, this.dataAwal});
  @override
  State<HalamanEditor> createState() => _HalamanEditorState();
}

class _HalamanEditorState extends State<HalamanEditor> {
  late quill.QuillController _controller;
  final TextEditingController _judulC = TextEditingController();
  DateTime _tgl = DateTime.now();
  TimeOfDay _jam = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _judulC.text = widget.dataAwal != null ? widget.dataAwal!['judul'] : "";
    if (widget.dataAwal != null) {
      _tgl = DateFormat('dd MMM yyyy', 'id_ID').parse(widget.dataAwal!['tgl']);
      final j = widget.dataAwal!['jam'].split(':');
      _jam = TimeOfDay(hour: int.parse(j[0]), minute: int.parse(j[1]));
    }
    _controller = widget.dataAwal != null 
      ? quill.QuillController(document: quill.Document.fromJson(jsonDecode(widget.dataAwal!['konten'])), selection: const TextSelection.collapsed(offset: 0))
      : quill.QuillController.basic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Tulis Agenda", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: () {
                Navigator.pop(context, {
                  'judul': _judulC.text.isEmpty ? "Tanpa Judul" : _judulC.text,
                  'konten': jsonEncode(_controller.document.toDelta().toJson()),
                  'tgl': DateFormat('dd MMM yyyy', 'id_ID').format(_tgl),
                  'jam': "${_jam.hour.toString().padLeft(2,'0')}:${_jam.minute.toString().padLeft(2,'0')}",
                  'is_keuangan': false
                });
              }, 
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text("Simpan"),
              style: TextButton.styleFrom(foregroundColor: Colors.indigoAccent, backgroundColor: Colors.indigo.withOpacity(0.05)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          quill.QuillSimpleToolbar(controller: _controller, config: const quill.QuillSimpleToolbarConfig(multiRowsDisplay: false, showHeaderStyle: false, showAlignmentButtons: false)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), 
            child: TextField(
              controller: _judulC, 
              decoration: const InputDecoration(hintText: "Beri judul agenda...", border: InputBorder.none), 
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)
            )
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _chipPicker(DateFormat('dd MMM yyyy', 'id_ID').format(_tgl), Icons.calendar_month, () async {
                  final d = await showDatePicker(context: context, initialDate: _tgl, firstDate: DateTime(2024), lastDate: DateTime(2030));
                  if (d != null) setState(() => _tgl = d);
                }),
                const SizedBox(width: 10),
                _chipPicker(_jam.format(context), Icons.access_time, () async {
                  final t = await showTimePicker(context: context, initialTime: _jam);
                  if (t != null) setState(() => _jam = t);
                }),
              ],
            ),
          ),
          const Divider(height: 40),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: quill.QuillEditor.basic(controller: _controller, config: const quill.QuillEditorConfig(placeholder: "Mulai menulis detail agenda...")))),
        ],
      ),
    );
  }

  Widget _chipPicker(String label, IconData icon, VoidCallback fn) {
    return ActionChip(
      onPressed: fn,
      label: Text(label),
      avatar: Icon(icon, size: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.grey.shade50,
    );
  }
}

// --- HALAMAN 3: MANAJEMEN KEUANGAN ---
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
    int nominal = int.tryParse(nominalStr.replaceAll('.', '')) ?? 1;
    int terkumpul = int.tryParse((terkumpulStr ?? "0").replaceAll('.', '')) ?? 0;
    double progress = terkumpul / nominal;
    if (progress > 1.0) return 1.0;
    if (progress < 0.0) return 0.0;
    return progress;
  }

  String _hitungSimulasi(String tglTargetStr, String nominalStr, String? terkumpulStr) {
    try {
      DateTime tglTarget = DateFormat('dd MMM yyyy', 'id_ID').parse(tglTargetStr);
      DateTime hariIni = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      
      int sisaHari = tglTarget.difference(hariIni).inDays;
      if (sisaHari <= 0) sisaHari = 1;
      
      int nominal = int.tryParse(nominalStr.replaceAll('.', '')) ?? 0;
      int terkumpul = int.tryParse((terkumpulStr ?? "0").toString().replaceAll('.', '')) ?? 0;
      
      int sisaTarget = nominal - terkumpul;
      if (sisaTarget < 0) sisaTarget = 0;

      int tabunganPerHari = (sisaTarget / sisaHari).round();
      
      if(sisaTarget == 0) {
        return "Selamat! Target tabungan Anda sudah terpenuhi 🎉";
      }
      
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
                TextField(
                  controller: judulController,
                  decoration: const InputDecoration(labelText: "Nama Target (Contoh: Beli Laptop)", hintText: "Masukkan tujuan menabung"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nominalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    RibuanInputFormatter()
                  ],
                  decoration: const InputDecoration(labelText: "Nominal Target (Rp)", hintText: "Contoh: 5.000.000"),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Target Selesai:", style: TextStyle(fontWeight: FontWeight.w500)),
                    TextButton.icon(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context, 
                          initialDate: tglTerpilih, 
                          firstDate: DateTime.now(), 
                          lastDate: DateTime(2030),
                          locale: const Locale('id', 'ID')
                        );
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
              onPressed: () {
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
                  _saveKeuangan();
                  Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Target Keuangan", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _dataTarget.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text("Belum ada target menabung", style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _dataTarget.length,
              itemBuilder: (context, i) {
                final item = _dataTarget[i];
                double persenProgress = _hitungPersentaseProgress(item['nominal'], item['terkumpul']);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04), 
                        blurRadius: 16, 
                        offset: const Offset(0, 6)
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HalamanDetailHistoryKeuangan(
                              targetData: item,
                              onUpdate: (dataBaru) {
                                setState(() {
                                  _dataTarget[i] = dataBaru;
                                });
                                _saveKeuangan();
                              },
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['judul'], 
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1A1C24), letterSpacing: -0.3)
                                  )
                                ),
                                Container(
                                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), shape: BoxShape.circle),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      setState(() => _dataTarget.removeAt(i));
                                      _saveKeuangan();
                                    },
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 14),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Sudah Terkumpul", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 2),
                                    Text("Rp ${item['terkumpul'] ?? '0'}", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2E7D32), fontSize: 18)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text("Target Dana", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 2),
                                    Text("Rp ${item['nominal']}", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.blueGrey.shade700, fontSize: 14)),
                                  ],
                                ),
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
                                Text(
                                  "${(persenProgress * 100).toStringAsFixed(0)}%", 
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))
                                )
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text("Hingga Tanggal: ${item['tgl']}", style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w400)),
                            
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.amber.withOpacity(0.2), width: 1)
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2.0),
                                    child: Icon(Icons.wb_incandescent_outlined, size: 16, color: Colors.amber),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _hitungSimulasi(item['tgl'], item['nominal'], item['terkumpul']),
                                      style: const TextStyle(color: Color(0xFF5D4037), fontSize: 12, fontWeight: FontWeight.w500, height: 1.4),
                                    ),
                                  ),
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
        heroTag: 'fab_keuangan_unique', // Memberikan tag unik agar tidak bentrok hero animation
        onPressed: _tambahTargetDialog,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_card_rounded),
        label: const Text("Target Baru", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
    );
  }
}

// --- HALAMAN DETAIL, HISTORY LOG & INPUT DANA / TARIK DANA ---
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

class RibuanInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    int value = int.parse(newValue.text.replaceAll('.', ''));
    final formatter = NumberFormat('#,###', 'id_ID');
    String newText = formatter.format(value);
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
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
        fontFamily: 'Roboto', // Pastikan font terbaca bersih
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indexSekarang,
        children: [
          BerandaAgenda(key: UniqueKey()), 
          HalamanKalender(key: UniqueKey()),
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
          showUnselectedLabels: false,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_mosaic_rounded), label: "Agenda"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: "Kalender"),
          ],
        ),
      ),
    );
  }
}

String buatPesan(Map<String, dynamic> item) {
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
    if (res != null) setState(() => _data = List<Map<String, dynamic>>.from(json.decode(res)));
  }

  _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('agenda_v7', json.encode(_data));
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
        DateTime t = DateFormat('dd MMM yyyy').parse(item['tgl']);
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
                    // Baris textAlign sudah dibuang
                  ),                todayTextStyle: const TextStyle(color: Colors.indigoAccent),
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
                          Container(width: 4, height: 40, decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(10))),
                          const SizedBox(width: 15),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(agendaHariIni[i]['judul'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(agendaHariIni[i]['jam'], style: TextStyle(color: Colors.grey.shade500)),
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
            Text(item['judul'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.timer_outlined, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 5),
              Text("${item['tgl']} | ${item['jam']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            ]),
            const Divider(height: 40),
            Expanded(child: SingleChildScrollView(
              child: Text(quill.Document.fromJson(jsonDecode(item['konten'])).toPlainText(), style: const TextStyle(fontSize: 16, height: 1.5)),
            )),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: ElevatedButton.icon(onPressed: () => Share.share(buatPesan(item)), icon: const Icon(Icons.share_rounded), label: const Text("Bagikan"), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))))),
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
      _tgl = DateFormat('dd MMM yyyy').parse(widget.dataAwal!['tgl']);
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
                  'tgl': DateFormat('dd MMM yyyy').format(_tgl),
                  'jam': "${_jam.hour.toString().padLeft(2,'0')}:${_jam.minute.toString().padLeft(2,'0')}",
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
                _chipPicker(DateFormat('dd MMM yyyy').format(_tgl), Icons.calendar_month, () async {
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
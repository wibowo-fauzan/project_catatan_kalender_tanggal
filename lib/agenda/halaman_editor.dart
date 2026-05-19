import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:intl/intl.dart';

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
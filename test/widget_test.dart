import 'package:flutter/material.dart';

void main() {
  runApp(const NoteApp());
}

class NoteApp extends StatelessWidget {
  const NoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      home: const FunctionalNotePage(),
    );
  }
}

class FunctionalNotePage extends StatefulWidget {
  const FunctionalNotePage({super.key});

  @override
  State<FunctionalNotePage> createState() => _FunctionalNotePageState();
}

class _FunctionalNotePageState extends State<FunctionalNotePage> {
  // Data dummy yang bisa dimanipulasi (Simpan/Tambah/Hapus)
  final List<Map<String, dynamic>> _myAgenda = [
    {'time': '08:00', 'title': 'Daily Standup', 'desc': 'Diskusi tim dev', 'color': Colors.blue},
    {'time': '10:00', 'title': 'Coding Flutter', 'desc': 'Selesaikan fitur UI', 'color': Colors.indigo},
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // Fungsi menambah agenda
  void _addAgenda() {
    if (_titleController.text.isNotEmpty) {
      setState(() {
        _myAgenda.add({
          'time': '${DateTime.now().hour}:${DateTime.now().minute}',
          'title': _titleController.text,
          'desc': _descController.text,
          'color': Colors.orange,
        });
      });
      _titleController.clear();
      _descController.clear();
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Catatan berhasil disimpan!")),
      );
    }
  }

  // Tampilan Dialog Input
  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Buat Agenda Baru", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Judul Agenda", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: "Keterangan", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: _addAgenda,
              child: const Text("Simpan Sekarang"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Workspace", style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.person, color: Colors.white, size: 20)),
          const SizedBox(width: 15),
        ],
      ),
      body: Row(
        children: [
          // Sidebar untuk layar lebar (Desktop/Tablet)
          if (isWide)
            NavigationRail(
              selectedIndex: 0,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
                NavigationRailDestination(icon: Icon(Icons.calendar_month_outlined), label: Text('Jadwal')),
                NavigationRailDestination(icon: Icon(Icons.settings_outlined), label: Text('Setting')),
              ],
              onDestinationSelected: (int index) {},
            ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 25),
                const Text("Kategori", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildCategoryChips(),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Agenda Anda", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("${_myAgenda.length} Total", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 15),
                
                // Daftar Agenda Dinamis
                _myAgenda.isEmpty 
                ? const Center(child: Text("Belum ada agenda."))
                : Column(
                    children: _myAgenda.map((item) {
                      return Dismissible(
                        key: UniqueKey(),
                        onDismissed: (direction) {
                          setState(() => _myAgenda.remove(item));
                        },
                        background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                        child: _buildAgendaCard(item),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.edit),
        label: const Text("Tulis Agenda"),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo, Colors.indigo.shade400]),
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Produktivitas Hari Ini", style: TextStyle(color: Colors.white70, fontSize: 14)),
          SizedBox(height: 5),
          Text("85% Selesai", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          LinearProgressIndicator(value: 0.85, backgroundColor: Colors.white24, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    List<String> cats = ["Semua", "Pekerjaan", "Belanja", "Ide", "Kesehatan"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cats.map((c) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(c),
            onPressed: () {}, // Fungsi filter bisa ditaruh di sini
            backgroundColor: c == "Semua" ? Colors.indigo.shade50 : Colors.white,
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildAgendaCard(Map<String, dynamic> data) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: data['color'].withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.calendar_today, color: data['color'], size: 20),
        ),
        title: Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(data['desc']),
        trailing: Text(data['time'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }
}
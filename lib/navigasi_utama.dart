import 'package:flutter/material.dart';
import 'agenda/beranda_agenda.dart';
import 'kalender/halaman_kalender.dart';
import 'keuangan/halaman_keuangan.dart';

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
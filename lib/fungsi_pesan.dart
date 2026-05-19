import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

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
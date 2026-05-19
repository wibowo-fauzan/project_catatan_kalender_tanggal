# Jadwal & manajemen Keuangan

Aplikasi Flutter untuk membantu pengguna dalam mengatur aktivitas sehari-hari, mulai dari pencatatan agenda, pengelolaan jadwal, hingga pencatatan keuangan pribadi dalam satu aplikasi yang praktis dan mudah digunakan.

## Fitur Utama

- 📅 Manajemen jadwal dan agenda harian
- 📝 Catatan aktivitas dan to-do list
- 💰 Pencatatan pemasukan dan pengeluaran
- 🔔 Pengingat kegiatan penting
- 📊 Ringkasan aktivitas dan keuangan
- 🎨 Tampilan sederhana dan user-friendly

## Tujuan Aplikasi

Aplikasi ini dibuat untuk membantu pengguna agar lebih terorganisir dalam mengatur waktu, aktivitas, dan keuangan sehari-hari. Dengan adanya fitur agenda dan pencatatan keuangan, pengguna dapat memantau kegiatan serta kondisi finansial dengan lebih mudah.

## Teknologi yang Digunakan

Project ini dibuat menggunakan:

- Flutter
- Dart
- Material Design

## Struktur Fitur

Berikut beberapa halaman utama dalam aplikasi:

- Home Dashboard
- Jadwal & Agenda
- Catatan Harian
- Keuangan
- Profil Pengguna

## Getting Started

Project ini merupakan aplikasi Flutter dasar yang dapat dikembangkan lebih lanjut.

Beberapa resource Flutter yang dapat dipelajari:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter Documentation](https://docs.flutter.dev/)

## cara release apk nya
cara install apk nya dengan perintah berikut : flutter build apk --release

## Cara Menjalankan Project

1. Install Flutter SDK
2. Clone repository ini
3. Jalankan perintah berikut:

```bash
flutter pub get
flutter run

file di dalam folder lib/. Struktur foldernya akan dibuat rapi seperti ini:

lib/
│
├── main.dart
├── navigasi_utama.dart
├── fungsi_pesan.dart
│
├── agenda/
│   ├── beranda_agenda.dart
│   └── halaman_editor.dart
│
├── kalender/
│   └── halaman_kalender.dart
│
└── keuangan/
    ├── halaman_keuangan.dart
    ├── detail_history_keuangan.dart
    └── ribuan_input_formatter.dart
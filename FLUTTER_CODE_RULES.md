# Flutter Code Organization & File Size Rules

## 1. Single Responsibility Principle

- Setiap file Dart harus memiliki satu tanggung jawab utama yang jelas.
- Hindari menumpuk seluruh halaman, komponen UI, state management, API request, validasi, dan business logic dalam satu file.
- Pisahkan kode berdasarkan feature, tanggung jawab, dan layer arsitektur.
- Gunakan nama file yang spesifik, deskriptif, dan konsisten.
- Utamakan komposisi widget daripada membuat satu widget besar yang menangani seluruh tampilan.
- Jangan memecah kode menjadi banyak file kecil tanpa alasan arsitektural yang jelas.
- Satu file sebaiknya memiliki satu tipe utama yang diekspos secara publik. Widget helper privat yang erat kaitannya boleh tetap berada dalam file yang sama.

## 2. Maximum Dart File Length

Gunakan batas berikut sebagai kebijakan internal proyek:

- Target ideal: 100–250 baris kode bermakna per file Dart.
- Batas normal: maksimal 300 baris kode bermakna.
- File di atas 300 baris wajib dievaluasi untuk kemungkinan pemisahan.
- File di atas 500 baris wajib ditinjau dan direfaktor jika terdapat tanggung jawab yang dapat dipisahkan secara logis.
- Jangan memecah file hanya untuk memenuhi batas baris jika pemisahan mengurangi keterbacaan atau meningkatkan kompleksitas.
- Batas ini berlaku sebagai pedoman untuk source code yang ditulis developer, bukan sebagai aturan mutlak untuk seluruh file dalam proyek.

Pengecualian yang diperbolehkan:
- Generated code, seperti file `.g.dart` dan `.freezed.dart`.
- Kode hasil generator localization.
- File konfigurasi, deklarasi tipe, atau data statis yang memang wajar berukuran besar.
- Kode integrasi platform atau kode yang mengikuti persyaratan framework.
- File lainnya dengan alasan teknis yang jelas dan terdokumentasi.

Jangan memasukkan generated code ke dalam file source manual hanya untuk menghindari pemeriksaan ukuran file.

## 3. Function, Method, and Class Size

- Fungsi atau method idealnya maksimal 30–50 baris.
- Fungsi di atas 50 baris wajib dievaluasi apakah memiliki beberapa tanggung jawab.
- Hindari fungsi dengan terlalu banyak percabangan, nested conditions, atau nested callbacks.
- Pisahkan validasi, transformasi data, pemrosesan bisnis, dan error handling jika kompleksitasnya meningkat.
- Satu class harus memiliki tanggung jawab yang jelas dan kohesif.
- Hindari ViewModel, Controller, Service, atau Repository raksasa yang menangani banyak feature sekaligus.
- Gunakan helper method untuk proses yang mempunyai tujuan logis tersendiri.
- Jangan membuat helper method untuk operasi sederhana yang justru menjadi lebih sulit dipahami setelah dipisahkan.

## 4. Flutter Widget and UI Separation

- Jangan menumpuk seluruh tampilan halaman dalam satu widget dengan method `build()` yang sangat panjang.
- Method `build()` idealnya ringkas dan berfokus pada komposisi UI.
- Jika `build()` melebihi sekitar 80–100 baris, evaluasi apakah beberapa bagian memiliki tanggung jawab UI yang dapat dipisahkan.
- Pisahkan bagian UI yang kompleks, dapat digunakan kembali, memiliki state sendiri, atau perlu diuji secara terpisah.
- Letakkan widget yang hanya digunakan satu kali dalam file yang sama jika masih erat dengan parent widget dan pemisahannya tidak memberikan manfaat berarti.
- Pindahkan widget ke file tersendiri jika dapat digunakan kembali, memiliki tanggung jawab jelas, atau ukurannya membuat file parent sulit dibaca.
- Hindari membuat terlalu banyak widget hanya untuk membungkus satu atau dua widget sederhana tanpa nilai tambah.
- Gunakan `const` constructor dan widget jika memungkinkan.
- Hindari menjalankan operasi berat, API request, akses database, atau business logic dalam `build()`.
- Jangan melakukan side effect seperti request API berulang ketika widget dibangun ulang.
- Pisahkan layout, reusable components, dialog, form, tabel/list kompleks, dan bagian UI lain jika pemisahan meningkatkan keterbacaan.
- Perubahan tampilan tidak boleh memerlukan perubahan pada business logic yang tidak berkaitan jika hal tersebut dapat dihindari.

## 5. State Management and UI Logic

- Gunakan pendekatan state management yang sudah ditetapkan proyek, misalnya Riverpod, BLoC, Provider, atau pendekatan lain yang sudah digunakan.
- Jangan memperkenalkan state management kedua tanpa alasan teknis yang jelas dan persetujuan yang diperlukan.
- Pisahkan pengelolaan state dan business logic dari widget UI sesuai kompleksitas fitur.
- Widget bertugas menampilkan state, menerima input pengguna, dan meneruskan event ke pengelola state.
- Controller, ViewModel, Notifier, atau Bloc menangani logika yang berkaitan dengan state dan alur interaksi pengguna sesuai pola yang digunakan proyek.
- Jangan menempatkan seluruh logika aplikasi ke dalam `StatefulWidget`.
- Hindari menyimpan state yang sama di beberapa tempat tanpa alasan yang jelas.
- Hindari global mutable state yang dapat diakses dan diubah dari mana saja.
- Pisahkan local UI state yang sederhana dari application state yang digunakan oleh beberapa bagian aplikasi.
- Gunakan dependency injection sesuai pola proyek agar dependensi mudah diganti dan diuji.
- Jangan menambahkan abstraksi state management yang berlebihan untuk fitur sederhana.

## 6. Data Layer and Backend Communication

Pisahkan tanggung jawab data berdasarkan kebutuhan proyek.

### Service

- Menangani komunikasi dengan API, platform plugin, local storage, atau sumber data eksternal.
- Menangani detail teknis request dan response.
- Tidak bertanggung jawab atas keseluruhan alur UI atau navigasi.

### Repository

- Menjadi titik akses data bagi layer aplikasi yang menggunakannya.
- Menangani pengambilan data, penyimpanan, caching, retry, dan pemilihan sumber data jika diperlukan.
- Mengubah respons mentah menjadi model yang sesuai dengan kebutuhan aplikasi.
- Tidak mengetahui detail widget atau komponen UI.

### Model and DTO

- Memisahkan model data berdasarkan kebutuhan domain atau format API jika diperlukan.
- Gunakan tipe data yang jelas dan hindari penggunaan `dynamic` secara berlebihan.
- Validasi data eksternal sebelum menggunakannya sebagai data aplikasi.
- Hindari menggandakan model identik di beberapa folder tanpa kebutuhan yang jelas.

### Error Handling

- Tangani kegagalan API, timeout, parsing, dan penyimpanan pada layer yang sesuai.
- Jangan menyembunyikan exception dengan catch kosong.
- Tampilkan pesan yang sesuai melalui UI atau state management.
- Hindari menampilkan detail sensitif, token, password, atau stack trace internal kepada pengguna.

## 7. Recommended Project Structure

Gunakan pendekatan feature-first dengan pemisahan layer. Sesuaikan struktur dengan ukuran dan arsitektur aplikasi; jangan membuat folder kosong atau layer yang tidak dibutuhkan.

Contoh struktur:

    lib/
      app/
        app.dart
        router/
          app_router.dart
        theme/
          app_theme.dart

      core/
        config/
        constants/
        errors/
        network/
        storage/
        utils/
        widgets/

      features/
        auth/
          presentation/
            screens/
              login_screen.dart
            widgets/
              login_form.dart
            controllers/
              login_controller.dart
          data/
            models/
              login_request.dart
              user_dto.dart
            repositories/
              auth_repository.dart
            services/
              auth_api_service.dart
          domain/
            entities/
            use_cases/

        home/
          presentation/
            screens/
              home_screen.dart
            widgets/
            controllers/
          data/
            repositories/
            services/

      main.dart

    test/
      features/
        auth/
          presentation/
          data/

Ketentuan struktur:

- Letakkan kode yang berkaitan dengan feature di dalam folder feature tersebut.
- Gunakan folder `core/` untuk fungsi dan komponen lintas feature yang benar-benar digunakan bersama.
- Jangan menempatkan seluruh widget aplikasi ke satu folder global tanpa pengelompokan.
- Jangan membuat `domain/` atau `use_cases/` untuk setiap feature secara otomatis. Tambahkan layer tersebut jika ada kebutuhan bisnis yang cukup kompleks.
- Jangan membuat `utils.dart` atau `helpers.dart` sebagai tempat menampung semua fungsi.
- Gunakan struktur yang sudah ada jika proyek telah memiliki arsitektur konsisten, kecuali terdapat alasan kuat untuk mengubahnya.

## 8. Naming and Dart Style

- Gunakan `snake_case.dart` untuk nama file.
- Gunakan `UpperCamelCase` untuk class, enum, extension, dan nama tipe.
- Gunakan `lowerCamelCase` untuk variabel, method, dan parameter.
- Gunakan nama yang menjelaskan fungsi, misalnya `product_list_screen.dart`, `product_repository.dart`, dan `product_controller.dart`.
- Hindari nama generik seperti `data.dart`, `manager.dart`, `helper.dart`, atau `common.dart` ketika nama tersebut tidak menjelaskan tanggung jawab file.
- Ikuti formatter dan lint rules Dart yang telah ditetapkan proyek.
- Hindari duplikasi import dan dependency yang tidak digunakan.
- Jangan menggunakan prefix atau suffix nama secara tidak konsisten antar-feature.

## 9. Mandatory Refactoring Workflow

Sebelum menyelesaikan fitur baru atau refactoring:

1. Periksa struktur folder dan pola arsitektur yang telah digunakan proyek.
2. Periksa ukuran file, panjang method, ukuran `build()`, dan tanggung jawab widget.
3. Identifikasi logic yang seharusnya dipisahkan dari UI.
4. Pisahkan kode berdasarkan tanggung jawab yang jelas, bukan hanya berdasarkan jumlah baris.
5. Perbarui seluruh import, constructor, provider, dependency injection, dan referensi yang terdampak.
6. Pastikan routing, state management, lifecycle widget, dan asynchronous operations tetap benar.
7. Jalankan `dart format` pada kode yang diubah.
8. Jalankan `flutter analyze`.
9. Jalankan unit tests dan widget tests yang relevan.
10. Jalankan build yang relevan jika perubahan memengaruhi konfigurasi platform atau integrasi native.
11. Laporkan file yang dipecah, alasan pemisahan, risiko, dan hasil validasi.

Jangan menyelesaikan refactoring hanya berdasarkan perubahan visual kode tanpa memastikan alur data serta state tetap benar.

## 10. Restrictions

- Jangan menambahkan fitur baru saat permintaan hanya meminta refactoring.
- Jangan mengubah business logic, API contract, format data, atau perilaku aplikasi tanpa kebutuhan yang jelas.
- Jangan mengubah skema database atau format penyimpanan tanpa evaluasi kompatibilitas.
- Jangan membuat banyak file abstraksi hanya demi mengurangi baris per file.
- Jangan memindahkan seluruh fungsi ke satu `Utils` atau `Helpers` class.
- Jangan menempatkan API request dan business logic langsung di widget.
- Jangan mengubah framework state management yang sudah dipakai tanpa alasan teknis.
- Jangan menghapus kode yang belum dipahami.
- Jangan menonaktifkan lint rules hanya agar analisis terlihat berhasil.
- Jangan menandai pekerjaan selesai jika `flutter analyze`, build, atau test yang relevan gagal.
- Jika ada kegagalan yang sudah ada sebelum perubahan, dokumentasikan dengan jelas dan bedakan dari regresi baru.

## 11. Code Review Enforcement

Saat melakukan code review:

- Tandai file Dart yang melebihi 300 baris jika pemisahan secara logis memungkinkan.
- Tinjau file di atas 500 baris sebagai kandidat utama refactoring struktural.
- Tinjau `build()` yang terlalu panjang dan widget yang memiliki terlalu banyak tanggung jawab.
- Cari business logic yang berada di widget UI atau bercampur dengan akses data.
- Periksa duplikasi widget, state, validasi, dan request handling.
- Periksa penggunaan `BuildContext` setelah operasi asynchronous; pastikan lifecycle widget diperhatikan ketika melakukan navigasi atau pemanggilan UI.
- Periksa potensi memory leaks, pemanggilan API berulang, serta pengelolaan controller dan subscription.
- Berikan rekomendasi konkret: file sumber, tanggung jawab yang dipisahkan, nama file tujuan, dan alasan pemisahan.
- Bedakan bug fungsional, masalah keamanan, masalah performa, dan masalah maintainability.
- Jangan melaporkan jumlah baris sebagai bug dengan sendirinya.
- Jangan meminta refactoring besar yang tidak berkaitan dengan tujuan review tanpa alasan yang jelas.

## 12. Testing and Definition of Done

Implementasi dinyatakan selesai apabila:

- Setiap file mempunyai tanggung jawab yang jelas.
- Tidak ada file besar yang menggabungkan tanggung jawab tidak berkaitan tanpa alasan terdokumentasi.
- Widget berfokus pada UI dan interaksi, bukan keseluruhan business logic.
- State management dan data access mengikuti pola yang digunakan proyek.
- Tidak ada abstraksi berlebihan atau pemisahan file yang justru menurunkan keterbacaan.
- Semua import, navigasi, dependency injection, serta pengelolaan lifecycle tetap benar.
- Formatter sudah dijalankan.
- `flutter analyze` tidak menghasilkan error baru akibat perubahan.
- Unit tests, widget tests, dan tes relevan lainnya berhasil, atau kegagalan yang sudah ada didokumentasikan.
- Perubahan besar pada struktur arsitektur disertai pembaruan dokumentasi jika diperlukan.

## 13. Priority of Rules

Jika beberapa aturan bertentangan:

1. Correctness, keamanan, dan lifecycle aplikasi.
2. Arsitektur serta konvensi yang telah ditetapkan proyek.
3. Separation of concerns dan kemudahan pengujian.
4. Readability dan maintainability.
5. Target ukuran file.

Jangan mengorbankan correctness atau arsitektur hanya demi memenuhi jumlah baris tertentu.

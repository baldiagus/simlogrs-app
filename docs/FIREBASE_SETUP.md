# Panduan Setup Firebase Cloud Messaging (FCM)

Panduan ini ditujukan bagi developer mobile dan administrator backend untuk mengonfigurasi proyek Firebase Console, mengunduh file konfigurasi klien Android, serta menyiapkan kredensial Service Account untuk backend Laravel.

---

## 1. Konfigurasi Aplikasi di Firebase Console

1. Buka [Firebase Console](https://console.firebase.google.com/) dan login menggunakan akun Google pengembang organisasi.
2. Buat proyek baru atau pilih proyek yang sudah ada:
   - Nama Proyek: `simlogrs-app` (atau `simlogrs-mobile-dev` untuk lingkungan pengembangan).
   - Google Analytics dapat diaktifkan atau dinonaktifkan sesuai kebutuhan rumah sakit.
3. Tambahkan aplikasi Android ke dalam proyek:
   - Klik ikon **Android** pada halaman ringkasan proyek (*Project Overview*).
   - **Android package name (Nama paket):**
     ```text
     com.simlogrs.simlog_mobile
     ```
     *(Catatan: Nama paket wajib sesuai dengan `applicationId` di `android/app/build.gradle.kts` dan `AndroidManifest.xml`).*
   - **App nickname (opsional):** `SIMLOG RS Mobile`
   - **Debug signing certificate SHA-1 (opsional):** Masukkan SHA-1 debug keystore jika diperlukan untuk verifikasi keamanan.
   - Klik **Register app**.

---

## 2. Pengambilan dan Penempatan `google-services.json`

1. Setelah mendaftarkan aplikasi, unduh file `google-services.json`.
2. Letakkan file hasil unduhan tepat pada direktori aplikasi Android:
   ```text
   android/app/google-services.json
   ```
3. Pastikan struktur berkas sesuai:
   ```text
   simlogrs-app/
   └── android/
       └── app/
           ├── build.gradle.kts
           ├── google-services.json.example   <-- Template referensi
           └── google-services.json           <-- File kredensial asli (ter-ignore git)
   ```
4. **Keamanan:** File `google-services.json` berisi kredensial proyek lokal dan telah tercatat di `.gitignore`. Jangan pernah melakukan force-commit file tersebut ke repository publik. Gunakan `google-services.json.example` sebagai referensi struktur konfigurasi.

---

## 3. Mendapatkan Kredensial Service Account untuk Backend Laravel

Backend Laravel memerlukan Service Account JSON untuk mengirimkan notifikasi melalui Firebase HTTP v1 API secara aman.

### 3.1 Langkah Pengambilan Kunci Service Account
1. Pada Firebase Console, klik ikon roda gigi ⚙️ di samping **Project Overview** lalu pilih **Project settings** (*Setelan proyek*).
2. Pilih tab **Service accounts** (*Akun layanan*).
3. Pastikan pilihan runtime mengarah ke **Firebase Admin SDK**.
4. Klik tombol **Generate new private key** (*Buat kunci privat baru*), lalu konfirmasi dengan menekan **Generate key**.
5. Browser akan mengunduh file berekstensi `.json` (misalnya `simlogrs-app-firebase-adminsdk-xxxxx.json`).

### 3.2 Penempatan Kredensial di Backend Laravel
1. Simpan file kredensial JSON di folder aman backend Laravel yang tidak dapat diakses publik, misalnya:
   ```text
   storage/app/firebase/firebase_credentials.json
   ```
2. Tambahkan variabel lingkungan pada file `.env` Laravel:
   ```env
   FIREBASE_CREDENTIALS=storage/app/firebase/firebase_credentials.json
   FIREBASE_PROJECT_ID=simlogrs-mobile-dev
   ```
3. Pastikan path `storage/app/firebase/*.json` sudah masuk ke dalam `.gitignore` di repository backend Laravel.
4. Gunakan package resmi atau library terverifikasi seperti `kreait/laravel-firebase` untuk integrasi pengiriman push notification dari antrean/job Laravel.

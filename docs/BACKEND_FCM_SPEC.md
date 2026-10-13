# Spesifikasi Teknis Integrasi FCM (Backend Laravel)

Dokumen ini merupakan panduan implementasi teknis untuk tim backend Laravel dalam mengelola token perangkat (FCM Token) dan mengirimkan push notification ke aplikasi mobile SIMLOG RS.

---

## 1. Skema Database

Tabel `user_device_tokens` digunakan untuk menyimpan token registrasi FCM dari perangkat mobile pengguna yang sedang aktif login.

### 1.1 Struktur Kolom

| Kolom | Tipe Data | Nullable | Keterangan |
| :--- | :--- | :--- | :--- |
| `id` | `BIGINT UNSIGNED` (Auto-increment, Primary Key) | Tidak | Identifier unik baris token |
| `user_id` | `BIGINT UNSIGNED` | Tidak | Foreign key merujuk ke `users.id` (ON DELETE CASCADE) |
| `fcm_token` | `VARCHAR(500)` / `TEXT` | Tidak | Registration token yang diterbitkan oleh Firebase Cloud Messaging |
| `device_type` | `VARCHAR(20)` | Tidak | Jenis platform: `android`, `ios`, atau `web` (default: `android`) |
| `last_used_at` | `TIMESTAMP` | Ya | Waktu terakhir kali token diverifikasi atau digunakan |
| `created_at` | `TIMESTAMP` | Ya | Waktu token pertama kali didaftarkan |
| `updated_at` | `TIMESTAMP` | Ya | Waktu pembaruan rekaman token |

### 1.2 Indexes & Constraints
- `UNIQUE INDEX` pada kombinasi `(user_id, fcm_token)` untuk mencegah duplikasi token bagi pengguna yang sama.
- `INDEX` pada `fcm_token` untuk mempercepat proses pencarian saat token kadaluwarsa/unregistered.
- `INDEX` pada `user_id` untuk mempercepat query pengiriman notifikasi per pengguna.

### 1.3 Contoh File Migrasi Laravel
```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_device_tokens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('fcm_token', 500);
            $table->string('device_type', 20)->default('android');
            $table->timestamp('last_used_at')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'fcm_token']);
            $table->index('fcm_token');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_device_tokens');
    }
};
```

---

## 2. Rute & Spesifikasi API

Seluruh rute ini wajib dilindungi middleware otentikasi Sanctum (`auth:sanctum`).

### 2.1 Pendaftaran / Sinkronisasi FCM Token
- **Endpoint:** `POST /api/v1/auth/fcm-token`
- **Headers:**
  - `Authorization: Bearer <sanctum_token>`
  - `Accept: application/json`
  - `Content-Type: application/json`

#### Request Body
```json
{
  "fcm_token": "eabc123...dummy_fcm_token_string...",
  "device_type": "android"
}
```

#### Aturan Validasi
```php
$request->validate([
    'fcm_token'   => 'required|string',
    'device_type' => 'nullable|string|in:android,ios,web',
]);
```

#### Logika Controller
Gunakan `updateOrCreate` agar idempotent:
```php
$request->user()->deviceTokens()->updateOrCreate(
    ['fcm_token' => $request->fcm_token],
    [
        'device_type'  => $request->input('device_type', 'android'),
        'last_used_at' => now(),
    ]
);
```

#### Response Sukses (200 OK / 201 Created)
```json
{
  "sukses": true,
  "pesan": "FCM token berhasil disinkronkan",
  "data": {
    "fcm_token": "eabc123...dummy_fcm_token_string...",
    "device_type": "android",
    "last_used_at": "2026-10-13T07:00:00.000000Z"
  }
}
```

---

### 2.2 Pencabutan / Penghapusan FCM Token (Saat Logout)
- **Endpoint:** `DELETE /api/v1/auth/fcm-token`
- **Headers:**
  - `Authorization: Bearer <sanctum_token>`
  - `Accept: application/json`
  - `Content-Type: application/json`

#### Request Body (Opsional: hapus token spesifik atau semua token user)
```json
{
  "fcm_token": "eabc123...dummy_fcm_token_string..."
}
```

#### Logika Controller
Jika parameter `fcm_token` dikirimkan, hapus token tersebut saja. Jika kosong, hapus semua token milik pengguna yang sedang aktif logout:
```php
if ($request->filled('fcm_token')) {
    $request->user()->deviceTokens()->where('fcm_token', $request->fcm_token)->delete();
} else {
    $request->user()->deviceTokens()->delete();
}
```

#### Response Sukses (200 OK)
```json
{
  "sukses": true,
  "pesan": "FCM token berhasil dihapus"
}
```

---

## 3. Format Payload FCM (Notification & Data Message)

Aplikasi Flutter SIMLOG RS mendengarkan pesan foreground, background, dan terminated. Agar notifikasi dapat ditampilkan sistem dan mengarahkan navigasi saat diketuk, backend wajib menyertakan payload `notification` dan `data`.

### 3.1 Struktur Payload FCM JSON (Firebase HTTP v1 API)
```json
{
  "message": {
    "token": "<target_fcm_token>",
    "notification": {
      "title": "Approval PR Baru #PR-2026-0042",
      "body": "Pengajuan PR Pengadaan Obat Paracetamol membutuhkan persetujuan Anda."
    },
    "data": {
      "tipe": "APPROVAL_PR",
      "referensiId": "42",
      "judul": "Approval PR Baru #PR-2026-0042",
      "pesan": "Pengajuan PR Pengadaan Obat Paracetamol membutuhkan persetujuan Anda.",
      "timestamp": "2026-10-13T07:15:00Z"
    },
    "android": {
      "priority": "high",
      "notification": {
        "channel_id": "simlog_approval_channel",
        "sound": "default",
        "icon": "@mipmap/ic_launcher"
      }
    }
  }
}
```

### 3.2 Kamus Nilai Kolom `data.tipe`
| Nilai `tipe` | Target Pengguna | Aksi Ketuk di Aplikasi Flutter |
| :--- | :--- | :--- |
| `APPROVAL_PR` | Pejabat / Kepala Unit / Direksi | Navigasi ke Layar Detail PR / Tab Approval PR |
| `APPROVAL_AMPRAH` | Kepala Ruangan / Farmasi | Navigasi ke Layar Detail Amprah / Approval Amprah |
| `TIKET_SPK` | Teknisi IPSRS | Navigasi ke Detail SPK Perbaikan Alat Medik |
| `STOCK_ALERT` | Petugas Gudang Logistik | Navigasi ke Layar FEFO / Monitoring Stok Kritis |
| `GENERAL` | Seluruh Pengguna | Membuka Pop-up Ringkasan Notifikasi |

### 3.3 Penanganan Token Kadaluwarsa / Tidak Valid
Jika response FCM HTTP v1 mengembalikan error `UNREGISTERED` atau `INVALID_ARGUMENT` untuk suatu token, worker background Laravel harus segera menghapus token tersebut dari tabel `user_device_tokens` agar tidak membebani pengiriman berikutnya.

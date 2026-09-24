# Design System & Specification: Modern Fintech / Digital Wallet App

Dokumen spesifikasi desain ini diekstraksi dan dirancang berdasarkan referensi visual antarmuka aplikasi fintech / dompet digital pada gambar terlampir (`{{DATA:IMAGE:IMAGE_1}}`).

---

## 1. Overview & Prinsip Desain

- **Karakter Visual**: Bersih (*clean*), modern, terpercaya (*trustworthy*), dan elegan.
- **Pendekatan Layout**: Mobile-first portrait, *card-based modular UI* dengan *rounded corners* lembut dan kedalaman halus (*soft elevation/drop-shadows*).
- **Aksen & Gradasi**: Gradasi lembut *periwinkle/violet* pada kartu saldo utama memberikan daya tarik visual tanpa mengorbankan keterbacaan data finansial.

---

## 2. Palet Warna (Color Tokens)

### 2.1 Primary & Accent
- **Primary / Accent Purple**: `#5B50E6` / `#6355F6` (Tombol aksi utama, ikon navigasi aktif, badge transfer)
- **Primary Gradient**: `linear-gradient(135deg, #635BF7 0%, #766EF8 50%, #9084FA 100%)` (Total Balance & Available Balance cards)
- **Secondary Gradient Accent**: `linear-gradient(180deg, rgba(238, 237, 254, 0.7) 0%, rgba(255, 255, 255, 1) 100%)`

### 2.2 Functional & Semantics
- **Success / Positive**: `#10B981` (Teks pemasukan, mutasi masuk `+ 50,000 IQD`, tren pengeluaran positif)
- **Danger / Negative**: `#EF4444` (Teks pengeluaran/penarikan `- 50,000 IQD`)
- **Warning / Pending**: `#F59E0B` (Badge status transaksi *Pending*)
- **Category Icon Tints**:
  - Blue/Indigo: `bg-blue-50 text-blue-600` (Send Money / Bank Transfer)
  - Orange/Peach: `bg-orange-50 text-orange-600` (Request Money)
  - Violet/Purple: `bg-purple-50 text-purple-600` (Pay Bills / Money Received)
  - Teal/Cyan: `bg-teal-50 text-teal-600` (Top Up Wallet / Wallet Withdrawal)

### 2.3 Neutral & Surface
- **Background App Canvas**: `#F7F8FC` atau `#F4F5FA`
- **Surface / Card Background**: `#FFFFFF`
- **Surface Secondary / Pill**: `#F1F3F9`
- **Text Primary (Headings, Amount)**: `#0F172A` / `#1E293B`
- **Text Secondary (Subtitles, Meta)**: `#64748B` / `#94A3B8`
- **Border / Divider**: `#EDF0F7`

---

## 3. Tipografi (Typography)

- **Font Family**: Modern Sans-Serif (`Inter`, `Plus Jakarta Sans`, atau sistem native `-apple-system, BlinkMacSystemFont, "SF Pro Display"`).
- **Scale**:
  - **Display / Balances**: 28px – 32px | Bold / SemiBold | Line-height: 1.2
  - **Header H1 / Title**: 18px – 20px | SemiBold | Line-height: 1.3
  - **Subheading / Section Title**: 15px – 16px | SemiBold | Line-height: 1.4
  - **Body Text**: 14px | Regular & Medium | Line-height: 1.5
  - **Captions / Meta / Timestamps**: 11px – 12px | Regular & Medium | Line-height: 1.4
  - **Button / Chip Text**: 13px – 14px | SemiBold / Medium

---

## 4. Spacing & Elevation

- **Base Unit**: `4px`
- **Card Padding**:
  - Standard Card: `16px` – `20px`
  - Balance Card: `20px` – `24px`
- **Border Radius**:
  - Standard Cards / Containers: `20px` (`rounded-2xl`) – `24px` (`rounded-3xl`)
  - Input & Search Bar: `16px` – `20px`
  - Buttons & Action Pills: `12px` – `9999px` (`rounded-full`)
- **Shadows**:
  - Soft Card Shadow: `0 4px 20px -2px rgba(15, 23, 42, 0.04), 0 2px 6px -1px rgba(15, 23, 42, 0.02)`
  - Elevated Active Card: `0 10px 25px -4px rgba(91, 80, 230, 0.18)`

---

## 5. Komponen Utama (Core Components)

### 5.1 Top Bar & Header
- **Home Screen**:
  - Avatar pengguna (kiri, circle 40x40px).
  - Search field fleksibel dengan icon magnifying glass: *"Search transactions, contacts, or bills"*.
  - Notifikasi & Quick Action icons di sisi kanan atas (pills / badges).
- **Detail Screen (Wallet Overview)**:
  - Tombol kembali (Back chevron) + Judul Halaman (*Wallet Overview*).

### 5.2 Balance Card (Hero)
- **Home Variant**:
  - Gradasi violet lembut, teks saldo utama kontras tinggi.
  - Sub-info: *This Month Spending* dengan indikator progress/link "*See Insights*".
  - Tombol aksi cepat: `Transfer ->` berbentuk pill.
- **Detail Variant**:
  - Tampilan *Available Balance* besar terpusat.
  - Ringkasan 3 kolom (*Income*, *Expenses*, *Pending*).
  - CTA Button ukuran penuh: `Withdraw` (Purple solid, rounded-full/rounded-xl).

### 5.3 Quick Action Grid (2x2)
- Kartu grid 2 kolom:
  1. *Send Money* (Icon panah atas, subtitle counter transaksi)
  2. *Request Money* (Icon wallet+, subtitle counter requests)
  3. *Pay Bills* (Icon nota/tagihan, subtitle tagihan tertunda)
  4. *Top Up Wallet* (Icon dompet, subtitle selesai)

### 5.4 Transaction & Activity List
- Item baris transaksi terstruktur:
  - Ikon kategori dengan background tint persegi membulat (*rounded-xl*).
  - Informasi judul transaksi, timestamp, dan ID/status dot.
  - Nilai nominal transaksi di sebelah kanan:
    - Hijau (`+ 50,000 IQD`) untuk kredit/penerimaan.
    - Merah/Dark (`- 50,000 IQD`) untuk debit/penarikan.
  - Tiga titik (*more menu*) horizontal di pojok kanan atas tiap baris.

### 5.5 Bottom Navigation Bar
- Bar navigasi melayang (*floating / docked bottom nav*):
  - Items: *Home*, *Payments*, *Scan QR (Center Elevated Action)*, *Cards*, *Profile*.
  - Icon state: Ungu aktif dengan dot indikator; abu-abu netral untuk non-aktif.


### 5.6 Splash Screen & Auth Gate (Peluncuran & Pemeriksaan Sesi)
- **Karakter Visual**: Minimalis, berwibawa, modern, dan memberikan rasa aman (*clean hospital tech*).
- **Kanvas / Background**:
  - Pilihan Primer: Kanvas bersih `#F7F8FC` dengan aksen bola cahaya gradasi ungu lembut di tengah layar.
  - Pilihan Alternatif (Hero Solid): Gradasi penuh `linear-gradient(135deg, #635BF7 0%, #766EF8 50%, #9084FA 100%)`.
- **Centerpiece (Branding Icon & Typography)**:
  - **Icon Container**: Kotak membulat 88x88px (`rounded-3xl` / r: 26px) dengan gradasi ungu hero (`#635BF7` &rarr; `#9084FA`), ikon `package-check` warna putih 44px, dan bayangan elevasi `0 12px 30px rgba(91, 80, 230, 0.3)`.
  - **Judul Utama**: `SIMLOG RS` (Display 28px, ExtraBold/w800, warna `#0F172A`, letter-spacing `-0.5px`).
  - **Subtitle / Deskripsi**: `Logistik Rumah Sakit Non-Medis v2` (13px, Medium, warna `#64748B`).
- **Footer & Status Indikator**:
  - Indikator putar (*CircularProgressIndicator*) berukuran 22px warna ungu primer (`#5B50E6`).
  - Teks status proses: *"Memeriksa sesi pengguna..."* (12px, warna `#94A3B8`).
  - Nomor versi di tepi bawah: `Versi 2.0.0 • Mobile Client` (11px, warna `#CBD5E1`).
- **Transisi & Motion**:
  - Fade & scale lembut (durasi 500ms) pada saat peluncuran.
  - Navigasi mulus (*fade route transition*) ke `HomeScreen` (jika token autentikasi valid) atau `LoginScreen` (jika token kosong).
---

## 6. Pedoman Implementasi (Tailwind CSS Guide)

```html
<!-- Contoh Card Balance -->
<div class="p-6 rounded-3xl bg-gradient-to-r from-indigo-600 via-indigo-500 to-purple-500 text-white shadow-lg shadow-indigo-500/20">
  <div class="flex items-center justify-between mb-4">
    <span class="text-sm font-medium opacity-90">Total Balance</span>
    <button class="px-4 py-1.5 rounded-full bg-white/20 text-xs font-semibold backdrop-blur-sm hover:bg-white/30 transition">
      Transfer &rarr;
    </button>
  </div>
  <div class="text-3xl font-bold tracking-tight">$20,865.00</div>
</div>
```

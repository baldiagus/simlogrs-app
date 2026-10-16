import 'notification_payload.dart';

/// Tujuan navigasi mobile untuk sebuah notifikasi (kontrak bagian 4).
enum NotificationTarget {
  /// Approval Center, tab PR.
  approvalPr,

  /// Approval Center, tab Amprah.
  approvalAmprah,

  /// Antrean Picking gudang.
  antreanPicking,

  /// Daftar Inbound PO.
  inboundPo,

  /// Riwayat PR milik pengaju.
  riwayatPr,

  /// Detail Amprah.
  detailAmprah,

  /// SPPB Inbound (barang masuk ke unit).
  sppbInbound,

  /// Hub IPSRS.
  hubIpsrs,

  /// Detail SPK maintenance.
  detailSpk,

  /// Detail tiket maintenance.
  detailTiket,

  /// Otorisasi Sirkulasi aset.
  otorisasiSirkulasi,

  /// Peminjaman Saya.
  peminjamanSaya,

  /// Hub Pengalihan aset.
  hubPengalihan,

  /// Otorisasi Penyesuaian stok.
  otorisasiPenyesuaian,

  /// Layar Temuan & CAPA untuk auditee (unit/gudang terperiksa).
  capaAuditee,

  /// Hub Audit SPI tab Temuan & CAPA untuk auditor.
  capaAuditor,

  /// Inbox notifikasi.
  inbox,

  /// Tipe tidak dikenal.
  tidakDikenal,
}

/// Memetakan `tipe` payload (tidak peka huruf besar/kecil) ke [NotificationTarget].
/// Tipe `UMUM` menuju inbox; tipe asing menjadi [NotificationTarget.tidakDikenal].
NotificationTarget resolveTarget(NotificationPayload p) {
  switch (p.tipe.trim().toUpperCase()) {
    case 'APPROVAL_PR':
      return NotificationTarget.approvalPr;
    case 'APPROVAL_AMPRAH':
      return NotificationTarget.approvalAmprah;
    case 'ANTREAN_PICKING':
      return NotificationTarget.antreanPicking;
    case 'PO_TERBIT':
      return NotificationTarget.inboundPo;
    case 'PR_DIPUTUSKAN':
      return NotificationTarget.riwayatPr;
    case 'AMPRAH_DIPUTUSKAN':
      return NotificationTarget.detailAmprah;
    case 'SPPB_DIKIRIM':
      return NotificationTarget.sppbInbound;
    case 'TIKET_BARU':
      return NotificationTarget.hubIpsrs;
    case 'SPK_DITUGASKAN':
    case 'SPK_PREVENTIF':
      return NotificationTarget.detailSpk;
    case 'PERBAIKAN_SELESAI':
      return NotificationTarget.detailTiket;
    case 'PINJAM_BARU':
      return NotificationTarget.otorisasiSirkulasi;
    case 'PINJAM_DIPUTUSKAN':
    case 'PINJAM_JATUH_TEMPO':
    case 'PINJAM_TERLAMBAT':
      return NotificationTarget.peminjamanSaya;
    case 'PENGALIHAN_MASUK':
      return NotificationTarget.hubPengalihan;
    case 'OTORISASI_STOK':
      return NotificationTarget.otorisasiPenyesuaian;
    case 'CAPA_BARU':
    case 'CAPA_DIEVALUASI':
    case 'CAPA_JATUH_TEMPO':
      return NotificationTarget.capaAuditee;
    case 'CAPA_TINDAK_LANJUT':
      return NotificationTarget.capaAuditor;
    case 'UMUM':
      return NotificationTarget.inbox;
    default:
      return NotificationTarget.tidakDikenal;
  }
}

/// Indeks tab shell role gudang untuk [target]; null bila target tidak punya tab sendiri.
/// Urutan tab dengan Amprah (kepala gudang/admin logistik): Beranda, Amprah, Picking, Profil; tanpa Amprah (petugas gudang): Beranda, Inbound PO, Picking, Profil.
int? resolveGudangTabIndex(NotificationTarget target, {required bool punyaTabApproval}) {
  switch (target) {
    case NotificationTarget.approvalAmprah:
      return punyaTabApproval ? 1 : null;
    case NotificationTarget.antreanPicking:
      return 2;
    default:
      return null;
  }
}

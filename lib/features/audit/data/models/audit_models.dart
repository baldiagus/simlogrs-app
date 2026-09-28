class AuditSummaryModel {
  final int totalTemuan;
  final int totalClosed;
  final int totalInProgress;
  final int totalInReview;
  final int mayorOpen;
  final int overdue;
  final double closingRate;

  final int poTanpaPr;
  final int poTerlambat;
  final int poSelisihRcv;
  final int totalPoAnomali;

  final int sesiOpnameSelisih;
  final int penyesuaianMenunggu;
  final int totalLogAudit;

  const AuditSummaryModel({
    required this.totalTemuan,
    required this.totalClosed,
    required this.totalInProgress,
    required this.totalInReview,
    required this.mayorOpen,
    required this.overdue,
    required this.closingRate,
    required this.poTanpaPr,
    required this.poTerlambat,
    required this.poSelisihRcv,
    required this.totalPoAnomali,
    required this.sesiOpnameSelisih,
    required this.penyesuaianMenunggu,
    required this.totalLogAudit,
  });

  factory AuditSummaryModel.fromJson(Map<String, dynamic> json) {
    final capa = (json['capa'] as Map<String, dynamic>?) ?? {};
    final kepatuhan = (json['kepatuhan_po'] as Map<String, dynamic>?) ?? {};
    final opname = (json['selisih_opname'] as Map<String, dynamic>?) ?? {};

    return AuditSummaryModel(
      totalTemuan: (capa['total_temuan'] as num?)?.toInt() ?? 0,
      totalClosed: (capa['total_closed'] as num?)?.toInt() ?? 0,
      totalInProgress: (capa['total_in_progress'] as num?)?.toInt() ?? 0,
      totalInReview: (capa['total_in_review'] as num?)?.toInt() ?? 0,
      mayorOpen: (capa['mayor_open'] as num?)?.toInt() ?? 0,
      overdue: (capa['overdue'] as num?)?.toInt() ?? 0,
      closingRate: (capa['closing_rate'] as num?)?.toDouble() ?? 100.0,
      poTanpaPr: (kepatuhan['tanpa_pr'] as num?)?.toInt() ?? 0,
      poTerlambat: (kepatuhan['terlambat'] as num?)?.toInt() ?? 0,
      poSelisihRcv: (kepatuhan['selisih_rcv'] as num?)?.toInt() ?? 0,
      totalPoAnomali: (kepatuhan['total_anomali'] as num?)?.toInt() ?? 0,
      sesiOpnameSelisih: (opname['sesi_berselisih'] as num?)?.toInt() ?? 0,
      penyesuaianMenunggu: (opname['penyesuaian_menunggu'] as num?)?.toInt() ?? 0,
      totalLogAudit: (json['total_log_audit'] as num?)?.toInt() ?? 0,
    );
  }
}

class AuditTrailItemModel {
  final int id;
  final String penggunaNama;
  final String penggunaNip;
  final String peran;
  final String aksi;
  final String referensiJenis;
  final int referensiId;
  final String ipAddress;
  final String device;
  final String waktu;
  final String timestamp;
  final bool hasDataSebelum;
  final bool hasDataSesudah;
  final Map<String, dynamic>? dataSebelum;
  final Map<String, dynamic>? dataSesudah;

  const AuditTrailItemModel({
    required this.id,
    required this.penggunaNama,
    required this.penggunaNip,
    required this.peran,
    required this.aksi,
    required this.referensiJenis,
    required this.referensiId,
    required this.ipAddress,
    required this.device,
    required this.waktu,
    required this.timestamp,
    required this.hasDataSebelum,
    required this.hasDataSesudah,
    this.dataSebelum,
    this.dataSesudah,
  });

  factory AuditTrailItemModel.fromJson(Map<String, dynamic> json) {
    return AuditTrailItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      penggunaNama: json['pengguna_nama']?.toString() ?? 'Sistem',
      penggunaNip: json['pengguna_nip']?.toString() ?? '-',
      peran: json['peran']?.toString() ?? '-',
      aksi: json['aksi']?.toString() ?? 'AKSI',
      referensiJenis: json['referensi_jenis']?.toString() ?? 'Data',
      referensiId: (json['referensi_id'] as num?)?.toInt() ?? 0,
      ipAddress: json['ip_address']?.toString() ?? '-',
      device: json['device']?.toString() ?? '-',
      waktu: json['waktu']?.toString() ?? '-',
      timestamp: json['timestamp']?.toString() ?? '',
      hasDataSebelum: json['has_data_sebelum'] == true,
      hasDataSesudah: json['has_data_sesudah'] == true,
      dataSebelum: json['data_sebelum'] is Map<String, dynamic> ? json['data_sebelum'] as Map<String, dynamic> : null,
      dataSesudah: json['data_sesudah'] is Map<String, dynamic> ? json['data_sesudah'] as Map<String, dynamic> : null,
    );
  }
}

class KepatuhanPoDetailModel {
  final int id;
  final String namaBarang;
  final String satuan;
  final int jumlahDipesan;
  final int jumlahDiterima;
  final double hargaSatuan;
  final double subtotal;

  const KepatuhanPoDetailModel({
    required this.id,
    required this.namaBarang,
    required this.satuan,
    required this.jumlahDipesan,
    required this.jumlahDiterima,
    required this.hargaSatuan,
    required this.subtotal,
  });

  factory KepatuhanPoDetailModel.fromJson(Map<String, dynamic> json) {
    return KepatuhanPoDetailModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      namaBarang: json['nama_barang']?.toString() ?? 'Barang',
      satuan: json['satuan']?.toString() ?? 'Pcs',
      jumlahDipesan: (json['jumlah_dipesan'] as num?)?.toInt() ?? 0,
      jumlahDiterima: (json['jumlah_diterima'] as num?)?.toInt() ?? 0,
      hargaSatuan: (json['harga_satuan'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class KepatuhanPoModel {
  final int id;
  final String kode;
  final String pemasok;
  final String kodePemasok;
  final String tanggalPesan;
  final String estimasiTanggalKirim;
  final String status;
  final double totalBiaya;
  final String? prKode;
  final String? prUnit;
  final List<String> anomaliTags;
  final bool isCompliant;
  final int totalItem;
  final List<KepatuhanPoDetailModel> items;

  const KepatuhanPoModel({
    required this.id,
    required this.kode,
    required this.pemasok,
    required this.kodePemasok,
    required this.tanggalPesan,
    required this.estimasiTanggalKirim,
    required this.status,
    required this.totalBiaya,
    this.prKode,
    this.prUnit,
    required this.anomaliTags,
    required this.isCompliant,
    required this.totalItem,
    required this.items,
  });

  factory KepatuhanPoModel.fromJson(Map<String, dynamic> json) {
    return KepatuhanPoModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kode: json['kode']?.toString() ?? '-',
      pemasok: json['pemasok']?.toString() ?? 'Vendor',
      kodePemasok: json['kode_pemasok']?.toString() ?? '-',
      tanggalPesan: json['tanggal_pesan']?.toString() ?? '-',
      estimasiTanggalKirim: json['estimasi_tanggal_kirim']?.toString() ?? '-',
      status: json['status']?.toString() ?? '-',
      totalBiaya: (json['total_biaya'] as num?)?.toDouble() ?? 0.0,
      prKode: json['pr_kode']?.toString(),
      prUnit: json['pr_unit']?.toString(),
      anomaliTags: (json['anomali_tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isCompliant: json['is_compliant'] == true,
      totalItem: (json['total_item'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => KepatuhanPoDetailModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SelisihOpnameDetailModel {
  final int id;
  final String namaBarang;
  final String kodeBarang;
  final String satuan;
  final String nomorBatch;
  final int jumlahSistem;
  final int jumlahFisik;
  final int selisih;
  final String jenis;
  final double hargaSatuan;
  final double nilaiSelisih;
  final String catatan;

  const SelisihOpnameDetailModel({
    required this.id,
    required this.namaBarang,
    required this.kodeBarang,
    required this.satuan,
    required this.nomorBatch,
    required this.jumlahSistem,
    required this.jumlahFisik,
    required this.selisih,
    required this.jenis,
    required this.hargaSatuan,
    required this.nilaiSelisih,
    required this.catatan,
  });

  factory SelisihOpnameDetailModel.fromJson(Map<String, dynamic> json) {
    return SelisihOpnameDetailModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      namaBarang: json['nama_barang']?.toString() ?? 'Barang',
      kodeBarang: json['kode_barang']?.toString() ?? '-',
      satuan: json['satuan']?.toString() ?? 'Pcs',
      nomorBatch: json['nomor_batch']?.toString() ?? '-',
      jumlahSistem: (json['jumlah_sistem'] as num?)?.toInt() ?? 0,
      jumlahFisik: (json['jumlah_fisik'] as num?)?.toInt() ?? 0,
      selisih: (json['selisih'] as num?)?.toInt() ?? 0,
      jenis: json['jenis']?.toString() ?? ((((json['selisih'] as num?)?.toInt() ?? 0) > 0) ? 'LEBIH' : 'KURANG'),
      hargaSatuan: (json['harga_satuan'] as num?)?.toDouble() ?? 0.0,
      nilaiSelisih: (json['nilai_selisih'] as num?)?.toDouble() ?? 0.0,
      catatan: json['catatan']?.toString() ?? '-',
    );
  }
}

class SesiOpnameSelisihModel {
  final int id;
  final String kode;
  final String gudang;
  final String petugas;
  final String tanggalOpname;
  final String status;
  final int totalBatchSelisih;
  final double totalNilaiSelisih;
  final List<SelisihOpnameDetailModel> details;

  const SesiOpnameSelisihModel({
    required this.id,
    required this.kode,
    required this.gudang,
    required this.petugas,
    required this.tanggalOpname,
    required this.status,
    required this.totalBatchSelisih,
    required this.totalNilaiSelisih,
    required this.details,
  });

  factory SesiOpnameSelisihModel.fromJson(Map<String, dynamic> json) {
    return SesiOpnameSelisihModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kode: json['kode']?.toString() ?? '-',
      gudang: json['gudang']?.toString() ?? 'Gudang',
      petugas: json['petugas']?.toString() ?? 'Petugas',
      tanggalOpname: json['tanggal_opname']?.toString() ?? '-',
      status: json['status']?.toString() ?? '-',
      totalBatchSelisih: (json['total_batch_selisih'] as num?)?.toInt() ?? 0,
      totalNilaiSelisih: (json['total_nilai_selisih'] as num?)?.toDouble() ?? 0.0,
      details: (json['details'] as List<dynamic>?)
              ?.map((e) => SelisihOpnameDetailModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PenyesuaianStokItemAuditModel {
  final String namaBarang;
  final String satuan;
  final int jumlah;
  final String jenis;
  final double subtotal;

  const PenyesuaianStokItemAuditModel({
    required this.namaBarang,
    required this.satuan,
    required this.jumlah,
    required this.jenis,
    required this.subtotal,
  });

  factory PenyesuaianStokItemAuditModel.fromJson(Map<String, dynamic> json) {
    return PenyesuaianStokItemAuditModel(
      namaBarang: json['nama_barang']?.toString() ?? 'Barang',
      satuan: json['satuan']?.toString() ?? 'Pcs',
      jumlah: (json['jumlah'] as num?)?.toInt() ?? 0,
      jenis: json['jenis']?.toString() ?? 'KURANG',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PenyesuaianStokAuditModel {
  final int id;
  final String kode;
  final String gudang;
  final String status;
  final String? alasan;
  final String pengaju;
  final String penyetuju;
  final String tanggalPengajuan;
  final int totalItem;
  final double totalNilai;
  final List<PenyesuaianStokItemAuditModel> items;

  const PenyesuaianStokAuditModel({
    required this.id,
    required this.kode,
    required this.gudang,
    required this.status,
    this.alasan,
    required this.pengaju,
    required this.penyetuju,
    required this.tanggalPengajuan,
    required this.totalItem,
    required this.totalNilai,
    required this.items,
  });

  factory PenyesuaianStokAuditModel.fromJson(Map<String, dynamic> json) {
    return PenyesuaianStokAuditModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kode: json['kode']?.toString() ?? '-',
      gudang: json['gudang']?.toString() ?? 'Gudang',
      status: json['status']?.toString() ?? 'MENUNGGU',
      alasan: json['alasan']?.toString(),
      pengaju: json['pengaju']?.toString() ?? 'Petugas',
      penyetuju: json['penyetuju']?.toString() ?? '-',
      tanggalPengajuan: json['tanggal_pengajuan']?.toString() ?? '-',
      totalItem: (json['total_item'] as num?)?.toInt() ?? 0,
      totalNilai: (json['total_nilai'] as num?)?.toDouble() ?? 0.0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PenyesuaianStokItemAuditModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TemuanCapaModel {
  final int id;
  final String kode;
  final String tanggalAudit;
  final String objekAudit;
  final String ringkasan;
  final String tingkatRisiko;
  final String dueDateCapa;
  final String statusCapa;
  final bool isOverdue;
  final String auditor;
  final String evaluator;
  final String unit;
  final String? gudang;
  final String? analisisPenyebab;
  final String? tindakanPerbaikan;
  final String? catatanEvaluasi;
  final List<String> buktiPerbaikan;

  const TemuanCapaModel({
    required this.id,
    required this.kode,
    required this.tanggalAudit,
    required this.objekAudit,
    required this.ringkasan,
    required this.tingkatRisiko,
    required this.dueDateCapa,
    required this.statusCapa,
    required this.isOverdue,
    required this.auditor,
    required this.evaluator,
    required this.unit,
    this.gudang,
    this.analisisPenyebab,
    this.tindakanPerbaikan,
    this.catatanEvaluasi,
    required this.buktiPerbaikan,
  });

  factory TemuanCapaModel.fromJson(Map<String, dynamic> json) {
    return TemuanCapaModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kode: json['kode']?.toString() ?? '-',
      tanggalAudit: json['tanggal_audit']?.toString() ?? '-',
      objekAudit: json['objek_audit']?.toString() ?? '-',
      ringkasan: json['ringkasan']?.toString() ?? '-',
      tingkatRisiko: json['tingkat_risiko']?.toString() ?? 'Moderat',
      dueDateCapa: json['due_date_capa']?.toString() ?? '-',
      statusCapa: json['status_capa']?.toString() ?? 'In Progress',
      isOverdue: json['is_overdue'] == true,
      auditor: json['auditor']?.toString() ?? 'Auditor SPI',
      evaluator: json['evaluator']?.toString() ?? '-',
      unit: json['unit']?.toString() ?? 'Sentral',
      gudang: json['gudang']?.toString(),
      analisisPenyebab: json['analisis_penyebab']?.toString(),
      tindakanPerbaikan: json['tindakan_perbaikan']?.toString(),
      catatanEvaluasi: json['catatan_evaluasi']?.toString(),
      buktiPerbaikan: (json['bukti_perbaikan'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

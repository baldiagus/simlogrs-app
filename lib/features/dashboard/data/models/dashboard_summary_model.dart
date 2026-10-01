class SubMetricModel {
  final String label;
  final String nilai;
  final String warna; // 'warning', 'blue', 'purple', 'danger', 'text'

  const SubMetricModel({
    required this.label,
    required this.nilai,
    this.warna = 'text',
  });

  factory SubMetricModel.fromJson(Map<String, dynamic> json) {
    return SubMetricModel(
      label: json['label']?.toString() ?? '',
      nilai: json['nilai']?.toString() ?? '0',
      warna: json['warna']?.toString() ?? 'text',
    );
  }
}

class HeroMetricModel {
  final String judul;
  final int total;
  final String satuan;
  final String labelTombol;
  final String targetAksi; // 'approval', 'spk_list', 'amprah_hub', 'picking', 'inbound'
  final List<SubMetricModel> subMetrik;

  const HeroMetricModel({
    required this.judul,
    required this.total,
    required this.satuan,
    required this.labelTombol,
    required this.targetAksi,
    required this.subMetrik,
  });

  factory HeroMetricModel.fromJson(Map<String, dynamic> json) {
    return HeroMetricModel(
      judul: json['judul']?.toString() ?? 'Total Antrean Kerja',
      total: (json['total'] is num)
          ? (json['total'] as num).toInt()
          : (double.tryParse(json['total']?.toString() ?? '')?.toInt() ?? 0),
      satuan: json['satuan']?.toString() ?? 'Dokumen',
      labelTombol: json['label_tombol']?.toString() ?? 'Periksa',
      targetAksi: json['target_aksi']?.toString() ?? 'approval',
      subMetrik: (json['sub_metrik'] as List<dynamic>?)
              ?.map((e) => SubMetricModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  factory HeroMetricModel.fallback({
    required int prCount,
    required int amprahCount,
    required int spkCount,
  }) {
    final total = prCount + amprahCount;
    return HeroMetricModel(
      judul: 'Total Antrean Approval',
      total: total,
      satuan: 'Dokumen',
      labelTombol: 'Periksa',
      targetAksi: 'approval',
      subMetrik: [
        SubMetricModel(label: 'PR Menunggu', nilai: '$prCount', warna: 'warning'),
        SubMetricModel(label: 'Amprah Menunggu', nilai: '$amprahCount', warna: 'blue'),
        SubMetricModel(label: 'SPK Aktif', nilai: '$spkCount', warna: 'purple'),
      ],
    );
  }
}

class ActivityItemModel {
  final String id;
  final String title;
  final String subtitle;
  final String timestamp;
  final String waktuLalu;
  final String status;
  final String type; // 'pr', 'amprah', 'spk', 'tiket', 'po', 'inbound'
  final String? kode;

  const ActivityItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.waktuLalu = '',
    required this.status,
    required this.type,
    this.kode,
  });

  factory ActivityItemModel.fromJson(Map<String, dynamic> json) {
    final tipe = json['tipe']?.toString().toLowerCase() ?? 'dokumen';
    return ActivityItemModel(
      id: json['id']?.toString() ?? '',
      title: json['judul']?.toString() ?? json['kode']?.toString() ?? 'Aktivitas',
      subtitle: json['subjudul']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      waktuLalu: json['waktu_lalu']?.toString() ?? '',
      status: json['status']?.toString() ?? 'DIAJUKAN',
      type: tipe,
      kode: json['kode']?.toString(),
    );
  }

  factory ActivityItemModel.fromPr(Map<String, dynamic> json) {
    return ActivityItemModel(
      id: json['id']?.toString() ?? '',
      title: json['nomor_pr']?.toString() ?? json['kode']?.toString() ?? 'Permintaan Pengadaan',
      subtitle: json['nama_unit']?.toString() ?? json['unit']?.toString() ?? 'Unit Pemohon',
      timestamp: json['tanggal_pengajuan']?.toString() ?? json['tanggal']?.toString() ?? '',
      waktuLalu: json['tanggal_pengajuan']?.toString() ?? '',
      status: json['status']?.toString() ?? 'DIAJUKAN',
      type: 'pr',
      kode: json['kode']?.toString(),
    );
  }

  factory ActivityItemModel.fromAmprah(Map<String, dynamic> json) {
    return ActivityItemModel(
      id: json['id']?.toString() ?? '',
      title: json['nomor_permintaan']?.toString() ?? json['kode']?.toString() ?? 'Amprah Ruangan',
      subtitle: json['nama_unit']?.toString() ?? json['unit']?.toString() ?? 'Unit Pemohon',
      timestamp: json['tanggal_permintaan']?.toString() ?? json['tanggal']?.toString() ?? '',
      waktuLalu: json['tanggal_permintaan']?.toString() ?? '',
      status: json['status']?.toString() ?? 'DIAJUKAN',
      type: 'amprah',
      kode: json['kode']?.toString(),
    );
  }
}

class DashboardSummaryModel {
  final HeroMetricModel hero;
  final List<ActivityItemModel> recentActivities;

  int get totalPendingApproval {
    if (hero.judul.toLowerCase().contains('pengajuan')) {
      return prCount + amprahCount;
    }
    return hero.total;
  }

  int get prCount {
    for (final s in hero.subMetrik) {
      if (s.label.toLowerCase().contains('pr')) {
        return int.tryParse(s.nilai) ?? 0;
      }
    }
    return 0;
  }

  int get amprahCount {
    for (final s in hero.subMetrik) {
      if (s.label.toLowerCase().contains('amprah')) {
        return int.tryParse(s.nilai) ?? 0;
      }
    }
    return 0;
  }

  int get activeSpkCount {
    for (final s in hero.subMetrik) {
      if (s.label.toLowerCase().contains('spk') || s.label.toLowerCase().contains('tugas')) {
        return int.tryParse(s.nilai) ?? 0;
      }
    }
    return 0;
  }

  const DashboardSummaryModel({
    required this.hero,
    required this.recentActivities,
  });

  factory DashboardSummaryModel.empty() {
    return DashboardSummaryModel(
      hero: HeroMetricModel.fallback(prCount: 0, amprahCount: 0, spkCount: 0),
      recentActivities: const [],
    );
  }

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final hero = json['hero'] is Map<String, dynamic>
        ? HeroMetricModel.fromJson(json['hero'] as Map<String, dynamic>)
        : HeroMetricModel.fallback(prCount: 0, amprahCount: 0, spkCount: 0);

    final activities = (json['aktivitas'] as List<dynamic>?)
            ?.map((e) => ActivityItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return DashboardSummaryModel(
      hero: hero,
      recentActivities: activities,
    );
  }
}

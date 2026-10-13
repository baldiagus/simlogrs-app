/// Model metadata paginasi dan pembungkus respon berhalaman.
class PaginationMeta {
  /// Total seluruh item di seluruh halaman di backend.
  final int total;

  /// Jumlah item per halaman.
  final int perHalaman;

  /// Nomor halaman saat ini (1-based).
  final int halamanIni;

  /// Total jumlah halaman yang tersedia.
  final int totalHalaman;

  /// Membuat instance [PaginationMeta].
  const PaginationMeta({
    required this.total,
    required this.perHalaman,
    required this.halamanIni,
    required this.totalHalaman,
  });

  /// Mengembalikan true bila masih ada halaman berikutnya yang bisa dimuat.
  bool get hasMore => halamanIni < totalHalaman;

  /// Membuat [PaginationMeta] dari JSON map (mendukung kunci bahasa Indonesia dan standar Laravel).
  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      total: (json['total'] as num?)?.toInt() ?? 0,
      perHalaman: (json['per_halaman'] as num?)?.toInt() ??
          (json['per_page'] as num?)?.toInt() ??
          20,
      halamanIni: (json['halaman_ini'] as num?)?.toInt() ??
          (json['current_page'] as num?)?.toInt() ??
          1,
      totalHalaman: (json['total_halaman'] as num?)?.toInt() ??
          (json['last_page'] as num?)?.toInt() ??
          1,
    );
  }

  /// Mengonversi model ke Map JSON.
  Map<String, dynamic> toJson() => {
        'total': total,
        'per_halaman': perHalaman,
        'halaman_ini': halamanIni,
        'total_halaman': totalHalaman,
      };

  /// Instance default kosong.
  static const empty = PaginationMeta(
    total: 0,
    perHalaman: 20,
    halamanIni: 1,
    totalHalaman: 1,
  );
}

/// Pembungkus data respon berhalaman dari repository.
class PagedResponse<T> {
  /// Daftar item pada halaman saat ini.
  final List<T> items;

  /// Metadata paginasi dari backend.
  final PaginationMeta meta;

  /// Membuat [PagedResponse] dengan daftar [items] dan [meta].
  const PagedResponse({
    required this.items,
    required this.meta,
  });

  /// Respon kosong dengan [PaginationMeta.empty].
  static PagedResponse<T> empty<T>() => PagedResponse<T>(
        items: const [],
        meta: PaginationMeta.empty,
      );
}

/// State generik untuk daftar data yang mendukung paginasi dan infinite scroll.
class PagedListState<T> {
  /// Daftar item terakumulasi dari halaman 1 hingga [page].
  final List<T> items;

  /// Halaman terakhir yang berhasil dimuat.
  final int page;

  /// True bila masih ada data di halaman berikutnya.
  final bool hasMore;

  /// True saat pemuatan awal (halaman 1) sedang berlangsung.
  final bool isLoading;

  /// True saat pemuatan halaman tambahan (halaman 2+) sedang berlangsung di latar belakang.
  final bool isLoadingMore;

  /// Pesan error bila terjadi kegagalan pemuatan.
  final String? errorMessage;

  /// Membuat instance [PagedListState].
  const PagedListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  /// State awal saat belum ada data yang dimuat.
  const PagedListState.initial() : this(isLoading: true);
  /// Salin state dengan nilai baru opsional.
  PagedListState<T> copyWith({
    List<T>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PagedListState<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

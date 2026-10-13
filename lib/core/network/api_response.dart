class ApiMeta {
  final String versiApi;
  final String timestamp;
  final int? waktuEksekusiMs;

  const ApiMeta({
    required this.versiApi,
    required this.timestamp,
    this.waktuEksekusiMs,
  });

  /// Membangun metadata respons API dari JSON, dengan nilai bawaan jika field kosong.
  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    return ApiMeta(
      versiApi: json['versi_api']?.toString() ?? 'v1.0',
      timestamp: json['timestamp']?.toString() ?? '',
      waktuEksekusiMs: json['waktu_eksekusi_ms'] is int
          ? json['waktu_eksekusi_ms'] as int
          : null,
    );
  }
}

class ApiResponse<T> {
  final bool sukses;
  final String pesan;
  final T? data;
  final ApiMeta? meta;
  final Map<String, dynamic>? errors;

  const ApiResponse({
    required this.sukses,
    required this.pesan,
    this.data,
    this.meta,
    this.errors,
  });

  /// Membangun respons API standar dari JSON; `fromJsonT` mengonversi field `data` ke tipe T.
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic rawJson)? fromJsonT,
  ) {
    return ApiResponse<T>(
      sukses: json['sukses'] == true,
      pesan: json['pesan']?.toString() ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : (json['data'] as T?),
      meta: json['meta'] is Map<String, dynamic>
          ? ApiMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
      errors: json['errors'] is Map<String, dynamic>
          ? json['errors'] as Map<String, dynamic>
          : null,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  /// Representasi teks pengecualian untuk keperluan log dan debugging.
  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

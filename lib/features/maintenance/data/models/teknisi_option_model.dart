class TeknisiOptionModel {
  final int id;
  final String nama;
  final String email;
  final String? nip;

  const TeknisiOptionModel({
    required this.id,
    required this.nama,
    required this.email,
    this.nip,
  });

  factory TeknisiOptionModel.fromJson(Map<String, dynamic> json) {
    return TeknisiOptionModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      nama: json['nama']?.toString() ?? 'Teknisi',
      email: json['email']?.toString() ?? '',
      nip: json['nip']?.toString(),
    );
  }
}

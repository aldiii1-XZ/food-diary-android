class FoodEntry {
  FoodEntry({
    required this.id,
    this.name = '',
    this.note = '',
    this.kcal,
    required this.consumedAt,
    this.photoFileName,
  });

  final String id;
  String name;
  String note;

  /// Kalori (kkal) bila diketahui; null = tidak dihitung.
  int? kcal;

  DateTime consumedAt;
  String? photoFileName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'kcal': kcal,
        'consumedAt': consumedAt.toIso8601String(),
        'photoFileName': photoFileName,
      };

  /// Dibaca defensif: kunci yang hilang/tak terduga tidak membuat app gagal.
  factory FoodEntry.fromJson(Map<String, dynamic> json) => FoodEntry(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        note: (json['note'] as String?) ?? '',
        kcal: (json['kcal'] as num?)?.toInt(),
        consumedAt: DateTime.parse(json['consumedAt'] as String),
        photoFileName: json['photoFileName'] as String?,
      );
}

class MoveDetail {
  final int id;
  final String name;
  final String? type;
  final int? power;
  final int? accuracy;
  final int? pp;
  final String? damageClass; // physical, special, status
  final String? effectText;

  MoveDetail({
    required this.id,
    required this.name,
    this.type,
    this.power,
    this.accuracy,
    this.pp,
    this.damageClass,
    this.effectText,
  });

  String get displayName =>
      name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  factory MoveDetail.fromJson(Map<String, dynamic> json) {
    String? effectText;
    final effectEntries = json['effect_entries'] as List? ?? [];
    for (final e in effectEntries) {
      if (e['language']['name'] == 'en') {
        effectText = e['short_effect'];
        break;
      }
    }

    return MoveDetail(
      id: json['id'],
      name: json['name'],
      type: json['type']?['name'],
      power: json['power'],
      accuracy: json['accuracy'],
      pp: json['pp'],
      damageClass: json['damage_class']?['name'],
      effectText: effectText,
    );
  }
}

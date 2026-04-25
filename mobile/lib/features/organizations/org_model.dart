class Org {
  final String id;
  final String name;
  final String type;
  final DateTime createdAt;

  Org({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  factory Org.fromJson(Map<String, dynamic> json) {
    return Org(
      id: json['_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

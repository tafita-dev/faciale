class Org {
  final String id;
  final String name;
  final String type;
  final String? logoUrl;
  final double? recognitionThreshold;
  final DateTime createdAt;

  Org({
    required this.id,
    required this.name,
    required this.type,
    this.logoUrl,
    this.recognitionThreshold,
    required this.createdAt,
  });

  factory Org.fromJson(Map<String, dynamic> json) {
    return Org(
      id: json['_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      logoUrl: json['logo_url'] as String?,
      recognitionThreshold: (json['recognition_threshold'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'type': type,
      'logo_url': logoUrl,
      'recognition_threshold': recognitionThreshold,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

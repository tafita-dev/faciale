class OrgSettings {
  final String startTime;
  final int lateBufferMinutes;

  OrgSettings({
    required this.startTime,
    required this.lateBufferMinutes,
  });

  factory OrgSettings.fromJson(Map<String, dynamic> json) {
    return OrgSettings(
      startTime: json['start_time'] as String? ?? "09:00",
      lateBufferMinutes: json['late_buffer_minutes'] as int? ?? 15,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_time': startTime,
      'late_buffer_minutes': lateBufferMinutes,
    };
  }
}

class Org {
  final String id;
  final String name;
  final String type;
  final String? adminEmail;
  final String? logoUrl;
  final double? recognitionThreshold;
  final DateTime createdAt;
  final OrgSettings? settings;

  Org({
    required this.id,
    required this.name,
    required this.type,
    this.adminEmail,
    this.logoUrl,
    this.recognitionThreshold,
    required this.createdAt,
    this.settings,
  });

  factory Org.fromJson(Map<String, dynamic> json) {
    return Org(
      id: json['_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      adminEmail: json['admin_email'] as String?,
      logoUrl: json['logo_url'] as String?,
      recognitionThreshold: (json['recognition_threshold'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      settings: json['settings'] != null 
          ? OrgSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'type': type,
      'admin_email': adminEmail,
      'logo_url': logoUrl,
      'recognition_threshold': recognitionThreshold,
      'created_at': createdAt.toIso8601String(),
      if (settings != null) 'settings': settings!.toJson(),
    };
  }
}

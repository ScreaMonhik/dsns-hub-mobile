class EmergencyAlert {
  const EmergencyAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.severity,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String severity;
  final DateTime createdAt;

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      severity: json['severity'] as String? ?? 'INFO',
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }
}

class EmergencyAlertsPage {
  const EmergencyAlertsPage({
    required this.data,
    required this.page,
    required this.lastPage,
  });

  final List<EmergencyAlert> data;
  final int page;
  final int lastPage;

  factory EmergencyAlertsPage.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return EmergencyAlertsPage(
      data: ((json['data'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(EmergencyAlert.fromJson)
          .toList(),
      page: (meta['page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['lastPage'] as num?)?.toInt() ?? 1,
    );
  }
}

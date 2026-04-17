class SiteSettings {
  final String siteId;
  final String siteName;
  final int overstayThresholdHours;

  SiteSettings({
    required this.siteId,
    required this.siteName,
    required this.overstayThresholdHours,
  });

  factory SiteSettings.fromMap(Map<String, dynamic> map, String id) {
    return SiteSettings(
      siteId: id,
      siteName: map['site_name'] ?? '',
      overstayThresholdHours: map['overstay_threshold_hours'] ?? 8,
    );
  }

  Map<String, dynamic> toMap() => {
        'site_name': siteName,
        'overstay_threshold_hours': overstayThresholdHours,
      };
}

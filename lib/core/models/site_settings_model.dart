class GuestSlipWarnings {
  final Map<String, String> english;
  final Map<String, String> urdu;

  GuestSlipWarnings({required this.english, required this.urdu});

  factory GuestSlipWarnings.fromMap(Map<String, dynamic> map) {
    Map<String, String> toStringMap(dynamic raw) {
      if (raw == null) return {};
      return Map<String, String>.from(
          (raw as Map).map((k, v) => MapEntry(k.toString(), v.toString())));
    }
    return GuestSlipWarnings(
      english: toStringMap(map['guest_slip_warnings']),
      urdu: toStringMap(map['guest_slip_warnings_urdu']),
    );
  }
}

class SiteSettings {
  final String siteId;
  final String siteName;
  final int overstayThresholdHours;
  final int cardExpiryAlertDays;
  final int guestValidityHours;
  final GuestSlipWarnings? guestSlipWarnings;

  SiteSettings({
    required this.siteId,
    required this.siteName,
    required this.overstayThresholdHours,
    this.cardExpiryAlertDays = 30,
    this.guestValidityHours = 24,
    this.guestSlipWarnings,
  });

  factory SiteSettings.fromMap(Map<String, dynamic> map, String id) {
    return SiteSettings(
      siteId: id,
      siteName: map['site_name'] ?? '',
      overstayThresholdHours: map['overstay_threshold_hours'] is int
          ? map['overstay_threshold_hours']
          : int.tryParse(map['overstay_threshold_hours']?.toString() ?? '') ?? 8,
      cardExpiryAlertDays: map['card_expiry_alert_days'] is int
          ? map['card_expiry_alert_days']
          : int.tryParse(map['card_expiry_alert_days']?.toString() ?? '') ?? 30,
      guestValidityHours: map['guest_validity_hours'] is int
          ? map['guest_validity_hours']
          : int.tryParse(map['guest_validity_hours']?.toString() ?? '') ?? 24,
      guestSlipWarnings: GuestSlipWarnings.fromMap(map),
    );
  }

  Map<String, dynamic> toMap() => {
        'site_name': siteName,
        'overstay_threshold_hours': overstayThresholdHours,
        'card_expiry_alert_days': cardExpiryAlertDays,
        'guest_validity_hours': guestValidityHours,
      };
}

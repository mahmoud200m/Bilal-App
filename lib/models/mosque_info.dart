class MosqueInfo {
  final String uuid;
  final String name;
  final String slug;
  final String? localisation;
  final String? phone;
  final String? email;
  final String? site;
  final String? image;
  final String? jumua;
  final String? jumua2;
  final double? latitude;
  final double? longitude;
  final bool iqamaEnabled;
  final int hijriAdjustment;
  final List<String>? todayTimes;
  final List<String>? iqama;

  const MosqueInfo({
    required this.uuid,
    required this.name,
    required this.slug,
    this.localisation,
    this.phone,
    this.email,
    this.site,
    this.image,
    this.jumua,
    this.jumua2,
    this.latitude,
    this.longitude,
    this.iqamaEnabled = false,
    this.hijriAdjustment = 0,
    this.todayTimes,
    this.iqama,
  });

  factory MosqueInfo.fromSearchJson(Map<String, dynamic> json) {
    return MosqueInfo(
      uuid: json['uuid'] as String? ?? '',
      name: json['name'] as String? ?? json['label'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      localisation: json['localisation'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      site: json['site'] as String?,
      image: json['image'] as String?,
      jumua: json['jumua'] as String?,
      jumua2: json['jumua2'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      iqamaEnabled: json['iqamaEnabled'] as bool? ?? false,
      todayTimes: (json['times'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      iqama: (json['iqama'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'name': name,
        'slug': slug,
        'localisation': localisation,
        'phone': phone,
        'email': email,
        'site': site,
        'image': image,
        'jumua': jumua,
        'jumua2': jumua2,
        'latitude': latitude,
        'longitude': longitude,
        'iqamaEnabled': iqamaEnabled,
        'hijriAdjustment': hijriAdjustment,
      };

  factory MosqueInfo.fromJson(Map<String, dynamic> json) {
    return MosqueInfo(
      uuid: json['uuid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      localisation: json['localisation'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      site: json['site'] as String?,
      image: json['image'] as String?,
      jumua: json['jumua'] as String?,
      jumua2: json['jumua2'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      iqamaEnabled: json['iqamaEnabled'] as bool? ?? false,
      hijriAdjustment: (json['hijriAdjustment'] as num?)?.toInt() ?? 0,
    );
  }
}

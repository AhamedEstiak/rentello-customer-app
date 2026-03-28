class Upazila {
  final String id;
  final String name;

  const Upazila({
    required this.id,
    required this.name,
  });

  factory Upazila.fromJson(Map<String, dynamic> json) {
    String pickString(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v != null) return v.toString();
      }
      return '';
    }

    return Upazila(
      id: pickString(['id', 'upazilaId', '_id']),
      name: pickString(['name', 'upazilaName', 'displayName']),
    );
  }
}

class DistrictLocation {
  final String id;
  final String name;
  final List<Upazila> upazilas;

  const DistrictLocation({
    required this.id,
    required this.name,
    required this.upazilas,
  });

  factory DistrictLocation.fromJson(Map<String, dynamic> json) {
    String pickString(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v != null) return v.toString();
      }
      return '';
    }

    final upazilasRaw = json['upazilas'] ??
        json['upazilaList'] ??
        json['children'] ??
        json['upazila'] ??
        <dynamic>[];

    final upazilas = (upazilasRaw as List<dynamic>)
        .map((e) => Upazila.fromJson(e as Map<String, dynamic>))
        .toList();

    return DistrictLocation(
      id: pickString(['id', 'districtId', '_id']),
      name: pickString(['name', 'districtName', 'displayName']),
      upazilas: upazilas,
    );
  }
}

class LocationSelection {
  final String districtId;
  final String upazilaId;
  final String label;

  const LocationSelection({
    required this.districtId,
    required this.upazilaId,
    required this.label,
  });
}


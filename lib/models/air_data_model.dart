class AirData {
  final String id;
  final DateTime date;
  final int aqi;
  final double? pm25;
  final double? co2;
  final double? temperature;
  final String riskLevel;
  final double latitude;
  final double longitude;

  AirData({
    required this.id,
    required this.date,
    required this.aqi,
    this.pm25,
    this.co2,
    this.temperature,
    required this.riskLevel,
    required this.latitude,
    required this.longitude,
  });

  factory AirData.fromMap(Map<String, dynamic> map) {
    return AirData(
      id: map['id'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      aqi: map['aqi'] ?? 0,
      pm25: map['pm25']?.toDouble(),
      co2: map['co2']?.toDouble(),
      temperature: map['temperature']?.toDouble(),
      riskLevel: map['riskLevel'] ?? 'Unknown',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'aqi': aqi,
      'pm25': pm25,
      'co2': co2,
      'temperature': temperature,
      'riskLevel': riskLevel,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get aqiDescription {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  String get aqiColor {
    if (aqi <= 50) return '#00E400';
    if (aqi <= 100) return '#FFFF00';
    if (aqi <= 150) return '#FF7E00';
    if (aqi <= 200) return '#FF0000';
    if (aqi <= 300) return '#8F3F97';
    return '#7E0023';
  }
}


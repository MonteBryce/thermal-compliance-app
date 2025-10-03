class ThermalReading {
  final int hour;
  final String timestamp;

  // Readings
  final double? inletReading;
  final double? outletReading;
  final double? toInletReadingH2S;
  final double? lelInletReading; // Marathon GBR specific field

  // Flow Rates
  final double? vaporInletFlowRateFPM;
  final double? vaporInletFlowRateBBL;
  final double? tankRefillFlowRate;
  final double? combustionAirFlowRate;

  // System Metrics
  final double? vacuumAtTankVaporOutlet;
  final double? exhaustTemperature;
  final double? totalizer;

  // Notes
  final String observations;
  final String operatorId;
  final bool validated;

  ThermalReading({
    required this.hour,
    required this.timestamp,
    this.inletReading,
    this.outletReading,
    this.toInletReadingH2S,
    this.lelInletReading,
    this.vaporInletFlowRateFPM,
    this.vaporInletFlowRateBBL,
    this.tankRefillFlowRate,
    this.combustionAirFlowRate,
    this.vacuumAtTankVaporOutlet,
    this.exhaustTemperature,
    this.totalizer,
    this.observations = '',
    this.operatorId = 'OP001',
    this.validated = false,
  });

  factory ThermalReading.fromJson(Map<String, dynamic> json) {
    return ThermalReading(
      hour: json['hour'],
      timestamp: json['timestamp'],
      inletReading: json['inletReading']?.toDouble(),
      outletReading: json['outletReading']?.toDouble(),
      toInletReadingH2S: json['toInletReadingH2S']?.toDouble(),
      lelInletReading: json['lelInletReading']?.toDouble(),
      vaporInletFlowRateFPM: json['vaporInletFlowRateFPM']?.toDouble(),
      vaporInletFlowRateBBL: json['vaporInletFlowRateBBL']?.toDouble(),
      tankRefillFlowRate: json['tankRefillFlowRate']?.toDouble(),
      combustionAirFlowRate: json['combustionAirFlowRate']?.toDouble(),
      vacuumAtTankVaporOutlet: json['vacuumAtTankVaporOutlet']?.toDouble(),
      exhaustTemperature: json['exhaustTemperature']?.toDouble(),
      totalizer: json['totalizer']?.toDouble(),
      observations: json['observations'] ?? '',
      operatorId: json['operatorId'] ?? 'OP001',
      validated: json['validated'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'timestamp': timestamp,
      'inletReading': inletReading,
      'outletReading': outletReading,
      'toInletReadingH2S': toInletReadingH2S,
      'lelInletReading': lelInletReading,
      'vaporInletFlowRateFPM': vaporInletFlowRateFPM,
      'vaporInletFlowRateBBL': vaporInletFlowRateBBL,
      'tankRefillFlowRate': tankRefillFlowRate,
      'combustionAirFlowRate': combustionAirFlowRate,
      'vacuumAtTankVaporOutlet': vacuumAtTankVaporOutlet,
      'exhaustTemperature': exhaustTemperature,
      'totalizer': totalizer,
      'observations': observations,
      'operatorId': operatorId,
      'validated': validated,
    };
  }
}
// JobData model for use across the app
class JobData {
  final String projectNumber;
  final String projectName;
  final String unitNumber;
  final String date;
  final String status;
  final String location;
  final String workOrderNumber;
  final String tankType;
  final String facilityTarget;
  final String operatingTemperature;
  final String benzeneTarget;
  final bool h2sAmpRequired;
  final String product;

  JobData({
    required this.projectNumber,
    required this.projectName,
    required this.unitNumber,
    required this.date,
    required this.status,
    required this.location,
    required this.workOrderNumber,
    required this.tankType,
    required this.facilityTarget,
    required this.operatingTemperature,
    required this.benzeneTarget,
    required this.h2sAmpRequired,
    required this.product,
  });

  factory JobData.fromJson(Map<String, dynamic> json) {
    return JobData(
      projectNumber: json['projectNumber'],
      projectName: json['projectName'],
      unitNumber: json['unitNumber'],
      date: json['date'],
      status: json['status'],
      location: json['location'],
      workOrderNumber: json['workOrderNumber'] ?? '',
      tankType: json['tankType'] ?? '',
      facilityTarget: json['facilityTarget'] ?? '',
      operatingTemperature: json['operatingTemperature'] ?? '',
      benzeneTarget: json['benzeneTarget'] ?? '',
      h2sAmpRequired: json['h2sAmpRequired'] ?? false,
      product: json['product'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectNumber': projectNumber,
      'projectName': projectName,
      'unitNumber': unitNumber,
      'date': date,
      'status': status,
      'location': location,
      'workOrderNumber': workOrderNumber,
      'tankType': tankType,
      'facilityTarget': facilityTarget,
      'operatingTemperature': operatingTemperature,
      'benzeneTarget': benzeneTarget,
      'h2sAmpRequired': h2sAmpRequired,
      'product': product,
    };
  }
}

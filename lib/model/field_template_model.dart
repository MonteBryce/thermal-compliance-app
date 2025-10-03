class FieldTemplate {
  final String key;
  final String label;
  final String type;
  final String? unit;

  FieldTemplate({
    required this.key,
    required this.label,
    required this.type,
    this.unit,
  });

  factory FieldTemplate.fromMap(Map<String, dynamic> map) {
    return FieldTemplate(
      key: map['key'],
      label: map['label'],
      type: map['type'],
      unit: map['unit'],
    );
  }
}

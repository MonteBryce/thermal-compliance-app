// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thermal_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ThermalLogAdapter extends TypeAdapter<ThermalLog> {
  @override
  final int typeId = 5;

  @override
  ThermalLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ThermalLog(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      temperature: fields[2] as double,
      notes: fields[3] as String,
      projectId: fields[4] as String,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ThermalLog obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.temperature)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.projectId)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThermalLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

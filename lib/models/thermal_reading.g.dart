import 'package:hive/hive.dart';
import 'thermal_reading.dart';

class ThermalReadingAdapter extends TypeAdapter<ThermalReading> {
  @override
  final int typeId = 10; // Unique ID for this type (changed to avoid conflict)

  @override
  ThermalReading read(BinaryReader reader) {
    return ThermalReading(
      hour: reader.readInt(),
      timestamp: reader.readString(),
      inletReading: reader.readDouble(),
      outletReading: reader.readDouble(),
      toInletReadingH2S: reader.readDouble(),
      vaporInletFlowRateFPM: reader.readDouble(),
      vaporInletFlowRateBBL: reader.readDouble(),
      tankRefillFlowRate: reader.readDouble(),
      combustionAirFlowRate: reader.readDouble(),
      vacuumAtTankVaporOutlet: reader.readDouble(),
      exhaustTemperature: reader.readDouble(),
      totalizer: reader.readDouble(),
      observations: reader.readString(),
      operatorId: reader.readString(),
      validated: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, ThermalReading obj) {
    writer.writeInt(obj.hour);
    writer.writeString(obj.timestamp);
    writer.writeDouble(obj.inletReading ?? 0.0);
    writer.writeDouble(obj.outletReading ?? 0.0);
    writer.writeDouble(obj.toInletReadingH2S ?? 0.0);
    writer.writeDouble(obj.vaporInletFlowRateFPM ?? 0.0);
    writer.writeDouble(obj.vaporInletFlowRateBBL ?? 0.0);
    writer.writeDouble(obj.tankRefillFlowRate ?? 0.0);
    writer.writeDouble(obj.combustionAirFlowRate ?? 0.0);
    writer.writeDouble(obj.vacuumAtTankVaporOutlet ?? 0.0);
    writer.writeDouble(obj.exhaustTemperature ?? 0.0);
    writer.writeDouble(obj.totalizer ?? 0.0);
    writer.writeString(obj.observations);
    writer.writeString(obj.operatorId);
    writer.writeBool(obj.validated);
  }
}
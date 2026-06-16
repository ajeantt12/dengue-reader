// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dot_reading.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DotReadingAdapter extends TypeAdapter<DotReading> {
  @override
  final int typeId = 1;

  @override
  DotReading read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DotReading(
      dotId: fields[0] as String,
      hue: fields[1] as double,
      saturation: fields[2] as double,
      value: fields[3] as double,
      rawR: fields[4] as int,
      rawG: fields[5] as int,
      rawB: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DotReading obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.dotId)
      ..writeByte(1)
      ..write(obj.hue)
      ..writeByte(2)
      ..write(obj.saturation)
      ..writeByte(3)
      ..write(obj.value)
      ..writeByte(4)
      ..write(obj.rawR)
      ..writeByte(5)
      ..write(obj.rawG)
      ..writeByte(6)
      ..write(obj.rawB);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DotReadingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_model.dart';

// **************************************************************************
// HiveAdapter
// **************************************************************************

class RechargeCardAdapter extends TypeAdapter<RechargeCard> {
  @override
  final int typeId = 0;

  @override
  RechargeCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RechargeCard(
      uid: fields[0] as String,
      fullName: fields[1] as String,
      phoneNumber: fields[2] as String,
      balance: (fields[3] as num).toDouble(),
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      rechargeCount: fields[6] as int,
      totalRecharged: (fields[7] as num).toDouble(),
      studentId: fields[8] as String?,
      promotion: fields[9] as String?,
      academicYear: fields[10] as String?,
      faculty: fields[11] as String?,
      program: fields[12] as String?,
      isBlocked: (fields[13] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, RechargeCard obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.fullName)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.balance)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.rechargeCount)
      ..writeByte(7)
      ..write(obj.totalRecharged)
      ..writeByte(8)
      ..write(obj.studentId)
      ..writeByte(9)
      ..write(obj.promotion)
      ..writeByte(10)
      ..write(obj.academicYear)
      ..writeByte(11)
      ..write(obj.faculty)
      ..writeByte(12)
      ..write(obj.program)
      ..writeByte(13)
      ..write(obj.isBlocked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RechargeCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

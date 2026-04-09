import 'package:flutter/foundation.dart';

enum DeviceStatus {
  normalOperation,
  earlyWarning,
  failureDetected,
  maintenanceRequired,
  scheduled,
}

extension DeviceStatusExtension on DeviceStatus {
  String get displayName {
    switch (this) {
      case DeviceStatus.normalOperation:
        return 'Normal';
      case DeviceStatus.earlyWarning:
        return 'Early Warning';
      case DeviceStatus.failureDetected:
        return 'Failure Detected';
      case DeviceStatus.maintenanceRequired:
        return 'Maintenance Required';
      case DeviceStatus.scheduled:
        return 'Scheduled';
    }
  }
}

@immutable
class WashCycle {
  final DateTime date;
  final int durationMinutes;
  final DeviceStatus status;
  final String? diagnosticMessage;

  const WashCycle({
    required this.date,
    required this.durationMinutes,
    this.status = DeviceStatus.normalOperation,
    this.diagnosticMessage,
  });
}

@immutable
class Device {
  final String id;
  final String name;
  final String type;
  final bool isOnline;
  final DeviceStatus status;
  final DateTime lastActivity;
  final List<WashCycle> washCycleHistory;
  final double waterLevel;
  final double temperature;
  final double vibrationLevel;
  final DateTime? scheduledMaintenanceDate;
  
  // New Specification Fields
  final String brand;
  final String modelName;
  final int maxSpinSpeed;
  final double capacity;
  final bool hasHeater;
  final String? diagnosticMessage;

  const Device({
    required this.id,
    required this.name,
    required this.type,
    required this.isOnline,
    required this.status,
    required this.lastActivity,
    this.washCycleHistory = const [],
    required this.waterLevel,
    required this.temperature,
    required this.vibrationLevel,
    this.scheduledMaintenanceDate,
    this.brand = 'Generic',
    this.modelName = 'Model X',
    this.maxSpinSpeed = 800,
    this.capacity = 7.0,
    this.hasHeater = false,
    this.diagnosticMessage,
  });

  Device copyWith({
    String? id,
    String? name,
    String? type,
    bool? isOnline,
    DeviceStatus? status,
    DateTime? lastActivity,
    List<WashCycle>? washCycleHistory,
    double? waterLevel,
    double? temperature,
    double? vibrationLevel,
    DateTime? scheduledMaintenanceDate,
    String? brand,
    String? modelName,
    int? maxSpinSpeed,
    double? capacity,
    bool? hasHeater,
    String? diagnosticMessage,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isOnline: isOnline ?? this.isOnline,
      status: status ?? this.status,
      lastActivity: lastActivity ?? this.lastActivity,
      washCycleHistory: washCycleHistory ?? this.washCycleHistory,
      waterLevel: waterLevel ?? this.waterLevel,
      temperature: temperature ?? this.temperature,
      vibrationLevel: vibrationLevel ?? this.vibrationLevel,
      scheduledMaintenanceDate: scheduledMaintenanceDate ?? this.scheduledMaintenanceDate,
      brand: brand ?? this.brand,
      modelName: modelName ?? this.modelName,
      maxSpinSpeed: maxSpinSpeed ?? this.maxSpinSpeed,
      capacity: capacity ?? this.capacity,
      hasHeater: hasHeater ?? this.hasHeater,
      diagnosticMessage: diagnosticMessage ?? this.diagnosticMessage,
    );
  }
}

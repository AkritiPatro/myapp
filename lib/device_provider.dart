import 'package:flutter/material.dart';
import 'dart:math';
import 'device_model.dart';

class DeviceProvider with ChangeNotifier {
  final List<Device> _devices = [];

  List<Device> get devices => _devices;

  // --- Mock Data Generation ---
  Device _createNewWashingMachine(String name) {
    final random = Random();
    final now = DateTime.now();

    // Generate random historical wash cycles
    final washCycleHistory = List<WashCycle>.generate(
      random.nextInt(15) + 5, // 5 to 20 cycles
      (index) {
        return WashCycle(
          date: now.subtract(Duration(days: random.nextInt(30), hours: random.nextInt(24))),
          durationMinutes: random.nextInt(30) + 30, // 30 to 60 minutes
        );
      },
    )..sort((a, b) => b.date.compareTo(a.date));

    // Determine a random status
    final statusRoll = random.nextDouble();
    DeviceStatus status;
    if (statusRoll < 0.6) { // 60% chance of normal
      status = DeviceStatus.normalOperation;
    } else if (statusRoll < 0.85) { // 25% chance of early warning
      status = DeviceStatus.earlyWarning;
    } else { // 15% chance of maintenance required
      status = DeviceStatus.maintenanceRequired;
    }

    return Device(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: 'Washing Machine',
      isOnline: random.nextBool(),
      status: status,
      lastActivity: now.subtract(Duration(minutes: random.nextInt(120))),
      washCycleHistory: washCycleHistory,
      waterLevel: random.nextDouble() * 100, // Percentage
      temperature: random.nextDouble() * 60 + 20, // 20-80 C
      vibrationLevel: random.nextDouble() * 5, // 0-5 mm/s
      scheduledMaintenanceDate: null,
    );
  }

  // --- Device Management ---

  void addDevice(String name) {
    final newDevice = _createNewWashingMachine(name);
    _devices.add(newDevice);
    notifyListeners();
  }

  void removeDevice(String deviceId) {
    _devices.removeWhere((device) => device.id == deviceId);
    notifyListeners();
  }

  void renameDevice(String deviceId, String newName) {
    try {
      final deviceIndex = _devices.indexWhere((device) => device.id == deviceId);
      if (deviceIndex != -1) {
        final oldDevice = _devices[deviceIndex];
        _devices[deviceIndex] = oldDevice.copyWith(name: newName);
        notifyListeners();
      }
    } catch (e) {
      // Handle error if necessary
    }
  }

  void toggleDeviceStatus(String deviceId) {
     try {
      final deviceIndex = _devices.indexWhere((d) => d.id == deviceId);
      if (deviceIndex != -1) {
         final oldDevice = _devices[deviceIndex];
        _devices[deviceIndex] = oldDevice.copyWith(isOnline: !oldDevice.isOnline);
        notifyListeners();
      }
    } catch (e) {
      // Handle error
    }
  }

  Device? getDeviceById(String deviceId) {
    try {
      return _devices.firstWhere((device) => device.id == deviceId);
    } catch (e) {
      return null; // Return null if not found
    }
  }

  void scheduleMaintenance(String deviceId, DateTime maintenanceDate) {
    try {
      final deviceIndex = _devices.indexWhere((device) => device.id == deviceId);
      if (deviceIndex != -1) {
        final oldDevice = _devices[deviceIndex];
        _devices[deviceIndex] = oldDevice.copyWith(
          status: DeviceStatus.scheduled,
          scheduledMaintenanceDate: maintenanceDate,
        );
        notifyListeners();
      }
    } catch (e) {
      // Handle error
    }
  }
}
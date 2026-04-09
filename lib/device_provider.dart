import 'package:flutter/material.dart';
import 'dart:math';
import 'device_model.dart';
import 'services/catalog_service.dart';
import 'services/maintenance_service.dart';
import 'services/archive_service.dart';

class DeviceProvider with ChangeNotifier {
  final List<Device> _devices = [];
  bool _isInitialized = false;

  List<Device> get devices => _devices;
  bool get isInitialized => _isInitialized;

  // --- Initialization ---
  
  Future<void> initializeData() async {
    if (_isInitialized) return;

    try {
      final catalog = CatalogService();
      await catalog.init();
      
      // Start with 3 realistic devices from the catalog
      final initialDevices = catalog.getRandomDevices(3);
      _devices.addAll(initialDevices);
    } catch (e) {
      debugPrint('Error loading catalog: $e');
    }
    _isInitialized = true;
    notifyListeners();
  }

  // --- Diagnostic Simulation ---

  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  Future<DiagnosticResult?> runAnalytics(String deviceId) async {
    _isAnalyzing = true;
    notifyListeners();

    try {
      final deviceIndex = _devices.indexWhere((d) => d.id == deviceId);
      if (deviceIndex == -1) return null;

      final device = _devices[deviceIndex];
      final archive = ArchiveService();
      
      // DEMO STRATEGY: Use the reliable Healthy file for all scenarios
      // We 'inject' virtual stress if the scenario is a failure
      // This ensures 100% speed and reliability for the major project demo
      final scenarios = [
        {'id': '2_1639574100_1639584900', 'type': 'Normal'},
        {'id': '2_1639574100_1639584900', 'type': 'Heating'},
        {'id': '2_1639574100_1639584900', 'type': 'Bearings'},
      ];
      
      final random = Random();
      final scenario = scenarios[random.nextInt(scenarios.length)];
      final runId = scenario['id']!;
      final scenarioType = scenario['type']!;
      
      final sensorData = await archive.loadRunData(runId);
      
      if (sensorData.isNotEmpty) {
        // Calculate original peaks (95th percentile)
        List<double> allVibs = sensorData.map((e) => e.vibration).toList()..sort();
        double peakVibration = allVibs.sublist((allVibs.length * 0.95).toInt()).reduce((a, b) => a + b) / (allVibs.length * 0.05);
        
        List<double> allPower = sensorData.map((e) => e.power).toList()..sort();
        double maxPower = allPower.sublist((allPower.length * 0.95).toInt()).reduce((a, b) => a + b) / (allPower.length * 0.05);
        
        List<double> allAmps = sensorData.map((e) => e.current).toList()..sort();
        double peakAmps = allAmps.sublist((allAmps.length * 0.95).toInt()).reduce((a, b) => a + b) / (allAmps.length * 0.05);

        // INJECT VIRTUAL STRESS for demo failure variety
        if (scenarioType == 'Heating') {
          maxPower *= 1.8; // Trigger Power Warning
          peakAmps *= 2.5; // Trigger Amp Overload
        } else if (scenarioType == 'Bearings') {
          peakVibration *= 1.6; // Trigger Critical Bearing Limit (~4800)
        }

        // Run Diagnostic Engine
        final result = MaintenanceService().evaluateHealth(
          maxSpinSpeed: device.maxSpinSpeed,
          hasHeater: device.hasHeater,
          currentVibration: peakVibration,
          currentPower: maxPower,
          currentAmps: peakAmps,
        );

        // Create new historical entry
        final newCycle = WashCycle(
          date: DateTime.now(),
          durationMinutes: 45, // Standard diagnostic duration
          status: result.status,
          diagnosticMessage: result.message,
        );
        
        // Update Device State with new history
        _devices[deviceIndex] = device.copyWith(
          status: result.status,
          diagnosticMessage: result.message,
          vibrationLevel: peakVibration,
          temperature: device.hasHeater && maxPower > 1500 ? 90.0 : 40.0, 
          waterLevel: 65.0, // Simulated during cycle
          lastActivity: DateTime.now(),
          washCycleHistory: [...device.washCycleHistory, newCycle],
        );
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('Diagnostic Error: $e');
      return null;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  // --- Device Management ---

  void addDeviceFromCatalog() {
    final catalog = CatalogService();
    final newDevice = catalog.getRandomDevices(1);
    if (newDevice.isNotEmpty) {
      _devices.add(newDevice.first);
      notifyListeners();
    }
  }

  void removeDevice(String deviceId) {
    _devices.removeWhere((device) => device.id == deviceId);
    notifyListeners();
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
      return null;
    }
  }

  void addDevice(String name, {String? brand, String? model}) {
    final catalog = CatalogService();
    Device? newDevice;

    if (brand != null && model != null) {
      final entry = catalog.getSpecificEntry(brand, model);
      if (entry != null) {
        newDevice = catalog.createDeviceFromCatalogEntry(entry);
      }
    }

    // Fallback to random if no specific entry found
    newDevice ??= catalog.getRandomDevices(1).first;

    _devices.add(newDevice.copyWith(name: name));
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
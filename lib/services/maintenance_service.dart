import '../device_model.dart';

class DiagnosticResult {
  final DeviceStatus status;
  final String message;

  DiagnosticResult({required this.status, required this.message});
}

class MaintenanceService {
  static final MaintenanceService _instance = MaintenanceService._internal();
  factory MaintenanceService() => _instance;
  MaintenanceService._internal();

  DiagnosticResult evaluateHealth({
    required int maxSpinSpeed,
    required bool hasHeater,
    required double currentVibration,
    required double currentPower,
    required double currentAmps,
  }) {
    // 1. Check for Critical Mechanical Failure (Bearings)
    // Thresholds recalibrated for specific industrial dataset (baseline noise can reach 3000)
    final double bearingWarningLimit = (maxSpinSpeed / 10) + 3000;
    final double bearingCriticalLimit = (maxSpinSpeed / 5) + 3600;

    if (currentVibration >= 4095) {
      return DiagnosticResult(
        status: DeviceStatus.failureDetected,
        message: 'Critical Mechanical Lock: Sensor saturation at 4095. Immediate safety shutdown triggered. Inspect for internal drum obstructions or complete motor stall.',
      );
    }

    if (currentVibration > bearingCriticalLimit) {
      return DiagnosticResult(
        status: DeviceStatus.maintenanceRequired,
        message: 'Structural Health Alert: Sustained vibration detected at ${currentVibration.toInt()} units. High-frequency resonance indicates drum bearing fatigue; schedule replacement.',
      );
    }
    
    if (currentVibration > bearingWarningLimit) {
      return DiagnosticResult(
        status: DeviceStatus.earlyWarning,
        message: 'Acoustic/Resonant Noise detected. Increasing mechanical stress in high-speed cycle. Verify floor stability and drum alignment.',
      );
    }

    // 2. Check for Electrical / Heating Anomalies
    if (!hasHeater && currentPower > 2200) {
      return DiagnosticResult(
        status: DeviceStatus.earlyWarning,
        message: 'Unusual Power Signature: Non-heated model drawing ${currentPower.toInt()}W. Motor winding overheating or leakage detected.',
      );
    }

    if (currentAmps > 4500) {
      return DiagnosticResult(
        status: DeviceStatus.maintenanceRequired,
        message: 'Amperage Overload: Motor current spike detected. Potential logic board failure or control module short-circuit.',
      );
    }

    // 3. Normal Operation
    return DiagnosticResult(
      status: DeviceStatus.normalOperation,
      message: 'Systems Synchronized: All sensor benchmarks within model-specific resonance limits.',
    );
  }
}

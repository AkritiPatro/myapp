import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';

class SensorReading {
  final double vibration;
  final double current;
  final double power;
  final double timestamp;

  SensorReading({
    required this.vibration,
    required this.current,
    required this.power,
    required this.timestamp,
  });
}

class ArchiveService {
  static final ArchiveService _instance = ArchiveService._internal();
  factory ArchiveService() => _instance;
  ArchiveService._internal();

  Future<List<SensorReading>> loadRunData(String runId) async {
    try {
      final fastRaw = await rootBundle.loadString('assets/archive/${runId}_fast.csv');
      final slowRaw = await rootBundle.loadString('assets/archive/${runId}_slow.csv');

      List<List<dynamic>> fastRows = const CsvToListConverter().convert(fastRaw);
      List<List<dynamic>> slowRows = const CsvToListConverter().convert(slowRaw);

      if (fastRows.isEmpty || slowRows.isEmpty) return [];

      // We only take a sample (100-500 points) to avoid UI lag in major project demo
      List<SensorReading> readings = [];
      
      // Map slow power data for quick lookup by proximity
      // For simplicity in this demo, we'll just use the peak power found in the run
      double peakPower = 0.0;
      for (var row in slowRows.skip(1)) {
        if (row.length >= 2) {
          double p = double.tryParse(row[1].toString()) ?? 0.0;
          if (p > peakPower) peakPower = p;
        }
      }

      // Process fast data
      // Fast CSV: UnixTimestamp (us),Current,Vibration
      int step = (fastRows.length / 200).floor().clamp(1, 1000000);
      
      for (int i = 1; i < fastRows.length; i += step) {
        final row = fastRows[i];
        if (row.length >= 3) {
          readings.add(SensorReading(
            timestamp: double.tryParse(row[0].toString()) ?? 0.0,
            current: double.tryParse(row[1].toString()) ?? 0.0,
            vibration: double.tryParse(row[2].toString()) ?? 0.0,
            power: peakPower, // Simplified for demo
          ));
        }
        if (readings.length >= 200) break;
      }

      return readings;
    } catch (e) {
      print('ArchiveService Error: Failed to load run $runId. Error: $e');
      // Return a safe empty list to prevent crashes in the UI
      return [];
    }
  }
}

import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import '../device_model.dart';
import 'dart:math';

class CatalogService {
  static final CatalogService _instance = CatalogService._internal();
  factory CatalogService() => _instance;
  CatalogService._internal();

  List<Map<String, dynamic>> _catalog = [];
  bool _isInitialized = false;

  // Accurate fallback data synchronized with user's provided table
  static final List<Map<String, dynamic>> _starterCatalog = [
    {'Brand Name': 'LG', 'Model Name': 'FHM1207ZDL', 'Maximum Spin Speed': '1200 rpm', 'Washing Capacity': '7 kg', 'Inbuilt Heater': 'Yes'},
    {'Brand Name': 'Samsung', 'Model Name': 'WW70T4020EE', 'Maximum Spin Speed': '1200 rpm', 'Washing Capacity': '7 kg', 'Inbuilt Heater': 'No'},
    {'Brand Name': 'IFB', 'Model Name': 'Senator WSS', 'Maximum Spin Speed': '1400 rpm', 'Washing Capacity': '8 kg', 'Inbuilt Heater': 'Yes'},
    {'Brand Name': 'Bosch', 'Model Name': 'WAJ24267IN', 'Maximum Spin Speed': '1200 rpm', 'Washing Capacity': '7 kg', 'Inbuilt Heater': 'Yes'},
    {'Brand Name': 'Whirlpool', 'Model Name': 'White Knight', 'Maximum Spin Speed': '800 rpm', 'Washing Capacity': '6.5 kg', 'Inbuilt Heater': 'No'},
    {'Brand Name': 'LG', 'Model Name': 'T70SJSF1Z', 'Maximum Spin Speed': '700 rpm', 'Washing Capacity': '7 kg', 'Inbuilt Heater': 'No'},
    {'Brand Name': 'Samsung', 'Model Name': 'WA70A4002GS', 'Maximum Spin Speed': '680 rpm', 'Washing Capacity': '7 kg', 'Inbuilt Heater': 'No'},
    {'Brand Name': 'IFB', 'Model Name': 'Elite Plus', 'Maximum Spin Speed': '1400 rpm', 'Washing Capacity': '7.5 kg', 'Inbuilt Heater': 'Yes'},
    {'Brand Name': 'BPL', 'Model Name': 'BWM70', 'Maximum Spin Speed': '800 rpm', 'Washing Capacity': '7 kg', 'Inbuilt Heater': 'No'},
    {'Brand Name': 'Panasonic', 'Model Name': 'NA-F70L9HRB', 'Maximum Spin Speed': '720 rpm', 'Washing Capacity': '7 kg', 'Inbuilt Heater': 'No'},
    {'Brand Name': 'Lloyd', 'Model Name': 'LWMT70G', 'Maximum Spin Speed': '750 rpm', 'Washing Capacity': '7 kg', 'Inbuilt Heater': 'No'},
    {'Brand Name': 'Haier', 'Model Name': 'HWM70', 'Maximum Spin Speed': '800 rpm', 'Washing Capacity': '7 kg', 'Inbuilt Heater': 'No'},
    {'Brand Name': 'Godrej', 'Model Name': 'WT EON', 'Maximum Spin Speed': '700 rpm', 'Washing Capacity': '7 kg', 'Inbuilt Heater': 'No'},
    {'Brand Name': 'Onida', 'Model Name': 'T70CGW', 'Maximum Spin Speed': '750 rpm', 'Washing Capacity': '7 kg', 'Inbuilt Heater': 'No'},
    {'Brand Name': 'Toshiba', 'Model Name': 'T-07', 'Maximum Spin Speed': '700 rpm', 'Washing Capacity': '7 kg', 'Inbuilt Heater': 'No'},
    {'Brand Name': 'LG', 'Model Name': 'VIVACE V5', 'Maximum Spin Speed': '1400 rpm', 'Washing Capacity': '9 kg', 'Inbuilt Heater': 'Yes'},
    {'Brand Name': 'Samsung', 'Model Name': 'EcoBubble', 'Maximum Spin Speed': '1400 rpm', 'Washing Capacity': '8 kg', 'Inbuilt Heater': 'Yes'},
    {'Brand Name': 'Bosch', 'Model Name': 'Series 6', 'Maximum Spin Speed': '1200 rpm', 'Washing Capacity': '8 kg', 'Inbuilt Heater': 'Yes'},
    {'Brand Name': 'IFB', 'Model Name': 'Diva Aqua', 'Maximum Spin Speed': '800 rpm', 'Washing Capacity': '6 kg', 'Inbuilt Heater': 'No'},
    {'Brand Name': 'Whirlpool', 'Model Name': 'Stainwash Pro', 'Maximum Spin Speed': '740 rpm', 'Washing Capacity': '7.5 kg', 'Inbuilt Heater': 'Yes'},
  ];

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final rawData = await rootBundle.loadString('assets/data/Washingmachine.csv');
      List<List<dynamic>> rows = const CsvToListConverter().convert(rawData);
      
      if (rows.length > 1) {
        final headers = rows[0].map((e) => e.toString()).toList();
        _catalog = rows.skip(1).map((row) {
          final map = <String, dynamic>{};
          for (int i = 0; i < headers.length; i++) {
            if (i < row.length) {
              map[headers[i]] = row[i];
            }
          }
          return map;
        }).toList();
      }
    } catch (e) {
      debugPrint('Error loading catalog: $e');
    } finally {
      // Always ensure we have at least the starter catalog
      if (_catalog.isEmpty) {
        _catalog = List.from(_starterCatalog);
      }
      _isInitialized = true;
    }
  }

  Device _generateRandomDevice() {
    final random = Random();
    // Pick from catalog (which now always has at least starter data)
    final entry = _catalog[random.nextInt(_catalog.length)];
    return createDeviceFromCatalogEntry(entry);
  }

  Device createDeviceFromCatalogEntry(Map<String, dynamic> entry) {
    final random = Random();
    final now = DateTime.now();

    // Parse specs from CSV
    final String brand = entry['Brand Name']?.toString() ?? 'Generic';
    final String model = entry['Model Name']?.toString() ?? 'Model X';
    
    // Parse Spin Speed
    final String rawSpin = entry['Maximum Spin Speed']?.toString() ?? '800';
    final int spinSpeed = int.tryParse(rawSpin.replaceAll(RegExp(r'[^0-9]'), '')) ?? 800;

    // Parse Capacity
    final String rawCap = entry['Washing Capacity']?.toString() ?? '7';
    final double capacity = double.tryParse(rawCap.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 7.0;

    final bool hasHeater = entry['Inbuilt Heater']?.toString().toLowerCase() == 'yes';

    return Device(
      id: '${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1000)}',
      name: '$brand $model',
      type: 'Washing Machine',
      isOnline: true,
      status: DeviceStatus.normalOperation,
      lastActivity: now,
      waterLevel: 15.0 + random.nextDouble() * 5.0,
      temperature: 22.0 + random.nextDouble() * 5.0,
      vibrationLevel: 180.0 + random.nextDouble() * 10.0,
      brand: brand,
      modelName: model,
      maxSpinSpeed: spinSpeed,
      capacity: capacity,
      hasHeater: hasHeater,
      washCycleHistory: [
        WashCycle(
          date: now.subtract(const Duration(days: 1)),
          durationMinutes: 45,
          status: DeviceStatus.normalOperation,
          diagnosticMessage: 'Factory Quality Audit: All mechanical and electrical subsystems cleared for distribution.',
        ),
      ],
      diagnosticMessage: 'Idle Monitoring: Sensors synchronized at baseline resonance. Systems ready for wash cycle.',
    );
  }

  List<Device> getRandomDevices(int count) {
    // If not initialized yet, use starter catalog immediately
    final activeCatalog = _isInitialized ? _catalog : _starterCatalog;
    final random = Random();
    final List<Device> devices = [];
    
    for (int i = 0; i < count; i++) {
      final entry = activeCatalog[random.nextInt(activeCatalog.length)];
      devices.add(createDeviceFromCatalogEntry(entry));
    }
    return devices;
  }

  // New methods for structured selection
  List<String> getUniqueBrands() {
    final activeCatalog = _isInitialized ? _catalog : _starterCatalog;
    return activeCatalog.map((e) => e['Brand Name']?.toString() ?? 'Generic').toSet().toList()..sort();
  }

  List<String> getModelsForBrand(String brand) {
    final activeCatalog = _isInitialized ? _catalog : _starterCatalog;
    return activeCatalog
        .where((e) => e['Brand Name'] == brand)
        .map((e) => e['Model Name']?.toString() ?? 'Model X')
        .toList()..sort();
  }

  Map<String, dynamic>? getSpecificEntry(String brand, String model) {
    final activeCatalog = _isInitialized ? _catalog : _starterCatalog;
    try {
      return activeCatalog.firstWhere(
        (e) => e['Brand Name'] == brand && e['Model Name'] == model,
      );
    } catch (_) {
      return null;
    }
  }
}

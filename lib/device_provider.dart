import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class DeviceProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> get devices => _devices;
  StreamSubscription? _devicesSubscription;

  DeviceProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        loadDevices(user.uid);
      } else {
        _devices = [];
        _devicesSubscription?.cancel();
        notifyListeners();
      }
    });
  }

  void loadDevices(String userId) {
    _devicesSubscription?.cancel();
    _devicesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('devices')
        .snapshots()
        .listen((snapshot) {
      _devices = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
      notifyListeners();
    });
  }

  Map<String, dynamic>? getDeviceById(String deviceId) {
    try {
      return _devices.firstWhere((device) => device['id'] == deviceId);
    } catch (e) {
      return null; // Return null if no device is found
    }
  }

  // THIS IS THE CORRECTED FUNCTION
  void addDevice(String name) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .add({
        'name': name.trim(),
        'status': 'Offline', // Default status
        'lastActivity': DateTime.now().toIso8601String(), // Default timestamp
        // Add any other default fields your device needs
      });
    }
  }

  void removeDevice(String deviceId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(deviceId)
          .delete();
    }
  }

  void renameDevice(String deviceId, String newName) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(deviceId)
          .update({'name': newName});
    }
  }

  void toggleDeviceStatus(String deviceId, String currentStatus) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(deviceId)
          .update({
        'status': currentStatus == 'Online' ? 'Offline' : 'Online',
        'lastActivity': DateTime.now().toIso8601String(),
      });
    }
  }
}

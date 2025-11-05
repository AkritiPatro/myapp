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

  void addDevice(String name) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Clean the name string before adding to Firestore (as discussed for potential garbled text)
      String cleanedName = name.replaceAll(RegExp(r'\s+'), ' ').trim(); 

      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .add({
        'name': cleanedName, // Use the cleaned name
        'status': 'Offline', // <--- CHANGED TO OFFLINE BY DEFAULT
        'lastActivity': DateTime.now().toIso8601String(),
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

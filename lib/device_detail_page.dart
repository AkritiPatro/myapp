import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'device_provider.dart';
import 'theme_provider.dart';

class DeviceDetailPage extends StatelessWidget {
  final String deviceId;

  const DeviceDetailPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final device = deviceProvider.devices.firstWhere((d) => d['id'] == deviceId);
    final isDark = themeProvider.isDarkMode;

    Color onlineColor = isDark ? Colors.greenAccent : Colors.green;
    Color offlineColor = isDark ? Colors.redAccent : Colors.red;
    Color textColor = isDark ? Colors.white : Colors.black87;
    Color subTextColor = isDark ? Colors.white70 : Colors.grey[600]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          device['name'],
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        centerTitle: true,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny : Icons.nightlight_round,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      backgroundColor: isDark ? Colors.black87 : Colors.grey[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices,
              size: 100,
              color: device['status'] == 'Online' ? onlineColor : offlineColor,
            ),
            SizedBox(height: 20),
            Text(
              device['name'],
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
            ),
            SizedBox(height: 10),
            Text(
              "Status: ${device['status']}",
              style: TextStyle(
                  fontSize: 18,
                  color: device['status'] == 'Online'
                      ? onlineColor
                      : offlineColor),
            ),
            SizedBox(height: 10),
            Text(
              "Last active ${timeAgo(DateTime.parse(device['lastActivity']))}",
              style: TextStyle(fontSize: 16, color: subTextColor),
            ),
            SizedBox(height: 30),
            Switch(
              value: device['status'] == 'Online',
              activeThumbColor: onlineColor,
              onChanged: (value) {
                deviceProvider.toggleDeviceStatus(deviceId, device['status']);
                Fluttertoast.showToast(
                  msg:
                  "${device['name']} turned ${value ? "On ✅" : "Off ⛔"}",
                  backgroundColor: value ? onlineColor : offlineColor,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to format DateTime into "time ago" style
String timeAgo(DateTime dateTime) {
  final Duration diff = DateTime.now().difference(dateTime);

  if (diff.inSeconds < 60) return "just now";
  if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
  if (diff.inHours < 24) return "${diff.inHours} hr ago";
  if (diff.inDays == 1) return "yesterday";
  return "${diff.inDays} days ago";
}

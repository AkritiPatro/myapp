
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'device_provider.dart';
import 'theme_provider.dart';

class DeviceDetailPage extends StatelessWidget {
  final String deviceId;

  const DeviceDetailPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('Device Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Colors.black, Colors.grey.shade900]
                : [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: Consumer<DeviceProvider>(
          builder: (context, deviceProvider, child) {
            final device = deviceProvider.getDeviceById(deviceId);

            if (device == null) {
              return Center(
                child: Text('Device not found.', style: GoogleFonts.poppins()),
              );
            }

            final String deviceName = device['name']?.toString() ?? 'Unnamed Device';
            final String deviceStatus = device['status']?.toString() ?? 'Unknown';
            final Color textColor = isDark ? Colors.white : Colors.black87;

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Card(
                  elevation: 12,
                  shadowColor: isDark ? Colors.purple.withAlpha(100) : Colors.deepPurple.withAlpha(100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: isDark
                            ? [Colors.grey.shade800, Colors.grey.shade900]
                            : [Colors.white, Colors.grey.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: isDark ? Colors.purple : Colors.deepPurple,
                              child: const Icon(
                                Icons.power_settings_new,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Text(
                                deviceName,
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        _buildDetailRow(
                          context,
                          'Status',
                          deviceStatus,
                          Switch(
                            value: deviceStatus == 'Online',
                            onChanged: (value) {
                              deviceProvider.toggleDeviceStatus(
                                deviceId,
                                deviceStatus,
                              );
                              Fluttertoast.showToast(
                                msg: '$deviceName turned ${value ? "On" : "Off"}',
                              );
                            },
                            activeThumbColor: isDark ? Colors.purpleAccent : Colors.deepPurple,
                            trackColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return isDark ? Colors.purple.withAlpha(100) : Colors.deepPurple.withAlpha(100);
                              }
                              return null;
                            }),
                          ),
                          isDark,
                        ),
                        const Divider(),
                        _buildDetailRow(
                          context,
                          'Last Activity',
                          timeAgo(device['lastActivity'] as String?),
                          null, // No trailing widget
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String title, String value, Widget? trailing, bool isDark) {
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white70 : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (trailing == null)
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: subTextColor,
              ),
            ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

String timeAgo(String? dateTimeStr) {
  if (dateTimeStr == null || dateTimeStr.isEmpty) {
    return "a while ago";
  }
  final dateTime = DateTime.tryParse(dateTimeStr);
  if (dateTime == null) return "a while ago";
  final Duration diff = DateTime.now().difference(dateTime);

  if (diff.inSeconds < 60) return "just now";
  if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
  if (diff.inHours < 24) return "${diff.inHours} hr ago";
  if (diff.inDays == 1) return "yesterday";
  return "${diff.inDays} days ago";
}

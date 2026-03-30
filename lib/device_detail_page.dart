import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'device_provider.dart';
import 'device_model.dart';
import 'theme_provider.dart';

class DeviceDetailScreen extends StatelessWidget {
  final String deviceId;

  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text("Device Details",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 1,
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, deviceProvider, child) {
          final device = deviceProvider.getDeviceById(deviceId);

          if (device == null) {
            return const Center(
              child: Text("Device not found. It may have been deleted."),
            );
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Colors.black, Colors.grey.shade900]
                    : [Colors.grey.shade200, Colors.white],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildDeviceHeader(context, device, isDark),
                const SizedBox(height: 20),
                _buildStatusCard(context, device, deviceProvider, isDark),
                const SizedBox(height: 20),
                _buildParametersGrid(context, device, isDark),
                const SizedBox(height: 20),
                _buildWashHistoryCard(context, device, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeviceHeader(BuildContext context, Device device, bool isDark) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: isDark ? Colors.purple : Colors.deepPurple,
            child: const Icon(Icons.local_laundry_service,
                size: 40, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            device.name,
            style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87),
          ),
          Text(
            device.type,
            style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
      BuildContext context, Device device, DeviceProvider provider, bool isDark) {
    Color statusColor;
    String statusMessage;
    IconData statusIcon;

    switch (device.status) {
      case DeviceStatus.normalOperation:
        statusColor = Colors.green.shade400;
        statusMessage = "Normal Operation";
        statusIcon = Icons.check_circle_outline;
        break;
      case DeviceStatus.earlyWarning:
        statusColor = Colors.orange.shade400;
        statusMessage = "Early Warning Detected";
        statusIcon = Icons.warning_amber_rounded;
        break;
      case DeviceStatus.maintenanceRequired:
      case DeviceStatus.failureDetected:
        statusColor = Colors.red.shade400;
        statusMessage = "Maintenance Required";
        statusIcon = Icons.error_outline_rounded;
        break;
      case DeviceStatus.scheduled:
        statusColor = Colors.blue.shade400;
        statusMessage = "Maintenance Scheduled";
        statusIcon = Icons.calendar_today_rounded;
        break;
    }

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Color.lerp(statusColor, Colors.black, 0.6) : statusColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  statusMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            if (device.status == DeviceStatus.scheduled &&
                device.scheduledMaintenanceDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  "Date: ${DateFormat.yMMMd().format(device.scheduledMaintenanceDate!)}",
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                ),
              ),
            if (device.status == DeviceStatus.earlyWarning ||
                device.status == DeviceStatus.maintenanceRequired ||
                device.status == DeviceStatus.failureDetected)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: const Text("Schedule Maintenance"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: statusColor,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      provider.scheduleMaintenance(device.id, pickedDate);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParametersGrid(BuildContext context, Device device, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade600;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildInfoCard(
            isDark,
            Icons.water_drop_outlined,
            "Water Level",
            "${device.waterLevel.toStringAsFixed(1)}%",
            subTextColor,
            textColor),
        _buildInfoCard(
            isDark,
            Icons.thermostat_outlined,
            "Temperature",
            "${device.temperature.toStringAsFixed(1)} °C",
            subTextColor,
            textColor),
        _buildInfoCard(
            isDark,
            Icons.vibration_outlined,
            "Vibration",
            "${device.vibrationLevel.toStringAsFixed(2)} mm/s",
            subTextColor,
            textColor),
        _buildInfoCard(
            isDark,
            device.isOnline ? Icons.wifi : Icons.wifi_off,
            "Connectivity",
            device.isOnline ? "Online" : "Offline",
            subTextColor,
            textColor),
      ],
    );
  }

  Widget _buildInfoCard(bool isDark, IconData icon, String title, String value,
      Color subTextColor, Color textColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon,
                size: 32,
                color: isDark ? Colors.purple.shade200 : Colors.deepPurple),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 14, color: subTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWashHistoryCard(BuildContext context, Device device, bool isDark) {
    final textColor = isDark ? Colors.white70 : Colors.black54;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Wash Cycle History",
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final index = value.toInt();
                          String text = '';
                          if (index >= 0 &&
                              index < device.washCycleHistory.length) {
                            final cycle = device.washCycleHistory[index];
                            text = DateFormat.Md().format(cycle.date);
                          }
                          return SideTitleWidget(
                            meta: meta, // FIXED: Required meta parameter
                            space: 4,
                            child: Text(text,
                                style:
                                    TextStyle(fontSize: 10, color: textColor)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35, // Increased slightly for 'm' unit
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return SideTitleWidget(
                            meta: meta, // FIXED: Required meta parameter
                            space: 4,
                            child: Text(
                              '${value.toInt()}m',
                              style: TextStyle(fontSize: 10, color: textColor),
                              textAlign: TextAlign.left,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 15,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: device.washCycleHistory
                      .take(7)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final cycle = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: cycle.durationMinutes.toDouble(),
                          color: isDark
                              ? Colors.purple.shade300
                              : Colors.deepPurple,
                          width: 12,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
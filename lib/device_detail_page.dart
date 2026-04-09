import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'device_model.dart';
import 'theme_provider.dart';
import 'device_provider.dart';
import 'history_chart.dart'; // Use our custom chart instead of fl_chart
import 'services/maintenance_service.dart';

import 'package:go_router/go_router.dart';

class DeviceDetailScreen extends StatelessWidget {
  final String deviceId;

  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, child) {
        final device = deviceProvider.getDeviceById(deviceId);

        if (device == null) {
          return const Scaffold(
            body: Center(
              child: Text("Device not found. It may have been deleted."),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text("Device Details",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            centerTitle: true,
            elevation: 1,
            actions: [
              IconButton(
                icon: const Icon(Icons.auto_awesome, color: Colors.deepPurple),
                onPressed: () {
                  context.go('/chatbot?deviceId=${device.brand} ${device.modelName}');
                },
                tooltip: 'Ask AI Assistant',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Container(
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
                const SizedBox(height: 10),
                if (device.diagnosticMessage != null)
                  _buildDiagnosticMessage(device.diagnosticMessage!, isDark),
                const SizedBox(height: 20),
                _buildAnalyticsButton(context, deviceProvider, device.id, isDark),
                const SizedBox(height: 20),
                _buildSpecificationsCard(device, isDark),
                const SizedBox(height: 20),
                _buildParametersGrid(context, device, isDark),
                const SizedBox(height: 20),
                _buildWashHistoryCard(context, device, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiagnosticMessage(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.purple.withValues(alpha: 0.2) : Colors.deepPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.purple.shade300 : Colors.deepPurple, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: isDark ? Colors.purple.shade200 : Colors.deepPurple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsButton(BuildContext context, DeviceProvider provider, String deviceId, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: provider.isAnalyzing 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.analytics_outlined),
        label: Text(provider.isAnalyzing ? "Analyzing Archive Data..." : "Run Smart Analytics"),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: isDark ? Colors.tealAccent.shade400 : Colors.deepPurple,
          foregroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: provider.isAnalyzing ? null : () async {
          final result = await provider.runAnalytics(deviceId);
          if (result != null && context.mounted) {
            _showDiagnosticResult(context, result, isDark);
          }
        },
      ),
    );
  }

  void _showDiagnosticResult(BuildContext context, DiagnosticResult result, bool isDark) {
    final statusColor = result.status == DeviceStatus.normalOperation 
        ? Colors.green 
        : (result.status == DeviceStatus.earlyWarning ? Colors.orange : Colors.red);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              result.status == DeviceStatus.normalOperation ? Icons.check_circle : Icons.warning,
              color: statusColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Diagnostic Verdict",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result.status.displayName.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              result.message,
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "UNDERSTOOD",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.tealAccent : Colors.deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationsCard(Device device, bool isDark) {
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Machine Specifications", 
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            const Divider(),
            const SizedBox(height: 8),
            _buildSpecRow("Brand", device.brand, Icons.branding_watermark_outlined, isDark),
            _buildSpecRow("Model", device.modelName, Icons.model_training, isDark),
            _buildSpecRow("Max Spin", "${device.maxSpinSpeed} RPM", Icons.speed, isDark),
            _buildSpecRow("Capacity", "${device.capacity} kg", Icons.fitness_center, isDark),
            _buildSpecRow("Inbuilt Heater", device.hasHeater ? "Yes" : "No", Icons.heat_pump_outlined, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? Colors.tealAccent : Colors.deepPurple),
          const SizedBox(width: 10),
          Text("$label:", style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey.shade600)),
          const Spacer(),
          Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ],
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
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87),
          ),
          Text(
            "Washing Machine",
            style: GoogleFonts.poppins(
                fontSize: 14,
                letterSpacing: 1.2,
                color: isDark ? Colors.tealAccent : Colors.deepPurple),
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
      case DeviceStatus.failureDetected:
        statusColor = Colors.red.shade900;
        statusMessage = "Critical Failure";
        statusIcon = Icons.dangerous_outlined;
        break;
      case DeviceStatus.maintenanceRequired:
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
                Expanded(
                  child: Text(
                    statusMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
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
    final primaryColor = isDark ? Colors.purple : Colors.deepPurple;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade600;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
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
            "${device.vibrationLevel.toInt()} / 4095",
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
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWashHistoryCard(BuildContext context, Device device, bool isDark) {
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
              "Diagnostic & Health History",
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87),
            ),
            if (device.washCycleHistory.isNotEmpty && device.washCycleHistory.every((c) => c.status == DeviceStatus.normalOperation))
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "Healthy Baseline Established",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.tealAccent.shade200 : Colors.teal.shade700,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180, // Reduced slightly to make room for the list
              child: WashHistoryChart(
                history: device.washCycleHistory,
                isDark: isDark,
              ),
            ),
            if (device.washCycleHistory.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                "Recent Diagnostic Runs",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.purple.shade200 : Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 10),
              ...device.washCycleHistory.reversed.take(5).map((cycle) {
                final statusColor = cycle.status == DeviceStatus.normalOperation 
                    ? Colors.green 
                    : (cycle.status == DeviceStatus.earlyWarning ? Colors.orange : Colors.red);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('MMM d, hh:mm a').format(cycle.date),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (cycle.diagnosticMessage != null)
                              Text(
                                cycle.diagnosticMessage!,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        cycle.status.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
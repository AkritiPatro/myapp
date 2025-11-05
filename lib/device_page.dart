import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'device_provider.dart';
import 'theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  DevicePageState createState() => DevicePageState();
}

class DevicePageState extends State<DevicePage> {
  String? _userName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _userName = userDoc.exists ? userDoc.get('name') : null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final Color lightGrey = Colors.grey.shade300;
    final Color darkGrey = Colors.grey.shade800;
    final Color iconColor = isDark ? Colors.white54 : darkGrey;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _userName != null ? "Welcome, $_userName" : "My Devices",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chatbot',
            onPressed: () {
              context.go('/chatbot');
            },
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny : Icons.nightlight_round,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () {
              Provider.of<ThemeProvider>(
                context,
                listen: false,
              ).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Fluttertoast.showToast(
                msg: "Logged out",
                backgroundColor: Colors.red,
              );
              context.go('/');
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark ? [Colors.black, darkGrey] : [lightGrey, Colors.white],
          ),
        ),
        child:
            deviceProvider.devices.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.devices_other, size: 80, color: iconColor),
                      const SizedBox(height: 20),
                      Text(
                        "No devices yet.",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          color: isDark ? Colors.white70 : darkGrey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Add a new device to get started!",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: isDark ? Colors.white54 : darkGrey,
                        ),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: deviceProvider.devices.length,
                  itemBuilder: (context, index) {
                    final device = deviceProvider.devices[index];
                    final String deviceName =
                        device['name']?.toString() ?? 'Unnamed Device';
                    final String deviceStatus =
                        device['status']?.toString() ?? 'Unknown';
                    final Color subTextColor =
                        isDark ? Colors.white70 : Colors.grey.shade600;

                    return Card(
                      elevation: 8,
                      shadowColor:
                          isDark
                              ? Colors.purple.withAlpha(128)
                              : Colors.deepPurple.withAlpha(128),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors:
                                isDark
                                    ? [darkGrey, darkGrey]
                                    : [Colors.white, lightGrey],
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            context.go('/devices/${device['id']}');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor:
                                      isDark
                                          ? Colors.purple
                                          : Colors.deepPurple,
                                  child: const Icon(
                                    Icons.power,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        deviceName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Status: $deviceStatus • Last active ${timeAgo(device['lastActivity'] as String?)}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: subTextColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 140,
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: deviceStatus == 'Online',
                                        onChanged: (value) {
                                          deviceProvider.toggleDeviceStatus(
                                            device['id'],
                                            deviceStatus,
                                          );
                                          Fluttertoast.showToast(
                                            msg:
                                                "$deviceName turned ${value ? "On" : "Off"}",
                                          );
                                        },
                                        activeThumbColor: Colors.purple,
                                      ),
                                      SizedBox(
                                        width: 32,
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: textColor,
                                            size: 20,
                                          ),
                                          onPressed:
                                              () => _showRenameDialog(
                                                context,
                                                deviceProvider,
                                                device['id'],
                                                deviceName,
                                              ),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 32,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                            size: 20,
                                          ),
                                          onPressed:
                                              () => _showDeleteDialog(
                                                context,
                                                deviceProvider,
                                                device['id'],
                                                deviceName,
                                              ),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ],
                                  ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddDeviceDialog(context, deviceProvider);
        },
        label: Text(
          "Add Device",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
        backgroundColor: isDark ? Colors.purple : Colors.deepPurple,
        elevation: 8,
        highlightElevation: 16,
      ),
    );
  }

  void _showAddDeviceDialog(BuildContext context, DeviceProvider provider) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Add Device", style: GoogleFonts.poppins()),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: "Device Name"),
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                child: Text("Cancel", style: GoogleFonts.poppins()),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text("Add", style: GoogleFonts.poppins()),
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    provider.addDevice(controller.text);
                    Navigator.pop(context);
                    Fluttertoast.showToast(msg: "New device added!");
                  }
                },
              ),
            ],
          ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    DeviceProvider provider,
    String deviceId,
    String currentName,
  ) {
    final TextEditingController controller = TextEditingController(
      text: currentName,
    );
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Rename Device", style: GoogleFonts.poppins()),
            content: TextField(
              controller: controller,
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                child: Text("Cancel", style: GoogleFonts.poppins()),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text("Save", style: GoogleFonts.poppins()),
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    provider.renameDevice(deviceId, controller.text);
                    Navigator.pop(context);
                  } else {
                    Fluttertoast.showToast(msg: "Device name cannot be empty.");
                  }
                },
              ),
            ],
          ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    DeviceProvider provider,
    String deviceId,
    String deviceName,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Delete Device", style: GoogleFonts.poppins()),
            content: Text(
              "Are you sure you want to delete $deviceName?",
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                child: Text("Cancel", style: GoogleFonts.poppins()),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text(
                  "Delete",
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
                onPressed: () {
                  provider.removeDevice(deviceId);
                  Navigator.pop(context);
                },
              ),
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
  if (dateTime == null) return "a while ago"; // Handle potential parse error
  final Duration diff = DateTime.now().difference(dateTime);

  if (diff.inSeconds < 60) return "just now";
  if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
  if (diff.inHours < 24) return "${diff.inHours} hr ago";
  if (diff.inDays == 1) return "yesterday";
  return "${diff.inDays} days ago";
}

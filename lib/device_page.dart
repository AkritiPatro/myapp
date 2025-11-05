import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'device_provider.dart';
import 'theme_provider.dart';
import 'device_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  _DevicePageState createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  String? _userName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          // Safely access the 'name' field
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
          // Chatbot button
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/chatbot');
            },
            tooltip: 'Chat with AI Assistant',
          ),
          // Existing theme toggle
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          // Existing logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Fluttertoast.showToast(
                msg: "Logged out",
                backgroundColor: Colors.red,
              );
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [Colors.black, darkGrey] : [lightGrey, Colors.white],
          ),
        ),
        child: deviceProvider.devices.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.devices_other,
                      size: 80,
                      color: iconColor,
                    ),
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
                  final String deviceName = device['name']?.toString() ?? 'Unnamed Device';
                  final String deviceStatus = device['status']?.toString() ?? 'Unknown';
                  final Color subTextColor = isDark ? Colors.white70 : Colors.grey.shade600;

                  return Card(
                    elevation: 8,
                    shadowColor: isDark
                        ? Colors.purple.withOpacity(0.5)
                        : Colors.deepPurple.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: isDark
                              ? [darkGrey, darkGrey]
                              : [Colors.white, lightGrey],
                        ),
                      ),
                      // **Manual Layout using InkWell/Row/Column for maximum control**
                      child: InkWell( // Provides touch ripple effect
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DeviceDetailPage(
                                deviceId: device['id'],
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 1. LEADING ICON
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: isDark ? Colors.purple : Colors.deepPurple,
                                child: const Icon(Icons.power, color: Colors.white),
                              ),

                              const SizedBox(width: 16),
                              
                              // 2. TEXT CONTENT (Guaranteed maximum space via Expanded)
                              Expanded( // Takes all available space not used by fixed elements
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Device Name - maxLines: 1 forces truncation if too long
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
                                    
                                    // Status & Last Activity - maxLines: 1 keeps card height minimal
                                    const SizedBox(height: 4),
                                    Text(
                                      "Status: $deviceStatus \u2022 Last active ${timeAgo(device['lastActivity'])}", 
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
                              
                              // 3. ACTION BUTTONS (Fixed Width Constraint)
                              // This prevents the buttons from flowing off-screen or squeezing the text.
                              Container(
                                width: 140, // Fixed width for the actions section
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min, // Essential to keep the Row tight
                                  children: [
                                    // Switch
                                    Switch(
                                      value: deviceStatus == 'Online',
                                      onChanged: (value) {
                                        deviceProvider.toggleDeviceStatus(
                                          device['id'],
                                          deviceStatus,
                                        );
                                        Fluttertoast.showToast(
                                          msg: "$deviceName turned ${value ? "On" : "Off"}",
                                        );
                                      },
                                      activeThumbColor: Colors.purple,
                                    ),
                                    
                                    // Edit Icon (Controlled width)
                                    SizedBox(
                                      width: 32, 
                                      child: IconButton(
                                        icon: Icon(Icons.edit, color: textColor, size: 20),
                                        onPressed: () => _showRenameDialog(
                                          context, deviceProvider, device['id'], deviceName,
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                    
                                    // Delete Icon (Controlled width)
                                    SizedBox(
                                      width: 32, 
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        onPressed: () => _showDeleteDialog(
                                          context, deviceProvider, device['id'], deviceName,
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

  // --- Dialog methods (unchanged) ---

  void _showAddDeviceDialog(BuildContext context, DeviceProvider provider) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
      builder: (_) => AlertDialog(
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
      builder: (_) => AlertDialog(
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

String timeAgo(String dateTimeStr) {
  final dateTime = DateTime.parse(dateTimeStr);
  final Duration diff = DateTime.now().difference(dateTime);

  if (diff.inSeconds < 60) return "just now";
  if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
  if (diff.inHours < 24) return "${diff.inHours} hr ago";
  if (diff.inDays == 1) return "yesterday";
  return "${diff.inDays} days ago";
}
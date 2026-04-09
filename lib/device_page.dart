import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'device_provider.dart';
import 'theme_provider.dart';
import 'device_model.dart'; // Import the device model
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/catalog_service.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  DevicePageState createState() => DevicePageState();
}

class DevicePageState extends State<DevicePage> {
  String? _userName;
  String? _userRole; // Added to track role

  @override
  void initState() {
    super.initState();
    // Fetch user name as soon as they become authenticated (especially for web refresh)
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && mounted) {
        _fetchUserName();
      }
    });
  }

  Future<void> _fetchUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? name = user.displayName;

      // Fallback 1: Firestore doc
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          name = data['name'];
          if (mounted) {
            setState(() {
              _userRole = data['role'] ?? "user";
            });
          }
        }
      } catch (e) {
        debugPrint('Error fetching user name/role: $e');
      }

      // Fallback 2: Email prefix
      if (name == null || name.isEmpty || name == "User") {
        final email = user.email;
        if (email != null && email.contains('@')) {
          name = email.split('@')[0];
        }
      }

      if (mounted) {
        setState(() {
          _userName = name ?? "User";
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
        toolbarHeight: 70, // Increased height for better visibility in Desktop Mode
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              "Welcome, ${_userName ?? "User"}",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
        ),
        centerTitle: false,
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
          PopupMenuButton<String>(
            icon: Icon(
              Icons.account_circle,
              color: isDark ? Colors.tealAccent : Colors.white,
              size: 28,
            ),
            tooltip: 'Account Settings',
            onSelected: (value) {
              if (value == 'admin') {
                context.go('/admin/users');
              } else if (value == 'logout') {
                FirebaseAuth.instance.signOut();
                Fluttertoast.showToast(msg: "Logged out", backgroundColor: Colors.red);
                context.go('/');
              } else if (value == 'delete') {
                _showDeleteAccountDialog(context, isDark);
              }
            },
            itemBuilder: (context) => [
              if (_userRole == 'admin')
                PopupMenuItem(
                  value: 'admin',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: isDark ? Colors.amber : Colors.orange),
                      const SizedBox(width: 12),
                      Text('Admin Panel', style: GoogleFonts.poppins()),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: isDark ? Colors.tealAccent : Colors.deepPurple),
                    const SizedBox(width: 12),
                    Text('Logout', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_forever, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Text('Delete Account', style: GoogleFonts.poppins(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
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
        child: deviceProvider.devices.isEmpty
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
                  final Color subTextColor =
                      isDark ? Colors.white70 : Colors.grey.shade600;

                  return Card(
                    elevation: 8,
                    shadowColor: isDark
                        ? Colors.purple.withAlpha(128)
                        : Colors.deepPurple.withAlpha(128),
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
                      child: InkWell(
                        onTap: () {
                          context.go('/devices/${device.id}');
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
                                backgroundColor: isDark
                                    ? Colors.purple
                                    : Colors.deepPurple,
                                child: const Icon(
                                  Icons.local_laundry_service_outlined,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      device.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                      // Allow wrapping for full name visibility on mobile
                                      overflow: TextOverflow.visible,
                                      softWrap: true,
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      alignment: Alignment.centerLeft,
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "Status: ${device.status.displayName} • Last active ${timeAgo(device.lastActivity)}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: subTextColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 110, // Reduced from 140
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Switch(
                                      value: device.isOnline,
                                      onChanged: (value) {
                                        deviceProvider.toggleDeviceStatus(device.id);
                                        Fluttertoast.showToast(
                                          msg: "${device.name} turned ${value ? "On" : "Off"}",
                                        );
                                      },
                                      activeColor: Colors.purple,
                                    ),
                                    SizedBox(
                                      width: 32,
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: textColor,
                                          size: 20,
                                        ),
                                        onPressed: () => _showRenameDialog(
                                          context,
                                          deviceProvider,
                                          device.id,
                                          device.name,
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
                                        onPressed: () => _showDeleteDialog(
                                          context,
                                          deviceProvider,
                                          device.id,
                                          device.name,
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

  void _showDeleteAccountDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Delete Account",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.tealAccent : Colors.deepPurple,
          ),
        ),
        content: Text(
          "All your devices and data will be permanently removed. You can register again with this email after deletion.",
          style: GoogleFonts.poppins(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "Delete",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Delete Firestore user document
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      // 2. Delete Auth User
      await user.delete();

      Fluttertoast.showToast(msg: "Account deleted successfully ✅", backgroundColor: Colors.green);
      if (context.mounted) {
        if (mounted) context.go('/');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        Fluttertoast.showToast(
          msg: "Please Log Out and Log Back In to delete your account (Security Requirement).",
          backgroundColor: Colors.orange,
          toastLength: Toast.LENGTH_LONG,
        );
      } else {
        Fluttertoast.showToast(msg: "Error: ${e.message}", backgroundColor: Colors.red);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Deletion failed: $e", backgroundColor: Colors.red);
    }
  }

  void _showAddDeviceDialog(BuildContext context, DeviceProvider provider) {
    final TextEditingController nameController = TextEditingController();
    final catalog = CatalogService();
    final brands = catalog.getUniqueBrands();

    String? selectedBrand;
    String? selectedModel;
    List<String> currentModels = [];
    Map<String, dynamic>? selectedSpecs;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return AlertDialog(
            title: Text("Add Your Machine", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedBrand,
                    decoration: InputDecoration(
                      labelText: "Select Brand",
                      labelStyle: GoogleFonts.poppins(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: brands.map((b) => DropdownMenuItem(value: b, child: Text(b, style: GoogleFonts.poppins()))).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedBrand = val;
                        selectedModel = null;
                        selectedSpecs = null;
                        currentModels = catalog.getModelsForBrand(val!);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Model Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedModel,
                    decoration: InputDecoration(
                      labelText: "Select Model",
                      labelStyle: GoogleFonts.poppins(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: currentModels.map((m) => DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.poppins()))).toList(),
                    disabledHint: Text("Pick a brand first", style: GoogleFonts.poppins(fontSize: 12)),
                    onChanged: selectedBrand == null ? null : (val) {
                      setDialogState(() {
                        selectedModel = val;
                        selectedSpecs = catalog.getSpecificEntry(selectedBrand!, val!);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Spec Preview
                  if (selectedSpecs != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.purple.withValues(alpha: 0.1) : Colors.deepPurple.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? Colors.purple : Colors.deepPurple, width: 0.5),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Spin Speed:", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(selectedSpecs!['Maximum Spin Speed']?.toString() ?? 'N/A', style: GoogleFonts.poppins(fontSize: 12)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Capacity:", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(selectedSpecs!['Washing Capacity']?.toString() ?? 'N/A', style: GoogleFonts.poppins(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Nickname Field
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Nickname (optional)",
                      labelStyle: GoogleFonts.poppins(),
                      hintText: "e.g. My LG Washer",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    style: GoogleFonts.poppins(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                onPressed: (selectedBrand != null && selectedModel != null)
                    ? () {
                        final nickname = nameController.text.isEmpty ? "$selectedBrand $selectedModel" : nameController.text;
                        provider.addDevice(nickname, brand: selectedBrand, model: selectedModel);
                        Navigator.pop(context);
                        Fluttertoast.showToast(msg: "Added $nickname to your home! ✅", backgroundColor: Colors.green);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.purple : Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("Register Machine", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
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

String timeAgo(DateTime? dateTime) {
  if (dateTime == null) {
    return "a while ago";
  }
  final Duration diff = DateTime.now().difference(dateTime);

  if (diff.inSeconds < 60) return "just now";
  if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
  if (diff.inHours < 24) return "${diff.inHours}h ago";
  if (diff.inDays == 1) return "yesterday";
  return "${diff.inDays}d ago";
}

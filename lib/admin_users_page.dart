import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'package:intl/intl.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Manage Users",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: isDark ? Colors.black : Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "Search by name or email...",
                hintStyle: TextStyle(color: textColor.withAlpha(128)),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.tealAccent : Colors.deepPurple),
                filled: true,
                fillColor: isDark ? Colors.grey[900] : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),

          // Users List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: textColor)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? "").toString().toLowerCase();
                  final email = (data['email'] ?? "").toString().toLowerCase();
                  return name.contains(_searchQuery) || email.contains(_searchQuery);
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      "No users found.",
                      style: GoogleFonts.poppins(color: textColor.withAlpha(150), fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData = users[index].data() as Map<String, dynamic>;
                    final String userId = users[index].id;
                    final String name = userData['name'] ?? "No Name";
                    final String email = userData['email'] ?? "No Email";
                    final String role = userData['role'] ?? "user";
                    final Timestamp? createdAt = userData['createdAt'] as Timestamp?;
                    
                    return _buildUserCard(context, userId, name, email, role, createdAt, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, String uid, String name, String email, String role, Timestamp? createdAt, bool isDark) {
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final String joinDate = createdAt != null ? DateFormat('MMM d, yyyy').format(createdAt.toDate()) : "Unknown";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: role == 'admin' ? Colors.amber : Colors.deepPurple,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : "?",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    email,
                    style: GoogleFonts.poppins(fontSize: 13, color: textColor.withAlpha(180)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: role == 'admin' ? Colors.amber.withAlpha(50) : Colors.blue.withAlpha(50),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: TextStyle(
                            color: role == 'admin' ? Colors.amber[700] : Colors.blue[700],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Joined $joinDate",
                        style: TextStyle(fontSize: 11, color: textColor.withAlpha(120)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () => _showEditDialog(uid, name, role, isDark),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
              onPressed: () => _showDeleteDialog(uid, name, isDark),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String uid, String currentName, String currentRole, bool isDark) {
    final TextEditingController nameEditController = TextEditingController(text: currentName);
    String selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: Text("Edit User", style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameEditController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Name",
                  labelStyle: TextStyle(color: isDark ? Colors.tealAccent : Colors.deepPurple),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedRole,
                dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text("User")),
                  DropdownMenuItem(value: 'admin', child: Text("Admin")),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedRole = val);
                },
                decoration: InputDecoration(
                  labelText: "Role",
                  labelStyle: TextStyle(color: isDark ? Colors.tealAccent : Colors.deepPurple),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'name': nameEditController.text.trim(),
                  'role': selectedRole,
                });
                if (mounted) Navigator.pop(context);
                Fluttertoast.showToast(msg: "User updated successfully");
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(String uid, String name, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text("Delete User", style: GoogleFonts.poppins(color: Colors.redAccent)),
        content: Text(
          "Are you sure you want to delete profile for $name? This only removes their data from Firestore.",
          style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(uid).delete();
              if (mounted) Navigator.pop(context);
              Fluttertoast.showToast(msg: "User deleted from Firestore");
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

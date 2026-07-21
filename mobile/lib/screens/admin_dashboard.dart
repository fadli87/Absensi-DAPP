import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'add_employee_screen.dart';
import 'edit_employee_screen.dart'; // <-- Diimpor agar bisa membuka form edit

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<List<dynamic>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() {
    setState(() {
      _usersFuture = ApiService.getUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Belum ada data pegawai.'));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(user['name'][0].toUpperCase()),
                  ),
                  title: Text(user['name']),
                  subtitle: Text(user['email']),
                  trailing: Chip(
                    label: Text(user['role']),
                    backgroundColor: user['role'] == 'ADMIN' 
                        ? Colors.red[100] 
                        : Colors.green[100],
                  ),
                  // Saat item diklik, arahkan ke form Edit Karyawan
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditEmployeeScreen(user: user),
                      ),
                    );
                    // Jika berhasil di-update, muat ulang daftar user
                    if (result == true) {
                      _fetchUsers();
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Pindah ke halaman tambah dan refresh daftar jika berhasil
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEmployeeScreen()),
          );
          if (result == true) {
            _fetchUsers();
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
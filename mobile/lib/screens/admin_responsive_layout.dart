import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'add_employee_screen.dart';
import 'edit_employee_screen.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart'; // <-- Diperlukan untuk mengakses halaman absen pegawai
import 'shift_management_screen.dart'; // <-- Halaman manajemen shift baru
import 'department_management_screen.dart';
import 'report_screen.dart';

class AdminResponsiveLayout extends StatefulWidget {
  const AdminResponsiveLayout({Key? key}) : super(key: key);

  @override
  _AdminResponsiveLayoutState createState() => _AdminResponsiveLayoutState();
}

class _AdminResponsiveLayoutState extends State<AdminResponsiveLayout> {
  int _selectedIndex = 0;

  final List<String> _menuTitles = [
    'Manajemen Pegawai',
    'Pengaturan Geofencing',
    'Pengaturan Shift', // <-- Menu baru untuk shift
    'Pengaturan Departemen',
    'Laporan Absensi',

  ];

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 850;

    if (isDesktop) {
      // Jika di Desktop, gunakan Layout Sidebar Kiri
      return _buildDesktopLayout();
    } else {
      // Jika di HP/Mobile, gunakan tampilan Drawer & List yang ramah layar kecil
      return _buildMobileLayout();
    }
  }

// ================= TAMPILAN DESKTOP =================
  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // MEMPERBAIKI ERROR LISTTILE: Ganti Container menjadi Material
          Material(
            color: Color(0xFF0F172A),
            child: SizedBox(
              width: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('DAPP Admin', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  Divider(color: Colors.white24, height: 1),
                  SizedBox(height: 10),
                  _buildSidebarItem(Icons.people, 'Manajemen Pegawai', 0),
                  _buildSidebarItem(Icons.map, 'Pengaturan Geofencing', 1),
                  _buildSidebarItem(Icons.schedule, 'Pengaturan Shift', 2),
                  _buildSidebarItem(Icons.business, 'Pengaturan Departemen', 3), // Hapus komentar ini jika Anda sudah buat menu Departemen
                  _buildSidebarItem(Icons.report, 'Laporan Absensi', 4),
                  Divider(color: Colors.white24, height: 20),
                  
                  // Pintas Menu Absensi untuk Admin di Desktop
                  ListTile(
                    leading: Icon(Icons.camera_alt, color: Colors.blueAccent),
                    title: Text('Menu Absensi Saya', style: TextStyle(color: Colors.white, fontSize: 14)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DashboardScreen()),
                      );
                    },
                  ),

                  Spacer(),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: TextButton.icon(
                      onPressed: () async {
                        await ApiService().logout();
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      icon: Icon(Icons.logout, color: Colors.redAccent),
                      label: Text('Keluar', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Color(0xFFF8FAFC),
              child: Column(
                children: [
                  Container(
                    height: 70,
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_menuTitles[_selectedIndex], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('Administrator (Desktop)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                      ],
                    ),
                  ),
                  Expanded(child: Padding(padding: EdgeInsets.all(24.0), child: _buildActiveContent())),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ================= TAMPILAN MOBILE (HP) =================
  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_menuTitles[_selectedIndex]),
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await ApiService().logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
            },
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0F172A)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('DAPP Admin', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Panel Pengelola (Mobile)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Manajemen Pegawai'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.map),
              title: Text('Pengaturan Geofencing'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.schedule),
              title: Text('Pengaturan Shift'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            Divider(color: Colors.grey[300]),
            // === TAMBAHKAN MENU DEPARTEMEN DI SINI ===
            ListTile(
              leading: Icon(Icons.business),
              title: Text('Pengaturan Departemen'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),
            // === TAMBAHKAN MENU LAPORAN DI SINI ===
            ListTile(
              leading: Icon(Icons.bar_chart),
              title: Text('Laporan Absensi'),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() => _selectedIndex = 4);
                Navigator.pop(context);
              },
            ),
            // =========================================
            Divider(color: Colors.grey[300]),
            
            // Pintas Menu Absensi Khusus Admin di Drawer HP
            ListTile(
              leading: Icon(Icons.camera_alt, color: Color(0xFF2563EB)),
              title: Text(
                'Menu Absensi Saya', 
                style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)
              ),
              subtitle: Text('Check-In / Check-Out (Selfie + GPS)', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context); // Tutup drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        color: Color(0xFFF8FAFC),
        padding: EdgeInsets.all(12.0),
        child: _buildActiveContent(),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return Material(
      color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? Colors.blueAccent : Colors.white70),
              SizedBox(width: 16),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveContent() {
    if (_selectedIndex == 0) {
      return AdminEmployeeListView(); // Tampilan List Pegawai yang ramah HP/Desktop
    } else if (_selectedIndex == 1) {
      return GeofencingSettingsView(); // Form Geofencing
    } else if (_selectedIndex == 2) {
      return ShiftManagementScreen(); // Halaman Shift Kerja baru
    } else if (_selectedIndex == 3) {
      return DepartmentManagementScreen(); // Halaman Departemen baru
    } else {
      return ReportScreen(); // Halaman Laporan Absensi
    }
  }
}

// ================= DAFTAR PEGAWAI VERSI LIST CARD =================
class AdminEmployeeListView extends StatefulWidget {
  const AdminEmployeeListView({Key? key}) : super(key: key);

  @override
  _AdminEmployeeListViewState createState() => _AdminEmployeeListViewState();
}

class _AdminEmployeeListViewState extends State<AdminEmployeeListView> {
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Daftar Pegawai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddEmployeeScreen()));
                if (result == true) _fetchUsers();
              },
              icon: Icon(Icons.add, color: Colors.white, size: 18),
              label: Text('Tambah', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2563EB)),
            ),
          ],
        ),
        SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
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
                  bool isAdmin = user['role'] == 'ADMIN';
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(user['name'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(user['email'] ?? '-'),
                          if (user['department'] != null && user['department'].toString().isNotEmpty) ...[
                            SizedBox(height: 2),
                            Text('Dept: ${user['department']}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          ],
                          SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isAdmin ? Colors.red[100] : Colors.green[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(user['role'], style: TextStyle(fontSize: 11, color: isAdmin ? Colors.red[800] : Colors.green[800], fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditEmployeeScreen(user: user)));
                          if (result == true) _fetchUsers();
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ================= FORM PENGATURAN GEOFENCING RESPONSIF =================
class GeofencingSettingsView extends StatefulWidget {
  const GeofencingSettingsView({Key? key}) : super(key: key);

  @override
  _GeofencingSettingsViewState createState() => _GeofencingSettingsViewState();
}

class _GeofencingSettingsViewState extends State<GeofencingSettingsView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadOfficeData();
  }

  void _loadOfficeData() async {
    try {
      final office = await ApiService.getOfficeLocation();
      setState(() {
        _nameController.text = office['name'] ?? '';
        _latController.text = office['latitude'].toString();
        _lngController.text = office['longitude'].toString();
        _radiusController.text = office['radius'].toString();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data lokasi: $e')));
    }
  }

  void _saveOfficeData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isSaving = true);
      try {
        bool success = await ApiService.updateOfficeLocation(
          _nameController.text,
          double.parse(_latController.text),
          double.parse(_lngController.text),
          int.parse(_radiusController.text),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Geofencing berhasil diperbarui!' : 'Gagal menyimpan.'), backgroundColor: success ? Colors.green : Colors.red),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      } finally {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Center(child: CircularProgressIndicator());

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text('Pengaturan Titik & Radius Kantor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            SizedBox(height: 6),
            Text('Atur batas wilayah geofencing absensi karyawan.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            SizedBox(height: 16),
            TextFormField(controller: _nameController, decoration: InputDecoration(labelText: 'Nama Lokasi Kantor', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextFormField(controller: _latController, decoration: InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()), keyboardType: TextInputType.numberWithOptions(decimal: true)),
            SizedBox(height: 12),
            TextFormField(controller: _lngController, decoration: InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()), keyboardType: TextInputType.numberWithOptions(decimal: true)),
            SizedBox(height: 12),
            TextFormField(controller: _radiusController, decoration: InputDecoration(labelText: 'Radius Maksimal (meter)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSaving ? null : _saveOfficeData,
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2563EB), padding: EdgeInsets.symmetric(vertical: 12)),
              child: isSaving ? CircularProgressIndicator(color: Colors.white) : Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
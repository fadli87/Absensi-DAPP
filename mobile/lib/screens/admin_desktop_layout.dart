import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'add_employee_screen.dart';
import 'edit_employee_screen.dart';

class AdminDesktopLayout extends StatefulWidget {
  const AdminDesktopLayout({Key? key}) : super(key: key);

  @override
  _AdminDesktopLayoutState createState() => _AdminDesktopLayoutState();
}

class _AdminDesktopLayoutState extends State<AdminDesktopLayout> {
  int _selectedIndex = 0;

  final List<String> _menuTitles = [
    'Manajemen Pegawai',
    'Pengaturan Geofencing',
    'Rekap Absensi',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ================= SIDEBAR KIRI =================
          Container(
            width: 260,
            color: Color(0xFF0F172A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'DAPP Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(color: Colors.white24, height: 1),
                SizedBox(height: 10),

                _buildSidebarItem(Icons.people, 'Manajemen Pegawai', 0),
                _buildSidebarItem(Icons.map, 'Pengaturan Geofencing', 1),
                _buildSidebarItem(Icons.assessment, 'Rekap Absensi', 2),

                Spacer(),

                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: TextButton.icon(
                    onPressed: () async {
                      ApiService apiService = ApiService();
                      await apiService.logout();
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    icon: Icon(Icons.logout, color: Colors.redAccent),
                    label: Text('Keluar', style: TextStyle(color: Colors.redAccent)),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      minimumSize: Size(double.infinity, 45),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================= KONTEN UTAMA KANAN =================
          Expanded(
            child: Container(
              color: Color(0xFFF8FAFC),
              child: Column(
                children: [
                  // Top Navbar Desktop
                  Container(
                    height: 70,
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _menuTitles[_selectedIndex],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Text('AD', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                            ),
                            SizedBox(width: 12),
                            Text('Administrator', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Dynamic Body berdasarkan menu yang dipilih
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: _buildMainContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.blueAccent : Colors.white70),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return AdminTableContent(); // Tabel Manajemen Pegawai
      case 1:
        return GeofencingSettingsView(); // Form Pengaturan Geofencing
      case 2:
        return Center(child: Text('Fitur Rekap Absensi (Segera Dibangun)'));
      default:
        return Center(child: Text('Halaman tidak ditemukan'));
    }
  }
}

// ================= KELAS TABEL PEGAWAI DESKTOP =================
class AdminTableContent extends StatefulWidget {
  const AdminTableContent({Key? key}) : super(key: key);

  @override
  _AdminTableContentState createState() => _AdminTableContentState();
}

class _AdminTableContentState extends State<AdminTableContent> {
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Daftar Seluruh Pegawai & Karyawan', style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddEmployeeScreen()),
                );
                if (result == true) _fetchUsers();
              },
              icon: Icon(Icons.add, color: Colors.white),
              label: Text('Tambah Pegawai', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2563EB)),
            ),
          ],
        ),
        SizedBox(height: 20),

        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))],
            ),
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
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Color(0xFFF1F5F9)),
                      columns: const [
                        DataColumn(label: Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: users.map((user) {
                        return DataRow(cells: [
                          DataCell(Text(user['name'] ?? '-')),
                          DataCell(Text(user['email'] ?? '-')),
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: user['role'] == 'ADMIN' ? Colors.red[100] : Colors.green[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user['role'],
                                style: TextStyle(
                                  color: user['role'] == 'ADMIN' ? Colors.red[800] : Colors.green[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => EditEmployeeScreen(user: user)),
                                );
                                if (result == true) _fetchUsers();
                              },
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ================= KELAS PENGATURAN GEOFENCING =================
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data lokasi kantor: $e')),
      );
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

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pengaturan Geofencing berhasil disimpan!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan pengaturan.'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text('Pengaturan Lokasi & Radius Absensi (Geofencing)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            SizedBox(height: 8),
            Text('Tentukan titik koordinat pusat kantor serta batas maksimal radius (dalam meter) agar pegawai dapat melakukan absensi.', style: TextStyle(color: Color(0xFF64748B))),
            SizedBox(height: 24),
            
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nama Lokasi / Kantor', border: OutlineInputBorder()),
              validator: (val) => val!.isEmpty ? 'Nama wajib diisi' : null,
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    decoration: InputDecoration(labelText: 'Latitude (Garis Lintang)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (val) => val!.isEmpty ? 'Latitude wajib diisi' : null,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    decoration: InputDecoration(labelText: 'Longitude (Garis Bujur)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (val) => val!.isEmpty ? 'Longitude wajib diisi' : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: _radiusController,
              decoration: InputDecoration(labelText: 'Radius Maksimal (dalam meter)', border: OutlineInputBorder(), helperText: 'Contoh: 100 (artinya pegawai harus berada dalam jarak 100m dari titik kantor)'),
              keyboardType: TextInputType.number,
              validator: (val) => val!.isEmpty ? 'Radius wajib diisi' : null,
            ),
            SizedBox(height: 32),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveOfficeData,
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2563EB)),
                child: isSaving 
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Simpan Pengaturan Geofencing', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
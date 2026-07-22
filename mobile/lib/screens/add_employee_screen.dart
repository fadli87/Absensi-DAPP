import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddEmployeeScreen extends StatefulWidget {
  @override
  _AddEmployeeScreenState createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String password = '';
  String role = 'EMPLOYEE';
  int? selectedDepartmentId; // Diubah menjadi int? untuk menampung ID departemen
  int? selectedShiftId;

  List<dynamic> departments = [];
  List<dynamic> shifts = [];
  bool isLoading = false;
  bool isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadMasterData();
  }

  // Ambil daftar departemen dan shift dari API
  void _loadMasterData() async {
    try {
      final fetchedDepts = await ApiService.getDepartments();
      final fetchedShifts = await ApiService.getShifts();
      setState(() {
        departments = fetchedDepts;
        shifts = fetchedShifts;
        isLoadingData = false;
      });
    } catch (e) {
      setState(() => isLoadingData = false);
      print('Gagal memuat data master: $e');
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => isLoading = true);

      try {
        bool success = await ApiService.createUser(
          name, 
          email, 
          password, 
          role, 
          selectedDepartmentId, 
          selectedShiftId,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Karyawan berhasil ditambahkan!')),
          );
          Navigator.pop(context, true); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menambahkan karyawan.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan koneksi.')),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Karyawan')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: isLoadingData 
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                    validator: (val) => val!.isEmpty ? 'Nama wajib diisi' : null,
                    onSaved: (val) => name = val!,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => !val!.contains('@') ? 'Email tidak valid' : null,
                    onSaved: (val) => email = val!,
                  ),
                  SizedBox(height: 12),
                  // Dropdown Departemen
                  DropdownButtonFormField<int>(
                    value: selectedDepartmentId,
                    decoration: InputDecoration(labelText: 'Pilih Departemen', border: OutlineInputBorder()),
                    items: departments.map<DropdownMenuItem<int>>((dept) {
                      return DropdownMenuItem<int>(
                        value: dept['id'],
                        child: Text(dept['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedDepartmentId = val;
                      });
                    },
                    hint: Text('Pilih Departemen'),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Password Default', border: OutlineInputBorder()),
                    obscureText: true,
                    validator: (val) => val!.length < 6 ? 'Minimal 6 karakter' : null,
                    onSaved: (val) => password = val!,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: InputDecoration(labelText: 'Jabatan / Role', border: OutlineInputBorder()),
                    items: ['EMPLOYEE', 'HR', 'ADMIN']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        role = val!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  // Dropdown Shift
                  DropdownButtonFormField<int>(
                    value: selectedShiftId,
                    decoration: InputDecoration(labelText: 'Pilih Shift Kerja', border: OutlineInputBorder()),
                    items: shifts.map<DropdownMenuItem<int>>((shift) {
                      return DropdownMenuItem<int>(
                        value: shift['id'],
                        child: Text('${shift['name']} (${shift['checkInTime']} - ${shift['checkOutTime']})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedShiftId = val;
                      });
                    },
                    hint: Text('Pilih Shift Kerja'),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2563EB), padding: EdgeInsets.symmetric(vertical: 14)),
                    child: isLoading 
                        ? CircularProgressIndicator(color: Colors.white) 
                        : Text('Simpan Karyawan', style: TextStyle(color: Colors.white, fontSize: 16)),
                  )
                ],
              ),
            ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditEmployeeScreen extends StatefulWidget {
  final Map<String, dynamic> user; // Menerima data user yang mau diedit

  const EditEmployeeScreen({Key? key, required this.user}) : super(key: key);

  @override
  _EditEmployeeScreenState createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String email;
  String password = ''; 
  late String role;
  int? selectedDepartmentId;
  int? selectedShiftId;

  List<dynamic> departments = [];
  List<dynamic> shifts = [];
  bool isLoading = false;
  bool isLoadingData = true;

  @override
  void initState() {
    super.initState();
    name = widget.user['name'] ?? '';
    email = widget.user['email'] ?? '';
    role = widget.user['role'] ?? 'EMPLOYEE';
    selectedDepartmentId = widget.user['departmentId'];
    selectedShiftId = widget.user['shiftId'];
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
        bool success = await ApiService.updateUser(
          widget.user['id'].toString(), 
          name, 
          email, 
          password, 
          role,
          selectedDepartmentId,
          selectedShiftId,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Karyawan berhasil diperbarui!')),
          );
          Navigator.pop(context, true); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memperbarui karyawan.')),
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
      appBar: AppBar(title: Text('Edit Karyawan')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: isLoadingData 
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                    validator: (val) => val!.isEmpty ? 'Nama wajib diisi' : null,
                    onSaved: (val) => name = val!,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    initialValue: email,
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
                    decoration: InputDecoration(
                      labelText: 'Password Baru (Opsional)',
                      helperText: 'Kosongkan jika tidak ingin mengubah password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    onChanged: (val) => password = val,
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
                        : Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontSize: 16)),
                  )
                ],
              ),
            ),
      ),
    );
  }
}
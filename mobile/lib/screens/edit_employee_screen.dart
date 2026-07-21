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
  String password = ''; // Kosongkan default-nya agar tidak wajib ganti password
  late String role;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    name = widget.user['name'] ?? '';
    email = widget.user['email'] ?? '';
    role = widget.user['role'] ?? 'EMPLOYEE';
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => isLoading = true);

      try {
        bool success = await ApiService.updateUser(
          widget.user['id'], 
          name, 
          email, 
          password, 
          role,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Karyawan berhasil diperbarui!')),
          );
          Navigator.pop(context, true); // Kembali & beritahu sukses untuk refresh list
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
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(labelText: 'Nama Lengkap'),
                validator: (val) => val!.isEmpty ? 'Nama wajib diisi' : null,
                onSaved: (val) => name = val!,
              ),
              TextFormField(
                initialValue: email,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => !val!.contains('@') ? 'Email tidak valid' : null,
                onSaved: (val) => email = val!,
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Password Baru (Opsional)',
                  helperText: 'Kosongkan jika tidak ingin mengubah password',
                ),
                obscureText: true,
                onChanged: (val) => password = val,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: role,
                decoration: InputDecoration(labelText: 'Jabatan / Role'),
                items: ['EMPLOYEE', 'HR', 'ADMIN']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    role = val!;
                  });
                },
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                child: isLoading 
                    ? CircularProgressIndicator(color: Colors.white) 
                    : Text('Simpan Perubahan'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
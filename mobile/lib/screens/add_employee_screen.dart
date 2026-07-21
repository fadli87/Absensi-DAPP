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
  bool isLoading = false;

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => isLoading = true);

      try {
        bool success = await ApiService.createUser(name, email, password, role);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Karyawan berhasil ditambahkan!')));
          Navigator.pop(context, true); // Kembali & beritahu sukses
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal menambahkan karyawan.')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Terjadi kesalahan.')));
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
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Nama Lengkap'),
                validator: (val) => val!.isEmpty ? 'Nama wajib diisi' : null,
                onSaved: (val) => name = val!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => !val!.contains('@') ? 'Email tidak valid' : null,
                onSaved: (val) => email = val!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password Default'),
                obscureText: true,
                validator: (val) => val!.length < 6 ? 'Minimal 6 karakter' : null,
                onSaved: (val) => password = val!,
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
                    : Text('Simpan Karyawan'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
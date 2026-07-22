import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DepartmentManagementScreen extends StatefulWidget {
  const DepartmentManagementScreen({Key? key}) : super(key: key);

  @override
  _DepartmentManagementScreenState createState() => _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends State<DepartmentManagementScreen> {
  late Future<List<dynamic>> _departmentsFuture;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  void _fetchDepartments() {
    setState(() {
      _departmentsFuture = ApiService.getDepartments();
    });
  }

  void _showDepartmentDialog({Map<String, dynamic>? dept}) {
    final _formKey = GlobalKey<FormState>();
    String name = dept?['name'] ?? '';
    bool isEditing = dept != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Departemen' : 'Tambah Departemen'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              initialValue: name,
              decoration: InputDecoration(labelText: 'Nama Departemen (Cth: IT, HRD)', border: OutlineInputBorder()),
              validator: (val) => val!.isEmpty ? 'Nama departemen wajib diisi' : null,
              onSaved: (val) => name = val!,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2563EB)),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  
                  bool success = isEditing 
                      ? await ApiService.updateDepartment(dept['id'], name)
                      : await ApiService.createDepartment(name);

                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEditing ? 'Departemen diperbarui!' : 'Departemen ditambahkan!')),
                    );
                    _fetchDepartments();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menyimpan departemen.'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pengaturan Departemen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            ElevatedButton.icon(
              onPressed: () => _showDepartmentDialog(),
              icon: Icon(Icons.add, color: Colors.white, size: 18),
              label: Text('Tambah Departemen', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2563EB)),
            ),
          ],
        ),
        SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _departmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Belum ada data departemen.'));
              }

              final depts = snapshot.data!;
              return ListView.builder(
                itemCount: depts.length,
                itemBuilder: (context, index) {
                  final dept = depts[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(dept['name'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showDepartmentDialog(dept: dept),
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
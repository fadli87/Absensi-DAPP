import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ShiftManagementScreen extends StatefulWidget {
  const ShiftManagementScreen({Key? key}) : super(key: key);

  @override
  _ShiftManagementScreenState createState() => _ShiftManagementScreenState();
}

class _ShiftManagementScreenState extends State<ShiftManagementScreen> {
  late Future<List<dynamic>> _shiftsFuture;

  @override
  void initState() {
    super.initState();
    _fetchShifts();
  }

  void _fetchShifts() {
    setState(() {
      _shiftsFuture = ApiService.getShifts();
    });
  }

  // Dialog untuk Tambah / Edit Shift
  void _showShiftDialog({Map<String, dynamic>? shift}) {
    final _formKey = GlobalKey<FormState>();
    String name = shift?['name'] ?? '';
    String checkInTime = shift?['checkInTime'] ?? '08:00';
    String checkOutTime = shift?['checkOutTime'] ?? '17:00';
    int toleranceMinutes = shift?['toleranceMinutes'] ?? 15;
    bool isEditing = shift != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Shift Kerja' : 'Tambah Shift Kerja'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: InputDecoration(labelText: 'Nama Shift (Cth: Shift Pagi)', border: OutlineInputBorder()),
                    validator: (val) => val!.isEmpty ? 'Nama wajib diisi' : null,
                    onSaved: (val) => name = val!,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    initialValue: checkInTime,
                    decoration: InputDecoration(labelText: 'Jam Masuk (Format HH:mm, Cth: 08:00)', border: OutlineInputBorder()),
                    validator: (val) => val!.isEmpty ? 'Jam masuk wajib diisi' : null,
                    onSaved: (val) => checkInTime = val!,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    initialValue: checkOutTime,
                    decoration: InputDecoration(labelText: 'Jam Pulang (Format HH:mm, Cth: 17:00)', border: OutlineInputBorder()),
                    validator: (val) => val!.isEmpty ? 'Jam pulang wajib diisi' : null,
                    onSaved: (val) => checkOutTime = val!,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    initialValue: toleranceMinutes.toString(),
                    decoration: InputDecoration(labelText: 'Toleransi Terlambat (Menit)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onSaved: (val) => toleranceMinutes = int.tryParse(val ?? '15') ?? 15,
                  ),
                ],
              ),
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
                  
                  // Kirim data ke backend (bisa menggunakan fungsi service khusus shift)
                  bool success = isEditing 
                      ? await ApiService.updateShift(shift['id'], name, checkInTime, checkOutTime, toleranceMinutes)
                      : await ApiService.createShift(name, checkInTime, checkOutTime, toleranceMinutes);

                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEditing ? 'Shift berhasil diperbarui!' : 'Shift berhasil ditambahkan!')),
                    );
                    _fetchShifts();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menyimpan shift.'), backgroundColor: Colors.red),
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
            Text('Pengaturan Shift Kerja', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            ElevatedButton.icon(
              onPressed: () => _showShiftDialog(),
              icon: Icon(Icons.add, color: Colors.white, size: 18),
              label: Text('Tambah Shift', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2563EB)),
            ),
          ],
        ),
        SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _shiftsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Belum ada data shift kerja.'));
              }

              final shifts = snapshot.data!;
              return ListView.builder(
                itemCount: shifts.length,
                itemBuilder: (context, index) {
                  final shift = shifts[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(shift['name'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Jam Masuk: ${shift['checkInTime']} | Jam Pulang: ${shift['checkOutTime']} (Toleransi: ${shift['toleranceMinutes']} mnt)'),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showShiftDialog(shift: shift),
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
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({Key? key}) : super(key: key);

  @override
  _LeaveScreenState createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  late Future<List<dynamic>> _leaveFuture;

  @override
  void initState() {
    super.initState();
    _fetchLeaveData();
  }

  void _fetchLeaveData() {
    setState(() {
      _leaveFuture = ApiService.getMyLeaveRequests();
    });
  }

  void _showAddLeaveDialog() {
    final _formKey = GlobalKey<FormState>();
    DateTime? startDate;
    DateTime? endDate;
    final _reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Ajukan Izin / Cuti'),
              content: SizedBox(
                width: 400,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tanggal Mulai
                        TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: startDate == null ? 'Pilih Tanggal Mulai' : 'Mulai: ${DateFormat('yyyy-MM-dd').format(startDate!)}',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (picked != null) {
                              setStateDialog(() => startDate = picked);
                            }
                          },
                          validator: (value) => startDate == null ? 'Tanggal mulai harus diisi' : null,
                        ),
                        SizedBox(height: 16),
                        // Tanggal Selesai
                        TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: endDate == null ? 'Pilih Tanggal Selesai' : 'Selesai: ${DateFormat('yyyy-MM-dd').format(endDate!)}',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: startDate ?? DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (picked != null) {
                              setStateDialog(() => endDate = picked);
                            }
                          },
                          validator: (value) => endDate == null ? 'Tanggal selesai harus diisi' : null,
                        ),
                        SizedBox(height: 16),
                        // Alasan
                        TextFormField(
                          controller: _reasonController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Alasan / Keterangan',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Alasan wajib diisi' : null,
                        ),
                      ],
                    ),
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
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setStateDialog(() => isSubmitting = true);
                            bool success = await ApiService.createLeaveRequest(
                              startDate!.toIso8601String(),
                              endDate!.toIso8601String(),
                              _reasonController.text,
                            );
                            setStateDialog(() => isSubmitting = false);
                            Navigator.pop(context);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Pengajuan berhasil dikirim!'), backgroundColor: Colors.green),
                              );
                              _fetchLeaveData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal mengirim pengajuan.'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  child: isSubmitting ? CircularProgressIndicator(color: Colors.white) : Text('Kirim', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'APPROVED':
        return 'Disetujui';
      case 'REJECTED':
        return 'Ditolak';
      default:
        return 'Menunggu Konfirmasi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pengajuan Izin & Cuti Saya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            ElevatedButton.icon(
              onPressed: _showAddLeaveDialog,
              icon: Icon(Icons.add, color: Colors.white, size: 18),
              label: Text('Ajukan Cuti/Izin', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2563EB)),
            ),
          ],
        ),
        SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _leaveFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Belum ada riwayat pengajuan cuti atau izin.'));
              }

              final leaves = snapshot.data!;
              return ListView.builder(
                itemCount: leaves.length,
                itemBuilder: (context, index) {
                  final item = leaves[index];
                  final start = DateTime.tryParse(item['startDate'] ?? '');
                  final end = DateTime.tryParse(item['endDate'] ?? '');
                  final status = item['status'] ?? 'PENDING';
                  final reason = item['reason'] ?? '-';
                  final adminNotes = item['adminNotes'];

                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                start != null && end != null
                                    ? '${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}'
                                    : '-',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _statusLabel(status),
                                  style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text('Alasan: $reason', style: TextStyle(color: Colors.grey[700])),
                          if (adminNotes != null && adminNotes.toString().isNotEmpty) ...[
                            SizedBox(height: 6),
                            Text('Catatan Admin: $adminNotes', style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
                          ],
                        ],
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
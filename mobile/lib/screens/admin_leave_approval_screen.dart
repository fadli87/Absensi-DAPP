import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AdminLeaveApprovalScreen extends StatefulWidget {
  const AdminLeaveApprovalScreen({Key? key}) : super(key: key);

  @override
  _AdminLeaveApprovalScreenState createState() => _AdminLeaveApprovalScreenState();
}

class _AdminLeaveApprovalScreenState extends State<AdminLeaveApprovalScreen> {
  late Future<List<dynamic>> _allLeavesFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _allLeavesFuture = ApiService.getAllLeaveRequests();
    });
  }

  void _showActionDialog(int id, String currentStatus) {
    final _notesController = TextEditingController();
    String selectedStatus = currentStatus == 'PENDING' ? 'APPROVED' : currentStatus;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Validasi Pengajuan Cuti'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                      items: [
                        DropdownMenuItem(value: 'APPROVED', child: Text('Setujui (Approved)')),
                        DropdownMenuItem(value: 'REJECTED', child: Text('Tolak (Rejected)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setStateDialog(() => selectedStatus = val);
                      },
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: 'Catatan Admin (Opsional)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2563EB)),
                  onPressed: () async {
                    bool success = await ApiService.updateLeaveStatus(id, selectedStatus, _notesController.text);
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status cuti berhasil diperbarui!'), backgroundColor: Colors.green));
                      _fetchData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui status.'), backgroundColor: Colors.red));
                    }
                  },
                  child: Text('Simpan', style: TextStyle(color: Colors.white)),
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
      case 'APPROVED': return Colors.green;
      case 'REJECTED': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'APPROVED': return 'Disetujui';
      case 'REJECTED': return 'Ditolak';
      default: return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Persetujuan Cuti & Izin Pegawai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _allLeavesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Belum ada pengajuan cuti dari pegawai.'));
              }

              final list = snapshot.data!;
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  final user = item['user'] ?? {};
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
                              Text(user['name'] ?? 'Pegawai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(_statusLabel(status), style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text('Dept: ${user['department'] ?? '-'} (${user['email'] ?? '-'})', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          Divider(height: 16),
                          Text(
                            start != null && end != null ? 'Tanggal: ${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}' : '-',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text('Alasan: $reason'),
                          if (adminNotes != null && adminNotes.toString().isNotEmpty) ...[
                            SizedBox(height: 4),
                            Text('Catatan Admin: $adminNotes', style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
                          ],
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: () => _showActionDialog(item['id'], status),
                              icon: Icon(Icons.edit_note, size: 16),
                              label: Text('Ubah Status'),
                            ),
                          ),
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
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class MyAttendanceHistoryScreen extends StatefulWidget {
  const MyAttendanceHistoryScreen({Key? key}) : super(key: key);

  @override
  _MyAttendanceHistoryScreenState createState() => _MyAttendanceHistoryScreenState();
}

class _MyAttendanceHistoryScreenState extends State<MyAttendanceHistoryScreen> {
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void _fetchHistory() {
    setState(() {
      _historyFuture = ApiService.getMyHistory();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'LATE':
        return Colors.orange;
      case 'PERMIT':
        return Colors.blue;
      case 'ABSENT':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'LATE':
        return 'Terlambat';
      case 'PERMIT':
        return 'Izin';
      case 'ABSENT':
        return 'Tidak Hadir';
      default:
        return 'Hadir';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Absensi Saya', 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))
        ),
        SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Belum ada riwayat absensi.'));
              }

              final history = snapshot.data!;
              return RefreshIndicator(
                onRefresh: () async => _fetchHistory(),
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final date = DateTime.tryParse(item['date'] ?? '');
                    final checkIn = item['checkIn'] != null ? DateTime.tryParse(item['checkIn']) : null;
                    final checkOut = item['checkOut'] != null ? DateTime.tryParse(item['checkOut']) : null;
                    final status = item['status'] ?? 'PRESENT';

                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          date != null ? DateFormat('EEEE, dd MMM yyyy').format(date) : '-',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(Icons.login, size: 14, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(checkIn != null ? DateFormat('HH:mm').format(checkIn) : '-'),
                              SizedBox(width: 16),
                              Icon(Icons.logout, size: 14, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(checkOut != null ? DateFormat('HH:mm').format(checkOut) : '-'),
                            ],
                          ),
                        ),
                        trailing: Container(
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
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
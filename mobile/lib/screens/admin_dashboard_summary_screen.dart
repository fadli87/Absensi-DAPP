import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AdminDashboardSummaryScreen extends StatefulWidget {
  const AdminDashboardSummaryScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardSummaryScreenState createState() => _AdminDashboardSummaryScreenState();
}

class _AdminDashboardSummaryScreenState extends State<AdminDashboardSummaryScreen> {
  late Future<Map<String, dynamic>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  void _fetchSummary() {
    setState(() {
      _summaryFuture = ApiService.getDashboardSummary();
    });
  }

  void _showDetailDialog(String title, Color color, List<dynamic> people) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 400,
            height: 400,
            child: people.isEmpty
                ? const Center(child: Text('Tidak ada data.'))
                : ListView.builder(
                    itemCount: people.length,
                    itemBuilder: (context, index) {
                      final p = people[index];
                      final checkIn = p['checkIn'] != null ? DateTime.tryParse(p['checkIn']) : null;
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(Icons.person, color: color)),
                        title: Text(p['name'] ?? '-'),
                        subtitle: Text(p['department'] ?? '-'),
                        trailing: checkIn != null ? Text(DateFormat('HH:mm').format(checkIn)) : null,
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required List<dynamic> people,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => _showDetailDialog(title, color, people),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              Text('$count', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _fetchSummary(),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Tidak ada data.'));
          }

          final data = snapshot.data!;
          final summary = data['summary'];
          final details = data['details'];
          final today = DateTime.tryParse(data['date'] ?? '');

          return ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    today != null ? DateFormat('EEEE, dd MMMM yyyy').format(today) : '-',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                  Text('Total Pegawai: ${data['totalEmployees']}', style: TextStyle(color: Colors.grey[700])),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildSummaryCard(
                    title: 'Hadir',
                    count: summary['present'],
                    color: const Color(0xFF059669),
                    icon: Icons.check_circle,
                    people: details['present'],
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    title: 'Terlambat',
                    count: summary['late'],
                    color: const Color(0xFFD97706),
                    icon: Icons.schedule,
                    people: details['late'],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildSummaryCard(
                    title: 'Cuti/Izin',
                    count: summary['onLeave'],
                    color: const Color(0xFF2563EB),
                    icon: Icons.event_note,
                    people: details['onLeave'],
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    title: 'Belum Absen',
                    count: summary['notYetCheckedIn'],
                    color: const Color(0xFFDC2626),
                    icon: Icons.person_off,
                    people: details['notYetCheckedIn'],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
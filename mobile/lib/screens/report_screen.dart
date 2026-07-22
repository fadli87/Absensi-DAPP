import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../services/api_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  List<dynamic> _departments = [];
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];

  int? _selectedDepartmentId;
  int? _selectedUserId;
  String? _selectedStatus;

  bool _isLoadingFilters = true;
  bool _isLoadingReport = false;
  bool _isExporting = false;

  List<dynamic> _summary = [];
  List<dynamic> _records = [];

  final _dateFormat = DateFormat('yyyy-MM-dd');
  final _displayDateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _loadFilterData();
  }

  Future<void> _loadFilterData() async {
    setState(() => _isLoadingFilters = true);
    try {
      final departments = await ApiService.getDepartments();
      final users = await ApiService.getUsers();
      setState(() {
        _departments = departments;
        _users = users;
        _filteredUsers = users;
        _isLoadingFilters = false;
      });
    } catch (e) {
      setState(() => _isLoadingFilters = false);
      _showSnack('Gagal memuat data departemen/pegawai', isError: true);
    }
  }

  void _onDepartmentChanged(int? deptId) {
    setState(() {
      _selectedDepartmentId = deptId;
      _selectedUserId = null; // reset pilihan pegawai saat departemen berubah
      if (deptId == null) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((u) => u['departmentId'] == deptId).toList();
      }
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() => _isLoadingReport = true);
    try {
      final result = await ApiService.getAttendanceReport(
        startDate: _dateFormat.format(_startDate),
        endDate: _dateFormat.format(_endDate),
        departmentId: _selectedDepartmentId,
        userId: _selectedUserId,
        status: _selectedStatus,
      );
      setState(() {
        _summary = result['summary'] ?? [];
        _records = result['records'] ?? [];
        _isLoadingReport = false;
      });
    } catch (e) {
      setState(() => _isLoadingReport = false);
      _showSnack('Gagal memuat laporan', isError: true);
    }
  }

  Future<void> _exportReport(String format) async {
    setState(() => _isExporting = true);
    try {
      final path = await ApiService.downloadReportFile(
        format: format,
        startDate: _dateFormat.format(_startDate),
        endDate: _dateFormat.format(_endDate),
        departmentId: _selectedDepartmentId,
        userId: _selectedUserId,
        status: _selectedStatus,
      );
      setState(() => _isExporting = false);
      _showSnack('Laporan berhasil diunduh!');
      await OpenFile.open(path);
    } catch (e) {
      setState(() => _isExporting = false);
      _showSnack('Gagal mengunduh laporan', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingFilters) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Laporan Absensi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 16),
        _buildFilterCard(),
        const SizedBox(height: 16),
        if (_isLoadingReport)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_summary.isEmpty && _records.isEmpty)
          const Expanded(child: Center(child: Text('Belum ada data. Silakan atur filter dan klik "Tampilkan Laporan".')))
        else
          Expanded(child: _buildReportResult()),
      ],
    );
  }

  Widget _buildFilterCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildDateField('Dari Tanggal', _startDate, () => _pickDate(isStart: true))),
                const SizedBox(width: 12),
                Expanded(child: _buildDateField('Sampai Tanggal', _endDate, () => _pickDate(isStart: false))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDepartmentDropdown()),
                const SizedBox(width: 12),
                Expanded(child: _buildUserDropdown()),
                const SizedBox(width: 12),
                Expanded(child: _buildStatusDropdown()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoadingReport ? null : _generateReport,
                  icon: const Icon(Icons.search, color: Colors.white, size: 18),
                  label: const Text('Tampilkan Laporan', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: (_isExporting || _records.isEmpty) ? null : () => _exportReport('excel'),
                  icon: const Icon(Icons.grid_on, size: 18),
                  label: const Text('Export Excel'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: (_isExporting || _records.isEmpty) ? null : () => _exportReport('pdf'),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Export PDF'),
                ),
                if (_isExporting) ...[
                  const SizedBox(width: 12),
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(_displayDateFormat.format(value)),
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return DropdownButtonFormField<int?>(
      value: _selectedDepartmentId,
      decoration: const InputDecoration(labelText: 'Departemen', border: OutlineInputBorder()),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Semua Departemen')),
        ..._departments.map((d) => DropdownMenuItem<int?>(value: d['id'], child: Text(d['name']))),
      ],
      onChanged: _onDepartmentChanged,
    );
  }

  Widget _buildUserDropdown() {
    return DropdownButtonFormField<int?>(
      value: _selectedUserId,
      decoration: const InputDecoration(labelText: 'Pegawai', border: OutlineInputBorder()),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Semua Pegawai')),
        ..._filteredUsers.map((u) => DropdownMenuItem<int?>(value: u['id'], child: Text(u['name']))),
      ],
      onChanged: (val) => setState(() => _selectedUserId = val),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String?>(
      value: _selectedStatus,
      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem<String?>(value: null, child: Text('Semua Status')),
        DropdownMenuItem<String?>(value: 'PRESENT', child: Text('Hadir')),
        DropdownMenuItem<String?>(value: 'LATE', child: Text('Terlambat')),
        DropdownMenuItem<String?>(value: 'PERMIT', child: Text('Izin')),
        DropdownMenuItem<String?>(value: 'ABSENT', child: Text('Tidak Hadir')),
      ],
      onChanged: (val) => setState(() => _selectedStatus = val),
    );
  }

  Widget _buildReportResult() {
    return ListView(
      children: [
        Text('Ringkasan per Pegawai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        _buildSummaryTable(),
        const SizedBox(height: 24),
        Text('Detail Absensi (${_records.length} baris)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        _buildDetailTable(),
      ],
    );
  }

  Widget _buildSummaryTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nama')),
          DataColumn(label: Text('Departemen')),
          DataColumn(label: Text('Hadir')),
          DataColumn(label: Text('Terlambat')),
          DataColumn(label: Text('Izin')),
          DataColumn(label: Text('Tidak Hadir')),
          DataColumn(label: Text('Total')),
        ],
        rows: _summary.map<DataRow>((s) {
          return DataRow(cells: [
            DataCell(Text(s['name'] ?? '-')),
            DataCell(Text(s['department'] ?? '-')),
            DataCell(Text('${s['present']}')),
            DataCell(Text('${s['late']}')),
            DataCell(Text('${s['permit']}')),
            DataCell(Text('${s['absent']}')),
            DataCell(Text('${s['total']}')),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildDetailTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Tanggal')),
          DataColumn(label: Text('Nama')),
          DataColumn(label: Text('Departemen')),
          DataColumn(label: Text('Check In')),
          DataColumn(label: Text('Check Out')),
          DataColumn(label: Text('Status')),
        ],
        rows: _records.map<DataRow>((r) {
          final date = DateTime.tryParse(r['date'] ?? '');
          final checkIn = r['checkIn'] != null ? DateTime.tryParse(r['checkIn']) : null;
          final checkOut = r['checkOut'] != null ? DateTime.tryParse(r['checkOut']) : null;
          return DataRow(cells: [
            DataCell(Text(date != null ? DateFormat('dd/MM/yyyy').format(date) : '-')),
            DataCell(Text(r['user']?['name'] ?? '-')),
            DataCell(Text(r['user']?['department']?['name'] ?? '-')),
            DataCell(Text(checkIn != null ? DateFormat('HH:mm').format(checkIn) : '-')),
            DataCell(Text(checkOut != null ? DateFormat('HH:mm').format(checkOut) : '-')),
            DataCell(Text(r['status'] ?? '-')),
          ]);
        }).toList(),
      ),
    );
  }
}
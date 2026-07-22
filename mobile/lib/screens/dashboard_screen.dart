// lib/screens/dashboard_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import 'my_attendance_history_screen.dart';
import 'leave_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  
  String _statusMessage = 'Belum melakukan absensi hari ini.';
  bool _isLoading = false;
  File? _imageFile; // Menyimpan file foto selfie

  // Fungsi untuk mengambil foto selfie menggunakan kamera depan
  Future<void> _takeSelfie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front, // Menggunakan kamera depan
        imageQuality: 50, // Kompres kualitas gambar agar ukuran tidak terlalu besar
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
          _statusMessage = 'Foto selfie berhasil diambil. Siap melakukan absensi.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Gagal membuka kamera: $e';
      });
    }
  }

  // Fungsi untuk mendapatkan posisi GPS
  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _statusMessage = 'Gagal: Layanan GPS/Lokasi di HP Anda nonaktif.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _statusMessage = 'Gagal: Izin akses lokasi ditolak.');
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() => _statusMessage = 'Gagal: Izin lokasi ditolak permanen. Ubah di Pengaturan HP.');
      return null;
    }

    try {
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) return position;

      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      return position;
    } catch (e) {
      setState(() => _statusMessage = 'Gagal mendeteksi sinyal GPS. Pastikan Anda di luar ruangan.');
      return null;
    }
  }

  // Rumus Haversine untuk menghitung jarak dalam meter antara dua koordinat
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Radius bumi dalam meter
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Fungsi Validasi Geofencing & Kirim Absen (Check-In / Check-Out)
  Future<void> _processAttendance(String type) async {
    if (_imageFile == null) {
      setState(() => _statusMessage = 'Harap ambil foto selfie terlebih dahulu!');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Memeriksa lokasi GPS & radius kantor...';
    });

    // 1. Ambil posisi GPS Pegawai saat ini
    Position? position = await _determinePosition();
    if (position == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 2. Ambil data titik pusat & radius kantor dari database server
      Map<String, dynamic> office = await ApiService.getOfficeLocation();
      double officeLat = office['latitude'];
      double officeLng = office['longitude'];
      int maxRadius = office['radius']; // Batas radius dalam meter

      // 3. Hitung jarak menggunakan Haversine Formula
      double distanceInMeters = _calculateDistance(
        officeLat, 
        officeLng, 
        position.latitude, 
        position.longitude,
      );

      // 4. Validasi apakah pegawai berada di luar radius kantor
      if (distanceInMeters > maxRadius) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'ABSEN DITOLAK: Anda di luar radius kantor!\nJarak: ${distanceInMeters.toStringAsFixed(1)}m (Maks: ${maxRadius}m)';
        });
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Di Luar Jangkauan Kantor'),
            content: Text(
              'Anda berada di luar radius kantor yang diizinkan.\n\n'
              '• Jarak Anda: ${distanceInMeters.toStringAsFixed(1)} meter\n'
              '• Radius Maksimal: $maxRadius meter'
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))
            ],
          ),
        );
        return;
      }

      // 5. Jika lolos validasi jarak, ambil token dan kirim data ke server
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? prefs.getString('token');

      if (token == null) {
        setState(() {
          _statusMessage = 'Sesi habis. Silakan login ulang.';
          _isLoading = false;
        });
        return;
      }

      String endpoint = type == 'in' ? '/attendance/check-in' : '/attendance/check-out';
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.baseUrl}$endpoint'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['latitude'] = position.latitude.toString();
      request.fields['longitude'] = position.longitude.toString();
      request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _statusMessage = 'BERHASIL ${type == 'in' ? 'CHECK-IN' : 'CHECK-OUT'}!\nJarak: ${distanceInMeters.toStringAsFixed(1)}m dari kantor.';
          _imageFile = null; // Reset foto setelah sukses
        });
      } else {
        setState(() {
          _statusMessage = 'Gagal: ${data['message'] ?? 'Terjadi kesalahan'}';
        });
      }
    } catch (e) {
      setState(() => _statusMessage = 'Gagal memuat geofencing kantor / koneksi error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleCheckIn() => _processAttendance('in');
  void _handleCheckOut() => _processAttendance('out');

  void _handleLogout() async {
    await _apiService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: AppBar(
    title: Text('Absensi DAPP Mobile', style: TextStyle(fontWeight: FontWeight.bold)),
    backgroundColor: Color(0xFF2563EB),
    foregroundColor: Colors.white,
    actions: [
      IconButton(
        icon: Icon(Icons.logout),
        onPressed: _handleLogout,
      )
    ],
  ),
  drawer: Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(color: Color(0xFF2563EB)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Absensi DAPP', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Menu Pegawai', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
        ListTile(
          leading: Icon(Icons.camera_alt, color: Color(0xFF2563EB)),
          title: Text('Absen (Check-In/Out)'),
          onTap: () => Navigator.pop(context),
        ),
        ListTile(
          leading: Icon(Icons.history),
          title: Text('Riwayat Absensi Saya'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Text('Riwayat Absensi Saya'),
                    backgroundColor: Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  body: Padding(
                    padding: EdgeInsets.all(16),
                    child: MyAttendanceHistoryScreen(),
                  ),
                ),
              ),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.event_note),
          title: Text('Ajukan Cuti/Izin'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Text('Cuti / Izin'),
                    backgroundColor: Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  body: Padding(
                    padding: EdgeInsets.all(16),
                    child: LeaveScreen(),
                  ),
                ),
              ),
            );
          },
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.logout, color: Colors.redAccent),
          title: Text('Keluar', style: TextStyle(color: Colors.redAccent)),
          onTap: () {
            Navigator.pop(context);
            _handleLogout();
          },
        ),
      ],
    ),
  ),
  
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),
            
            // Preview Foto Selfie atau Tombol Kamera
            Center(
              child: GestureDetector(
                onTap: _takeSelfie,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFF2563EB), width: 3),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 40, color: Color(0xFF2563EB)),
                            SizedBox(height: 4),
                            Text('Ambil Selfie', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleCheckIn,
              icon: _isLoading 
                  ? Container(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(Icons.login, color: Colors.white),
              label: Text(_isLoading ? 'Memproses...' : 'Check In (Geofencing + Selfie)', style: TextStyle(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF059669),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleCheckOut,
              icon: Icon(Icons.logout, color: Colors.white),
              label: Text('Check Out (Geofencing + Selfie)', style: TextStyle(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD97706),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// lib/screens/dashboard_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

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
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      );
      return position;
    } catch (e) {
      setState(() => _statusMessage = 'Gagal mendeteksi sinyal GPS. Pastikan Anda di luar ruangan.');
      return null;
    }
  }

  // Fungsi Check-In dengan Selfie & GPS (Menggunakan Multipart Request)
  void _handleCheckIn() async {
    if (_imageFile == null) {
      setState(() => _statusMessage = 'Harap ambil foto selfie terlebih dahulu!');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Mendapatkan lokasi GPS & mengirim data...';
    });

    Position? position = await _determinePosition();
    if (position == null) {
      setState(() => _isLoading = false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      setState(() {
        _statusMessage = 'Sesi habis. Silakan login ulang.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Menggunakan MultipartRequest karena mengirim file gambar + teks (latitude/longitude)
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.baseUrl}/attendance/check-in'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['latitude'] = position.latitude.toString();
      request.fields['longitude'] = position.longitude.toString();
      
      // Lampirkan file foto selfie
      request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _statusMessage = 'BERHASIL CHECK-IN DENGAN SELFIE!\nLokasi: ${position!.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _imageFile = null; // Reset foto setelah sukses
        });
      } else {
        setState(() {
          _statusMessage = 'Gagal Check-In: ${data['message'] ?? 'Terjadi kesalahan'}';
        });
      }
    } catch (e) {
      setState(() => _statusMessage = 'Koneksi error ke server: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Fungsi Check-Out dengan Selfie & GPS
  void _handleCheckOut() async {
    if (_imageFile == null) {
      setState(() => _statusMessage = 'Harap ambil foto selfie terlebih dahulu untuk Check-Out!');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Mendapatkan lokasi GPS & mengirim data...';
    });

    Position? position = await _determinePosition();
    if (position == null) {
      setState(() => _isLoading = false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      setState(() {
        _statusMessage = 'Sesi habis. Silakan login ulang.';
        _isLoading = false;
      });
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.baseUrl}/attendance/check-out'),
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
          _statusMessage = 'BERHASIL CHECK-OUT DENGAN SELFIE!\nLokasi: ${position!.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _imageFile = null;
        });
      } else {
        setState(() {
          _statusMessage = 'Gagal Check-Out: ${data['message'] ?? 'Terjadi kesalahan'}';
        });
      }
    } catch (e) {
      setState(() => _statusMessage = 'Koneksi error ke server: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
              label: Text(_isLoading ? 'Memproses...' : 'Check In (Selfie + GPS)', style: TextStyle(fontSize: 16, color: Colors.white)),
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
              label: Text('Check Out (Selfie + GPS)', style: TextStyle(fontSize: 16, color: Colors.white)),
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
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti dengan IP address laptop Anda yang terhubung ke jaringan yang sama
  static const String baseUrl = 'http://192.168.8.110:5005';


  // ==========================================
  // FUNGSI AUTHENTICATION (LOGIN)
  // ==========================================
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token']);
        await prefs.setString('role', responseData['data']['role']); 
        return true;
      } else {
        print('Gagal login. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error pada request login: $e');
      return false;
    }
  }

  // ==========================================
  // FUNGSI UNTUK MENGAMBIL DAFTAR USER
  // ==========================================
  static Future<List<dynamic>> getUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/users'), 
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']; 
    } else {
      throw Exception('Gagal memuat data user');
    }
  }

  // ==========================================
  // FUNGSI UNTUK MENAMBAH USER BARU
  // ==========================================
  static Future<bool> createUser(String name, String email, String password, String role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/api/users/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    return response.statusCode == 201;
  }

  // ==========================================
  // FUNGSI UNTUK UPDATE USER (YANG KURANG)
  // ==========================================
  static Future<bool> updateUser(String id, String name, String email, String password, String role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final Map<String, dynamic> bodyData = {
      'name': name,
      'email': email,
      'role': role,
    };
    
    // Kirim password hanya jika diisi (tidak kosong)
    if (password.isNotEmpty) {
      bodyData['password'] = password;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/api/users/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(bodyData),
    );

    return response.statusCode == 200;
  }

  // ==========================================
  // FUNGSI LOGOUT
  // ==========================================
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
  }
// ==========================================
  // AMBIL PENGATURAN LOKASI KANTOR
  // ==========================================
  static Future<Map<String, dynamic>> getOfficeLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/office'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Gagal memuat pengaturan lokasi kantor');
    }
  }

  // ==========================================
  // UPDATE PENGATURAN LOKASI KANTOR
  // ==========================================
  static Future<bool> updateOfficeLocation(String name, double latitude, double longitude, int radius) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/api/office'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      }),
    );

    return response.statusCode == 200;
  }





}
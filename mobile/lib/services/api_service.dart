import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti dengan IP address laptop Anda yang terhubung ke jaringan yang sama
  static const String baseUrl = 'http://192.168.67.222:5005';  //'http://192.168.8.110:5005';

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
  // FUNGSI LOGOUT
  // ==========================================
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
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
  static Future<bool> createUser(String name, String email, String password, String role, int? departmentId, int? shiftId) async {
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
        'departmentId': departmentId,
        'shiftId': shiftId,
      }),
    );

    return response.statusCode == 201;
  }

  // ==========================================
  // FUNGSI UNTUK UPDATE USER
  // ==========================================
  static Future<bool> updateUser(String id, String name, String email, String password, String role, int? departmentId, int? shiftId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final Map<String, dynamic> bodyData = {
      'name': name,
      'email': email,
      'role': role,
      'departmentId': departmentId,
      'shiftId': shiftId,
    };
    
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

  // ==========================================
  // FUNGSI SHIFT KERJA
  // ==========================================
  static Future<List<dynamic>> getShifts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/shifts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Gagal memuat data shift');
    }

  }

  static Future<bool> createShift(String name, String checkInTime, String checkOutTime, int toleranceMinutes) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/api/shifts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'checkInTime': checkInTime,
        'checkOutTime': checkOutTime,
        'toleranceMinutes': toleranceMinutes,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> updateShift(int id, String name, String checkInTime, String checkOutTime, int toleranceMinutes) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/api/shifts/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'checkInTime': checkInTime,
        'checkOutTime': checkOutTime,
        'toleranceMinutes': toleranceMinutes,
      }),
    );
    return response.statusCode == 200;
  }

  // ==========================================
  // FUNGSI DEPARTEMEN
  // ==========================================
  static Future<List<dynamic>> getDepartments() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/departments'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      // INI KUNCI UTAMANYA: Kita cetak error dari backend ke terminal
      print('=== ERROR DEPARTEMEN ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('========================');
      throw Exception('Gagal memuat data departemen');
    }
  }

  static Future<bool> createDepartment(String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/api/departments'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'name': name}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> updateDepartment(int id, String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/api/departments/$id'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'name': name}),
    );
    return response.statusCode == 200;
  }
  // ==========================================
  // FUNGSI LAPORAN / REPORT
  // ==========================================

  // Ambil data laporan (JSON) untuk ditampilkan di tabel
  static Future<Map<String, dynamic>> getAttendanceReport({
    required String startDate,
    required String endDate,
    int? departmentId,
    int? userId,
    String? status,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final queryParams = {
      'startDate': startDate,
      'endDate': endDate,
      if (departmentId != null) 'departmentId': departmentId.toString(),
      if (userId != null) 'userId': userId.toString(),
      if (status != null) 'status': status,
    };

    final uri = Uri.parse('$baseUrl/api/reports/attendance').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Gagal memuat data laporan');
    }
  }

  // Download file laporan (Excel atau PDF), return path file lokal
  static Future<String> downloadReportFile({
    required String format, // 'excel' atau 'pdf'
    required String startDate,
    required String endDate,
    int? departmentId,
    int? userId,
    String? status,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final queryParams = {
      'startDate': startDate,
      'endDate': endDate,
      if (departmentId != null) 'departmentId': departmentId.toString(),
      if (userId != null) 'userId': userId.toString(),
      if (status != null) 'status': status,
    };

    final uri = Uri.parse('$baseUrl/api/reports/attendance/export/$format').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengunduh laporan');
    }

    final dir = await getApplicationDocumentsDirectory();
    final extension = format == 'excel' ? 'xlsx' : 'pdf';
    final fileName = 'laporan_absensi_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final filePath = '${dir.path}\\$fileName';

    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    return filePath;
  }

  // ==========================================
  // FUNGSI RIWAYAT ABSENSI SAYA (Employee & Admin)
  // ==========================================
  static Future<List<dynamic>> getMyHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/attendance/my-history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Gagal memuat riwayat absensi');
    }
  }

  // ==========================================
  // FITUR CUTI / IZIN (LEAVE REQUESTS)
  // ==========================================

  // Mengajukan cuti atau izin baru
  static Future<bool> createLeaveRequest(String startDate, String endDate, String reason) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/api/leaves'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'startDate': startDate,
        'endDate': endDate,
        'reason': reason,
      }),
    );

    return response.statusCode == 201;
  }

  // Mengambil riwayat cuti milik user yang sedang login
  static Future<List<dynamic>> getMyLeaveRequests() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/leaves/my'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Gagal memuat riwayat cuti/izin');
    }
  }

  // (Khusus Admin) Mengambil semua pengajuan cuti karyawan
  static Future<List<dynamic>> getAllLeaveRequests() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/leaves/admin/all'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      print('=== ERROR LEAVE (ADMIN ALL) ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('================================');
      throw Exception('Gagal memuat data pengajuan cuti');
    }
  }

  // (Khusus Admin) Menyetujui atau menolak cuti
  static Future<bool> updateLeaveStatus(int id, String status, String? adminNotes) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/api/leaves/admin/$id/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': status, // 'APPROVED' atau 'REJECTED'
        'adminNotes': adminNotes,
      }),
    );

    return response.statusCode == 200;
  }
}
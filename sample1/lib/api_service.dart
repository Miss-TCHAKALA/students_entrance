import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://localhost:3000";

  // Function to fetch students
  static Future<List<Map<String, dynamic>>> fetchStudents() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/students'));

      if (response.statusCode == 200) {
        List<dynamic> students = json.decode(response.body);
        return students.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load students');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

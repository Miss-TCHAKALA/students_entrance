import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StudentSearchPage(),
    );
  }
}

class StudentSearchPage extends StatefulWidget {
  const StudentSearchPage({super.key});

  @override
  _StudentSearchPageState createState() => _StudentSearchPageState();
}

class _StudentSearchPageState extends State<StudentSearchPage> {
  TextEditingController searchController = TextEditingController();
  List<dynamic> students = []; // Store students from API
  List<dynamic> filteredStudents = []; // Search results
  Map<String, String>? selectedStudent;

  @override
  void initState() {
    super.initState();
    fetchStudents(); // Fetch students when the app starts
  }

  // Fetch students from API
  Future<void> fetchStudents() async {
    try {
      var response = await http.get(Uri.parse("http://localhost:3000/students"));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          students = data;
          filteredStudents = students; // Initially show all students
        });
      } else {
        print("❌ Error fetching students: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Network error: $e");
    }
  }

  // Search function
  void searchStudent(String query) {
    List<dynamic> results = students
        .where((student) =>
    student['student_id'].toLowerCase() == query.toLowerCase())
        .toList();

    setState(() {
      if (results.isNotEmpty) {
        selectedStudent = {
          "id": results[0]['student_id'],
          "name": results[0]['name'],
          "image": results[0]['profile_image'] ?? "https://via.placeholder.com/150",
        };
      } else {
        selectedStudent = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Search'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: "Enter Student ID",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: searchStudent,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner, size: 30),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => QRViewScreen(onScanned: searchStudent)),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (selectedStudent != null)
              Column(
                children: [
                  Image.network(
                    selectedStudent!["image"]!,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.error, size: 50),
                  ),
                  const SizedBox(height: 10),
                  Text("ID: ${selectedStudent!["id"]}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Name: ${selectedStudent!["name"]}", style: const TextStyle(fontSize: 18)),
                ],
              ),
            const SizedBox(height: 20),
            const Text("Student List", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  var student = filteredStudents[index];
                  return ListTile(
                    leading: Image.network(
                      student['profile_image'] ?? "https://via.placeholder.com/150",
                      width: 50,
                      height: 50,
                    ),
                    title: Text(student['name']),
                    subtitle: Text("ID: ${student['student_id']}"),
                    onTap: () => searchStudent(student['student_id']),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QRViewScreen extends StatelessWidget {
  final Function(String) onScanned;

  QRViewScreen({required this.onScanned});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Scanner")),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String? value = barcode.rawValue;
            if (value != null) {
              onScanned(value);
              Navigator.pop(context);
            }
          }
        },
      ),
    );
  }
}





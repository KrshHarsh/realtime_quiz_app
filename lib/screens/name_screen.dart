// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'home_screen.dart';

// class NameScreen extends StatefulWidget {
//   const NameScreen({super.key});

//   @override
//   State<NameScreen> createState() => _NameScreenState();
// }

// class _NameScreenState extends State<NameScreen> {
//   final _controller = TextEditingController();

//   Future<void> _saveName() async {
//     final name = _controller.text.trim();
//     if (name.isEmpty) return;

//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('userName', name);

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const HomeScreen()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Text(
//                 'Enter Your Name',
//                 style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 20),
//               TextField(
//                 controller: _controller,
//                 decoration: InputDecoration(
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                   hintText: 'e.g. John Doe',
//                 ),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _saveName,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blueAccent,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
//                 ),
//                 child: const Text('Continue'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'chat_screen.dart';
// import 'quiz_screen.dart';


// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Realtime Quiz App')),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.chat),
//                 label: const Text('Join Chat Room'),
//                 onPressed: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const ChatScreen()),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.quiz),
//                 label: const Text('Join Live Quiz'),
//                 onPressed: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const QuizScreen()),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               // ElevatedButton.icon(
//               //   icon: const Icon(Icons.admin_panel_settings),
//               //   label: const Text('Admin Panel (for testing)'),
//               //   onPressed: () => Navigator.push(
//               //     context,
//               //     MaterialPageRoute(builder: (_) => const AdminScreen()),
//               //   ),
//               // ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

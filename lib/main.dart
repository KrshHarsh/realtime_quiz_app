import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAuth.instance.signInAnonymously();
  runApp(const RealtimeQuizApp());
}

class RealtimeQuizApp extends StatelessWidget {
  const RealtimeQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Realtime Quiz & Chat',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurpleAccent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ---------------- HOME -----------------
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Realtime Quiz & Chat")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _menuButton(context, "💬 Chat Room", const ChatPage()),
            const SizedBox(height: 20),
            _menuButton(context, "🧠 Live Quiz", const QuizPage()),
            const SizedBox(height: 20),
            _menuButton(context, "👑 Winner Board", const WinnerPage()),
            const SizedBox(height: 20),
            _menuButton(context, "🛠️ Admin (Post Question)", const AdminPage()),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(BuildContext context, String label, Widget page) {
    return ElevatedButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
    );
  }
}

// ---------------- CHAT -----------------
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final user = FirebaseAuth.instance.currentUser!;
  final chatRef = FirebaseFirestore.instance.collection('chats');

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await chatRef.add({
      'senderId': user.uid,
      'senderName': 'User-${user.uid.substring(0, 5)}',
      'message': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('💬 Global Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatRef.orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == user.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.deepPurpleAccent : Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['senderName'] ?? 'User',
                                style: const TextStyle(fontSize: 12, color: Colors.white70)),
                            const SizedBox(height: 2),
                            Text(data['message'] ?? '',
                                style: const TextStyle(fontSize: 16, color: Colors.white)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(color: Colors.black, border: Border(top: BorderSide(color: Colors.grey.shade800))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type message...'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Colors.deepPurpleAccent), onPressed: _sendMessage),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ---------------- QUIZ -----------------
class QuizPage extends StatefulWidget {
  const QuizPage({super.key});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final quizRef = FirebaseFirestore.instance.collection('quiz').doc('currentQuestion');
  final answersRef = FirebaseFirestore.instance.collection('quizAnswers');
  Map<String, dynamic>? currentQuestion;
  DateTime? openTime;
  int? selectedOption;

  @override
  void initState() {
    super.initState();
    quizRef.snapshots().listen((snapshot) {
      if (!mounted) return;
      if (snapshot.exists) {
        setState(() {
          currentQuestion = snapshot.data();
          selectedOption = null;
          openTime = DateTime.now();
        });
      }
    });
  }

  Future<void> _submitAnswer(int index) async {
    if (currentQuestion == null) return;
    final qid = currentQuestion!['questionId'];
    final correctIndex = currentQuestion!['correctAnswerIndex'];
    final timeTaken = DateTime.now().difference(openTime!).inMilliseconds / 1000.0;
    final isCorrect = index == correctIndex;

    await answersRef.doc(qid).collection('answers').doc(user.uid).set({
      'selectedOption': index,
      'timeTaken': timeTaken,
      'isCorrect': isCorrect,
      'name': 'User-${user.uid.substring(0, 5)}',
    });

    if (isCorrect) {
      final snap = await answersRef.doc(qid).collection('answers').get();
      double? bestTime;
      String? bestUser;
      String? bestName;

      for (var doc in snap.docs) {
        final data = doc.data();
        if (data['isCorrect'] == true) {
          final t = (data['timeTaken'] as num).toDouble();
          if (bestTime == null || t < bestTime) {
            bestTime = t;
            bestUser = doc.id;
            bestName = data['name'];
          }
        }
      }

      if (bestUser != null && bestTime != null) {
        await FirebaseFirestore.instance.collection('quiz').doc('winner').set({
          'questionId': qid,
          'userId': bestUser,
          'name': bestName,
          'timeTaken': bestTime,
        });
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? "✅ Correct! (${timeTaken.toStringAsFixed(2)}s)" : "❌ Wrong Answer"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🧠 Live Quiz")),
      body: currentQuestion == null
          ? const Center(child: Text("Waiting for next question..."))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(currentQuestion!['questionText'] ?? '',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  ...List.generate((currentQuestion!['options'] as List).length, (i) {
                    final opt = currentQuestion!['options'][i];
                    final isSelected = selectedOption == i;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Colors.deepPurpleAccent
                              : Colors.deepPurpleAccent.withOpacity(0.3),
                        ),
                        onPressed: selectedOption == null
                            ? () {
                                setState(() => selectedOption = i);
                                _submitAnswer(i);
                              }
                            : null,
                        child: Text(opt, style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

// ---------------- WINNER -----------------
class WinnerPage extends StatelessWidget {
  const WinnerPage({super.key});
  @override
  Widget build(BuildContext context) {
    final winnerRef = FirebaseFirestore.instance.collection('quiz').doc('winner');
    return Scaffold(
      appBar: AppBar(title: const Text("👑 Winner Board")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: winnerRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return const Center(child: Text("No winner yet."));
          final data = snapshot.data!.data() as Map<String, dynamic>;
          return Center(
            child: Card(
              color: Colors.deepPurpleAccent.withOpacity(0.25),
              margin: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
                    const SizedBox(height: 10),
                    Text(data['name'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Time Taken: ${data['timeTaken']?.toStringAsFixed(2)}s",
                        style: const TextStyle(fontSize: 16, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------- ADMIN -----------------
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController qController = TextEditingController();
  final List<TextEditingController> options =
      List.generate(4, (_) => TextEditingController());
  int correctIndex = 0;

  Future<void> _postQuestion() async {
    final question = qController.text.trim();
    final opts = options.map((e) => e.text.trim()).toList();
    if (question.isEmpty || opts.any((o) => o.isEmpty)) return;
    await FirebaseFirestore.instance.collection('quiz').doc('currentQuestion').set({
      'questionId': DateTime.now().millisecondsSinceEpoch.toString(),
      'questionText': question,
      'options': opts,
      'correctAnswerIndex': correctIndex,
      'startTime': Timestamp.now(),
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("✅ Question Posted")));
    qController.clear();
    for (var o in options) o.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🛠️ Admin Panel")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: qController, decoration: const InputDecoration(labelText: "Question")),
            const SizedBox(height: 10),
            for (int i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: TextField(controller: options[i], decoration: InputDecoration(labelText: "Option ${i + 1}")),
              ),
            const SizedBox(height: 10),
            DropdownButton<int>(
              value: correctIndex,
              items: List.generate(4, (i) => DropdownMenuItem(value: i, child: Text("Correct Option ${i + 1}"))),
              onChanged: (v) => setState(() => correctIndex = v ?? 0),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _postQuestion, child: const Text("Post Question")),
          ],
        ),
      ),
    );
  }
}

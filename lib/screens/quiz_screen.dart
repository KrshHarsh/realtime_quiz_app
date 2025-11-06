import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _db = FirebaseDatabase.instance.ref();
  Map? currentQuestion;
  double? openTime;
  String? userName;
  bool answered = false;
  String? winnerName;

  @override
  void initState() {
    super.initState();
    _loadName();
    _listenForQuestion();
    _listenForWinner();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('userName');
  }

  void _listenForQuestion() {
    _db.child('quiz/currentQuestion').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          currentQuestion = Map.from(event.snapshot.value as Map);
          openTime = DateTime.now().millisecondsSinceEpoch / 1000;
          answered = false;
          winnerName = null;
        });
      }
    });
  }

  void _listenForWinner() {
    _db.child('quiz/winner').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() => winnerName = Map.from(event.snapshot.value as Map)['name']);
      }
    });
  }

  Future<void> _submitAnswer(int selectedIndex) async {
    if (answered) return;
    answered = true;

    final questionId = currentQuestion!['questionId'];
    final correctIndex = currentQuestion!['correctAnswerIndex'];
    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    final timeTaken = now - (openTime ?? now);
    final isCorrect = selectedIndex == correctIndex;

    await _db.child('quizAnswers/$questionId/$userName').set({
      'selectedOption': selectedIndex,
      'timeTaken': timeTaken,
      'isCorrect': isCorrect,
    });

    if (isCorrect) {
      // Determine winner client-side
      final answersRef = _db.child('quizAnswers/$questionId');
      final snapshot = await answersRef.get();
      if (snapshot.value != null) {
        final answers = Map.from(snapshot.value as Map);
        final correctAnswers = answers.entries
            .where((e) => e.value['isCorrect'] == true)
            .toList()
          ..sort((a, b) => (a.value['timeTaken']).compareTo(b.value['timeTaken']));

        if (correctAnswers.isNotEmpty) {
          final winner = correctAnswers.first;
          await _db.child('quiz/winner').set({
            'questionId': questionId,
            'name': winner.key,
            'timeTaken': winner.value['timeTaken'],
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentQuestion == null) {
      return const Scaffold(
        body: Center(child: Text('Waiting for next question...')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Live Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentQuestion!['questionText'], style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 20),
            ...List.generate(
              (currentQuestion!['options'] as List).length,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ElevatedButton(
                  onPressed: () => _submitAnswer(i),
                  child: Text(currentQuestion!['options'][i]),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (winnerName != null)
              Text(
                '🏆 Winner: $winnerName',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}

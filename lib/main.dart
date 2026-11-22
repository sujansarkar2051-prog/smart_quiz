import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const QuizScreen(),
    );
  }
}

class Question {
  final String question;
  final List<String> options;
  final int answerIndex;

  Question({
    required this.question,
    required this.options,
    required this.answerIndex,
  });

  factory Question.fromMap(Map<String, dynamic> m) => Question(
        question: (m['question'] ?? '') as String,
        options: List<String>.from(m['options'] ?? []),
        answerIndex: ((m['answerIndex'] ?? 0) as num).toInt(),
      );
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late Future<List<Question>> _future;
  int _index = 0;
  int _score = 0;
  int? _selected;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Question>> _load() async {
    final snap =
        await FirebaseFirestore.instance.collection('questions').get();
    return snap.docs.map((d) => Question.fromMap(d.data())).toList();
  }

  void _restart() {
    setState(() {
      _index = 0;
      _score = 0;
      _selected = null;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Quiz')),
      body: FutureBuilder<List<Question>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('ডাটা আনতে সমস্যা:\n${snapshot.error}'));
          }
          final questions = snapshot.data ?? [];
          if (questions.isEmpty) {
            return const Center(child: Text('কোনো প্রশ্ন পাওয়া যায়নি'));
          }
          if (_index >= questions.length) {
            return _result(questions.length);
          }
          return _questionView(questions[_index], questions.length);
        },
      ),
    );
  }

  Widget _questionView(Question q, int total) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: (_index + 1) / total),
              const SizedBox(height: 8),
              Text('প্রশ্ন ${_index + 1} / $total'),
              const SizedBox(height: 20),
              Text(q.question,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              for (int i = 0; i < q.options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: _optionColor(q, i),
                    ),
                    onPressed: _selected == null
                        ? () => setState(() {
                              _selected = i;
                              if (i == q.answerIndex) _score++;
                            })
                        : null,
                    child: Text(q.options[i],
                        style: const TextStyle(fontSize: 16)),
                  ),
                ),
              const Spacer(),
              if (_selected != null)
                FilledButton(
                  onPressed: () => setState(() {
                    _index++;
                    _selected = null;
                  }),
                  child: Text(_index + 1 == total ? 'ফলাফল দেখুন' : 'পরের প্রশ্ন'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color? _optionColor(Question q, int i) {
    if (_selected == null) return null;
    if (i == q.answerIndex) return Colors.green.shade300;
    if (i == _selected) return Colors.red.shade300;
    return null;
  }

  Widget _result(int total) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
          const SizedBox(height: 12),
          Text('আপনার স্কোর: $_score / $total',
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          FilledButton(onPressed: _restart, child: const Text('আবার খেলুন')),
        ],
      ),
    );
  }
}
// lib/screens/skill_tests/test_taking_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../models/skill_test_model.dart';
import '../../services/skill_test_service.dart';

class TestTakingScreen extends StatefulWidget {
  final SkillTest test;
  const TestTakingScreen({super.key, required this.test});

  @override
  State<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen> {
  int? _userTestId;
  List<Map<String, dynamic>> _answers = [];
  int _currentQuestionIndex = 0;
  bool _loading = false;
  bool _submitting = false;
  int _timeRemaining = 0;
  Timer? _timer;
  bool _isTestStarted = false;

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.test.timeLimitMinutes * 60;
    _startTest();
  }

  Future<void> _startTest() async {
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      final result = await SkillTestService.startTest(widget.test.id);

      print('Start test result: $result');

      if (result['success'] == true && result['userTestId'] != null) {
        if (mounted) {
          setState(() {
            _userTestId = result['userTestId'];
            _isTestStarted = true;
            _loading = false;
          });
          _startTimer();
        }
      } else {
        if (mounted) {
          setState(() => _loading = false);
          final errorMsg = result['message'] ?? 'Failed to start test';
          Fluttertoast.showToast(msg: errorMsg);

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      }
    } catch (e) {
      print('Error in _startTest: $e');
      if (mounted) {
        setState(() => _loading = false);
        Fluttertoast.showToast(msg: 'Error starting test: $e');
        Navigator.pop(context);
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining <= 0) {
        timer.cancel();
        _submitTest();
      } else {
        if (mounted) {
          setState(() => _timeRemaining--);
        }
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _submitAnswer(dynamic answer) {
    setState(() {
      _answers.add({
        'questionId': widget.test.questions[_currentQuestionIndex].id,
        'answer': answer,
      });
    });

    if (_currentQuestionIndex < widget.test.questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      _submitTest();
    }
  }

  Future<void> _submitTest() async {
    if (_userTestId == null) {
      if (mounted) {
        Fluttertoast.showToast(msg: 'Test not properly initialized');
        Navigator.pop(context);
      }
      return;
    }

    if (_submitting) return;

    setState(() => _submitting = true);
    _timer?.cancel();

    try {
      final result = await SkillTestService.submitTest(_userTestId!, _answers);

      if (mounted) {
        setState(() => _submitting = false);

        if (result['success'] == true) {
          _showResultDialog(result);
        } else {
          Fluttertoast.showToast(
            msg: result['message'] ?? 'Error submitting test',
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        Fluttertoast.showToast(msg: 'Error submitting test: $e');
        Navigator.pop(context);
      }
    }
  }

  void _showResultDialog(Map<String, dynamic> result) {
    final passed = result['passed'];
    final percentage = result['percentage'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              passed ? Icons.celebration : Icons.sentiment_dissatisfied,
              color: passed ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(passed ? 'Test Passed!' : 'Test Completed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your score: $percentage%'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                passed ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              passed
                  ? 'Congratulations! You earned a badge for this skill.'
                  : 'You need ${widget.test.passingScore}% to pass. You can try again later.',
              textAlign: TextAlign.center,
            ),
            if (passed && widget.test.badge != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(
                        widget.test.badge!.color.replaceFirst('#', '0xff'),
                      ),
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Color(
                          int.parse(
                            widget.test.badge!.color.replaceFirst('#', '0xff'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Badge: ${widget.test.badge!.name}',
                        style: TextStyle(
                          color: Color(
                            int.parse(
                              widget.test.badge!.color.replaceFirst(
                                '#',
                                '0xff',
                              ),
                            ),
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.test.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.test.name)),
        body: const Center(child: Text('No questions available for this test')),
      );
    }

    final question = widget.test.questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.test.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timeRemaining < 60
                  ? Colors.red.shade100
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: _timeRemaining < 60 ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_timeRemaining),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _timeRemaining < 60
                        ? Colors.red
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value:
                        (_currentQuestionIndex + 1) /
                        widget.test.questions.length,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(Color(0xff14A800)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${widget.test.questions.length}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    question.text,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ..._buildQuestionOptions(question),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildQuestionOptions(Question question) {
    if (question.type == 'multiple_choice') {
      return question.options.map((option) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _submitting ? null : () => _submitAnswer(option),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(option, style: const TextStyle(fontSize: 16)),
            ),
          ),
        );
      }).toList();
    } else if (question.type == 'true_false') {
      return ['True', 'False'].map((option) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _submitting ? null : () => _submitAnswer(option),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(option, style: const TextStyle(fontSize: 16)),
            ),
          ),
        );
      }).toList();
    }
    return [];
  }
}

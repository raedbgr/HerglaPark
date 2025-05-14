import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/bonus.dart';

class QuizChallenge {
  final String id;
  final List<QuizQuestion> questions;

  QuizChallenge({required this.id, required this.questions});
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
  });
}

class QuizScreen extends StatefulWidget {
  final String chestId;
  final Function onSuccess;
  final Function onFailure;

  QuizScreen({
    required this.chestId,
    required this.onSuccess,
    required this.onFailure,
  });

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  int _currentQuestionIndex = 0;
  bool _answerSelected = false;
  int _selectedAnswerIndex = -1;
  late QuizChallenge _currentChallenge;
  
  // Timer
  late Timer _timer;
  int _timeLeft = 30; // 30 seconds per question
  
  @override
  void initState() {
    super.initState();
    
    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut)
    );
    
    _animationController.forward();
    
    // Select a random challenge
    _currentChallenge = _getRandomChallenge();
    
    // Start timer
    _startTimer();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _timer.cancel();
    super.dispose();
  }
  
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer.cancel();
          _handleFailure("Time's up!");
        }
      });
    });
  }
  
  void _resetTimer() {
    _timer.cancel();
    _timeLeft = 30;
    _startTimer();
  }
  
  QuizChallenge _getRandomChallenge() {
    // Define all challenges
    List<QuizChallenge> challenges = [
      // Challenge 1
      QuizChallenge(
        id: 'challenge1',
        questions: [
          QuizQuestion(
            question: 'What is the capital of Tunisia?',
            options: ['Tunis', 'Sfax', 'Sousse', 'Hammamet'],
            correctAnswerIndex: 0,
          ),
          QuizQuestion(
            question: 'Which ancient city in Tunisia was a major power in the Mediterranean?',
            options: ['Carthage', 'Alexandria', 'Athens', 'Rome'],
            correctAnswerIndex: 0,
          ),
          QuizQuestion(
            question: 'What is the largest desert in Tunisia?',
            options: ['Sahara Desert', 'Arabian Desert', 'Gobi Desert', 'Kalahari Desert'],
            correctAnswerIndex: 0,
          ),
        ],
      ),
      
      // Challenge 2
      QuizChallenge(
        id: 'challenge2',
        questions: [
          QuizQuestion(
            question: 'What sea borders Tunisia to the north and east?',
            options: ['Mediterranean Sea', 'Red Sea', 'Black Sea', 'Caspian Sea'],
            correctAnswerIndex: 0,
          ),
          QuizQuestion(
            question: 'Which famous movie series had scenes filmed in Tunisia?',
            options: ['Star Wars', 'Harry Potter', 'Lord of the Rings', 'Pirates of the Caribbean'],
            correctAnswerIndex: 0,
          ),
          QuizQuestion(
            question: 'What is the official language of Tunisia?',
            options: ['Arabic', 'French', 'Berber', 'English'],
            correctAnswerIndex: 0,
          ),
        ],
      ),
      
      // Challenge 3
      QuizChallenge(
        id: 'challenge3',
        questions: [
          QuizQuestion(
            question: 'What year did Tunisia gain independence from France?',
            options: ['1956', '1945', '1962', '1970'],
            correctAnswerIndex: 0,
          ),
          QuizQuestion(
            question: 'Which Tunisian dish is made of semolina and typically served with stew?',
            options: ['Couscous', 'Brik', 'Lablabi', 'Ojja'],
            correctAnswerIndex: 0,
          ),
          QuizQuestion(
            question: 'What is Tunisia\'s currency?',
            options: ['Tunisian Dinar', 'Dirham', 'Euro', 'Pound'],
            correctAnswerIndex: 0,
          ),
        ],
      ),
    ];
    
    // Return a random challenge
    return challenges[Random().nextInt(challenges.length)];
  }
  
  void _handleAnswer(int selectedIndex) {
    setState(() {
      _answerSelected = true;
      _selectedAnswerIndex = selectedIndex;
    });
    
    // Check if the answer is correct
    if (selectedIndex == _currentChallenge.questions[_currentQuestionIndex].correctAnswerIndex) {
      // Correct answer
      Future.delayed(Duration(milliseconds: 500), () {
        if (_currentQuestionIndex < _currentChallenge.questions.length - 1) {
          // Move to next question
          setState(() {
            _currentQuestionIndex++;
            _answerSelected = false;
            _selectedAnswerIndex = -1;
            _resetTimer();
          });
        } else {
          // All questions answered correctly
          _timer.cancel();
          widget.onSuccess();
          _handleSuccess();
        }
      });
    } else {
      // Wrong answer
      Future.delayed(Duration(milliseconds: 500), () {
        _timer.cancel();
        _handleFailure("Incorrect answer!");
      });
    }
  }
  
  void _handleSuccess() {
    // Get chest data first to retrieve the bonus type
    FirebaseFirestore.instance.collection('chests').doc(widget.chestId).get().then((chestDoc) {
      if (chestDoc.exists) {
        final chestData = chestDoc.data() as Map<String, dynamic>;
        final bonusType = chestData['bonusType'] as String;
        
        // Generate QR code (15-digit random number as string)
        final qrCode = _generateRandomNumericString(15);
        
        // Create bonus document
        final bonusId = Uuid().v4();
        final userId = FirebaseAuth.instance.currentUser?.uid;
        
        if (userId != null) {
          // Create bonus object
          final bonus = Bonus(
            id: bonusId,
            type: bonusType,
            isUsed: false,
            ownerId: userId,
            qrCode: qrCode,
            createdAt: Timestamp.now(),
            expiresAt: Timestamp.fromDate(DateTime.now().add(Duration(days: 7))),
          );
          
          // Save bonus to Firestore
          FirebaseFirestore.instance.collection('bonus').doc(bonusId).set(bonus.toJson());
          
          // Increment user's chestsOpened counter
          FirebaseFirestore.instance.collection('users').doc(userId).get().then((userDoc) {
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              final int currentCount = userData['chestsOpened'] ?? 0;
              
              FirebaseFirestore.instance.collection('users').doc(userId).update({
                'chestsOpened': currentCount + 1,
              });
            } else {
              FirebaseFirestore.instance.collection('users').doc(userId).set({
                'chestsOpened': 1,
              });
            }
          });
          
          // Show success message with bonus details
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Trophy/success icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber.withOpacity(0.2),
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        size: 60,
                        color: Colors.amber,
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Congratulations text
                    Text(
                      'Congratulations!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'You have successfully opened the chest!',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    
                    // Bonus reward info
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'You\'ve earned:',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            _getBonusTypeDescription(bonusType),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getBonusTypeColor(bonusType),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Check your profile to use your reward!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Close button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getBonusTypeColor(bonusType),
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(); // Close bottom sheet
                      },
                      child: Text(
                        'Awesome!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        // Remove chest from Firestore
        FirebaseFirestore.instance.collection('chests').doc(widget.chestId).delete();
      }
    });
  }
  
  // Helper method to generate random numeric string
  String _generateRandomNumericString(int length) {
    final random = Random();
    final buffer = StringBuffer();
    
    for (var i = 0; i < length; i++) {
      buffer.write(random.nextInt(10).toString());
    }
    
    return buffer.toString();
  }
  
  // Function to generate a random bonus type
  String getRandomBonusType() {
    final List<String> bonusTypes = ["vr", "karting", "shooting"];
    final random = Random();
    return bonusTypes[random.nextInt(bonusTypes.length)];
  }
  
  // Helper method to get bonus type description
  String _getBonusTypeDescription(String bonusType) {
    switch (bonusType.toLowerCase()) {
      case 'vr':
        return 'Free VR Experience';
      case 'karting':
        return 'Free Karting Session';
      case 'shooting':
        return 'Free Shooting Session';
      default:
        return 'Free Park Activity';
    }
  }
  
  // Helper method to get bonus type color
  Color _getBonusTypeColor(String bonusType) {
    switch (bonusType.toLowerCase()) {
      case 'vr':
        return Colors.blue;
      case 'karting':
        return Colors.green;
      case 'shooting':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }
  
  void _handleFailure(String reason) {
    // Show failure message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Challenge Failed'),
        content: Text('$reason You can try again in 5 minutes.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close bottom sheet
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
    
    // Update chest with cooldown timer
    FirebaseFirestore.instance.collection('chests').doc(widget.chestId).update({
      'cooldownUntil': FieldValue.serverTimestamp(),
    });
    
    widget.onFailure();
  }
  
  @override
  Widget build(BuildContext context) {
    final currentQuestion = _currentChallenge.questions[_currentQuestionIndex];
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _animation.value) * 300),
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    height: 4,
                    width: 40,
                    alignment: Alignment.center,
                    child: Container(
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Quiz Title
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'Quiz Challenge',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Question ${_currentQuestionIndex + 1}/${_currentChallenge.questions.length}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Timer
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.grey[200],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: _timeLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: _timeLeft > 10 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 30 - _timeLeft,
                          child: Container(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Time left text
                  Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20, top: 5),
                    child: Text(
                      '$_timeLeft seconds left',
                      style: TextStyle(
                        color: _timeLeft > 10 ? Colors.green : Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  
                  // Question
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentQuestion.question,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          // Options
                          ...List.generate(
                            currentQuestion.options.length,
                            (index) => GestureDetector(
                              onTap: _answerSelected ? null : () => _handleAnswer(index),
                              child: Container(
                                margin: EdgeInsets.only(bottom: 15),
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: _getOptionColor(index),
                                  border: Border.all(
                                    color: _getOptionBorderColor(index),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 24,
                                      width: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _answerSelected && index == _selectedAnswerIndex
                                            ? _getOptionBorderColor(index)
                                            : Colors.white,
                                        border: Border.all(
                                          color: _getOptionBorderColor(index),
                                          width: 2,
                                        ),
                                      ),
                                      child: _answerSelected && index == _selectedAnswerIndex
                                          ? Icon(
                                              index == currentQuestion.correctAnswerIndex
                                                  ? Icons.check
                                                  : Icons.close,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        currentQuestion.options[index],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: index == _selectedAnswerIndex
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Color _getOptionColor(int index) {
    if (!_answerSelected) {
      return Colors.white;
    }
    
    if (index == _currentChallenge.questions[_currentQuestionIndex].correctAnswerIndex) {
      return Colors.green.withOpacity(0.2);
    }
    
    if (index == _selectedAnswerIndex) {
      return Colors.red.withOpacity(0.2);
    }
    
    return Colors.white;
  }
  
  Color _getOptionBorderColor(int index) {
    if (!_answerSelected) {
      return Colors.grey;
    }
    
    if (index == _currentChallenge.questions[_currentQuestionIndex].correctAnswerIndex) {
      return Colors.green;
    }
    
    if (index == _selectedAnswerIndex) {
      return Colors.red;
    }
    
    return Colors.grey;
  }
}

// Function to show the quiz bottom sheet
void showQuizBottomSheet(BuildContext context, String chestId) {
  // Check if chest is on cooldown
  FirebaseFirestore.instance.collection('chests').doc(chestId).get().then((doc) {
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Check if chest is on cooldown
      if (data.containsKey('cooldownUntil')) {
        final cooldownUntil = data['cooldownUntil'] as Timestamp;
        final cooldownEnd = cooldownUntil.toDate().add(Duration(minutes: 5));
        
        if (DateTime.now().isBefore(cooldownEnd)) {
          // Still on cooldown
          final remainingMinutes = cooldownEnd.difference(DateTime.now()).inMinutes + 1;
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Chest Locked'),
              content: Text('This chest is still locked. You can try again in $remainingMinutes minutes.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
          );
          return;
        }
      }
      
      // Show the quiz
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => QuizScreen(
          chestId: chestId,
          onSuccess: () {
            // Chest opened successfully, handled in the QuizScreen
          },
          onFailure: () {
            // Failed to open chest, handled in the QuizScreen
          },
        ),
      );
    }
  });
}

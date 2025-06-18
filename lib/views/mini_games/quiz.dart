import '/imports.dart';

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

  const QuizScreen({super.key, required this.chestId});

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
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
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
    List<QuizChallenge> challenges = [
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

    return challenges[Random().nextInt(challenges.length)];
  }

  void _handleAnswer(int selectedIndex) {
    setState(() {
      _answerSelected = true;
      _selectedAnswerIndex = selectedIndex;
    });

    if (selectedIndex == _currentChallenge.questions[_currentQuestionIndex].correctAnswerIndex) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (_currentQuestionIndex < _currentChallenge.questions.length - 1) {
          setState(() {
            _currentQuestionIndex++;
            _answerSelected = false;
            _selectedAnswerIndex = -1;
            _resetTimer();
          });
        } else {
          _timer.cancel();
          _handleSuccess();
        }
      });
    } else {
      Future.delayed(Duration(milliseconds: 500), () {
        _timer.cancel();
        _handleFailure("Incorrect answer!");
      });
    }
  }

  void _handleSuccess() {
    FirebaseFirestore.instance.collection('chests').doc(widget.chestId).get().then((chestDoc) {
      if (chestDoc.exists && mounted) {
        final chestData = chestDoc.data() as Map<String, dynamic>;
        final bonusType = chestData['bonusType'] as String;

        final qrCode = _generateRandomNumericString(15);
        final bonusId = Uuid().v4();
        final userId = FirebaseAuth.instance.currentUser?.uid;

        if (userId != null) {
          final bonus = Bonus(
            id: bonusId,
            type: bonusType,
            isUsed: false,
            ownerId: userId,
            qrCode: qrCode,
            createdAt: Timestamp.now(),
            expiresAt: Timestamp.fromDate(DateTime.now().add(Duration(days: 7))),
          );

          FirebaseFirestore.instance.collection('bonus').doc(bonusId).set(bonus.toJson());

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
                            style: TextStyle(fontSize: 16),
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
                        Get.back(); // Return to HomePage
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

          FirebaseFirestore.instance.collection('chests').doc(widget.chestId).delete();
        }
      }
    });
  }

  String _generateRandomNumericString(int length) {
    final random = Random();
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(random.nextInt(10).toString());
    }
    return buffer.toString();
  }

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
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          title: Text('Challenge Failed'),
          content: Text('$reason You can try again in 5 minutes.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('OK'),
            ),
          ],
        ),
      ).then((_) {
        if (mounted) {
          FirebaseFirestore.instance.collection('chests').doc(widget.chestId).update({
            'cooldownUntil': FieldValue.serverTimestamp(),
          });
          Get.back(); // Return to HomePage
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _currentChallenge.questions[_currentQuestionIndex];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Quiz Challenge'),
            automaticallyImplyLeading: true,
          ),
          body: Opacity(
            opacity: _animation.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
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
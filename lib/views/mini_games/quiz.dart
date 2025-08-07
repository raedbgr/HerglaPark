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

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _kartAnimationController;
  late Animation<double> _kartAnimation;

  int _currentQuestionIndex = 0;
  bool _answerSelected = false;
  int _selectedAnswerIndex = -1;
  late QuizChallenge _currentChallenge;
  bool isGameOver = false;

  // Timer
  late Timer _timer;
  int _timeLeft = 30;

  @override
  void initState() {
    super.initState();

    // Setup kart animation controller
    _kartAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 30),
    );
    _kartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _kartAnimationController, curve: Curves.linear),
    );

    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    // Load and select random questions
    _loadChallenge();

    // Reset and start kart animation
    _kartAnimationController.reset();
    _kartAnimationController.reverse(from: 1.0); // Run in reverse for countdown

    // Start timer
    _startTimer();
  }

  Future<void> _loadChallenge() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(context).loadString('assets/questions.json');
      final List<dynamic> questionsJson = jsonDecode(jsonString);

      // Shuffle questions and select 3
      questionsJson.shuffle(Random());
      final List<QuizQuestion> selectedQuestions = questionsJson.take(3).map((questionJson) {
        // Get original options and correct answer index
        List<String> options = List<String>.from(questionJson['options']);
        int originalCorrectIndex = questionJson['correctAnswerIndex'];

        // Create a list of indices and shuffle them
        List<int> indices = List.generate(options.length, (index) => index);
        indices.shuffle(Random());

        // Create shuffled options and find new correct answer index
        List<String> shuffledOptions = indices.map((i) => options[i]).toList();
        int newCorrectIndex = indices.indexOf(originalCorrectIndex);

        return QuizQuestion(
          question: questionJson['question'],
          options: shuffledOptions,
          correctAnswerIndex: newCorrectIndex,
        );
      }).toList();

      setState(() {
        _currentChallenge = QuizChallenge(
          id: 'quiz',
          questions: selectedQuestions,
        );
      });
    } catch (e) {
      // Handle error (e.g., show error message or use fallback questions)
      print('Error loading JSON: $e');
      setState(() {
        _currentChallenge = QuizChallenge(
          id: 'fallback',
          questions: [
            QuizQuestion(
              question: 'Error loading questions. Try this: What is 2+2?',
              options: ['3', '4', '5', '6'],
              correctAnswerIndex: 1,
            ),
          ],
        );
      });
    }
  }

  @override
  void dispose() {
    _kartAnimationController.dispose();
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
          handleFailure(context, widget.chestId, "Time's up!");
        }
      });
    });
    // Reset and start kart animation
    _kartAnimationController.reset();
    _kartAnimationController.reverse(from: 1.0); // Run in reverse for countdown
  }

  void _handleAnswer(int selectedIndex) {
    setState(() {
      _answerSelected = true;
      _selectedAnswerIndex = selectedIndex;
    });

    if (selectedIndex ==
        _currentChallenge.questions[_currentQuestionIndex].correctAnswerIndex) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (_currentQuestionIndex < _currentChallenge.questions.length - 1) {
          setState(() {
            _currentQuestionIndex++;
            _answerSelected = false;
            _selectedAnswerIndex = -1;
          });
        } else {
          _timer.cancel();
          endGame(true);
        }
      });
    } else {
      Future.delayed(Duration(milliseconds: 500), () {
        _timer.cancel();
        handleFailure(context, widget.chestId, "Réponse est incorrecte !");
      });
    }
  }

  void endGame(bool won) {
    if (mounted) {
      setState(() {
        isGameOver = true;
      });
    }
    _timer.cancel();
    if (won) {
      handleSuccess(context, widget.chestId, 2500);
    } else {
      handleFailure(context, widget.chestId, "Le temps est écoulé ou la réponse est incorrecte !");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentChallenge.questions.isEmpty) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentQuestion = _currentChallenge.questions[_currentQuestionIndex];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Scaffold(
          body: Opacity(
            opacity: _animation.value,
            child: Stack(
              children: [
                // background
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/quiz/q_bg.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // items
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Image.asset('assets/images/quiz/title.png'),
                      ),
                      // main game
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // question
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Center(
                                child: Text(
                                  currentQuestion.question,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'myFont',
                                    fontSize: 24,
                                    color: themeCtrl.textColor,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 25),
                            // options
                            ...List.generate(
                              currentQuestion.options.length,
                                  (index) => GestureDetector(
                                onTap:
                                _answerSelected
                                    ? null
                                    : () => _handleAnswer(index),
                                child: Container(
                                  width: double.infinity,
                                  margin: EdgeInsets.only(bottom: 15),
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: _getOptionColor(index),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      currentQuestion.options[index],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'myFont',
                                        fontSize: 20,
                                        color: _answerSelected &&
                                            (index == _selectedAnswerIndex ||
                                                index ==
                                                    _currentChallenge
                                                        .questions[_currentQuestionIndex]
                                                        .correctAnswerIndex)
                                            ? themeCtrl.textColor
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // stats
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/timer.png',
                              height: 50,
                            ),
                            Column(
                              children: [
                                Text(
                                  '$_timeLeft',
                                  style: TextStyle(
                                    fontFamily: 'myFont',
                                    color: themeCtrl.textColor,
                                    fontSize: 32,
                                  ),
                                ),
                                Text(
                                  'SEC',
                                  style: TextStyle(
                                    fontFamily: 'myFont',
                                    color: themeCtrl.textColor,
                                    fontSize: 24,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 50, // Adjust height to match road image
                              child: Stack(
                                children: [
                                  // Road image (full width)
                                  Image.asset(
                                    'assets/images/road.png',
                                    fit: BoxFit.cover,
                                  ),
                                  // Kart image animated horizontally
                                  AnimatedBuilder(
                                    animation: _kartAnimationController,
                                    builder: (context, child) {
                                      // Calculate horizontal offset (1.0 to 0.0 maps to left-to-right)
                                      double offsetX =
                                          _kartAnimationController.value *
                                              200; // Adjust 200 based on road width
                                      return Transform.translate(
                                        offset: Offset(offsetX, 0),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Transform.translate(
                                            offset: Offset(0, -2),
                                            child: Image.asset(
                                              'assets/images/kart.png',
                                              height: 30,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

    if (index ==
        _currentChallenge.questions[_currentQuestionIndex].correctAnswerIndex) {
      return Color(0xff3ab54a);
    }

    if (index == _selectedAnswerIndex) {
      return Colors.red;
    }

    return Colors.white;
  }
}
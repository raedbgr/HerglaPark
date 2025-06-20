import '/imports.dart';

class CardMatch extends StatefulWidget {
  final String chestId;

  const CardMatch({super.key, required this.chestId});

  @override
  State<CardMatch> createState() => _CardMatchState();
}

class _CardMatchState extends State<CardMatch> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Game constants
  final int gridSize = 4; // 4x4 grid
  final int totalCards = 16; // 16 cards (8 pairs)
  final int gameDuration = 30; // 30 seconds
  final int pairsToWin = 8; // 8 pairs to match
  final Duration flipDuration = Duration(milliseconds: 300); // Flip animation

  // Game state
  List<IconData> cardIcons = []; // Shuffled icons for cards
  List<bool> cardFaceUp = []; // Is card face-up?
  List<bool> cardMatched = []; // Is card matched?
  List<int> flippedCards = []; // Indices of currently flipped cards
  int pairsMatched = 0; // Number of pairs matched
  int timeLeft = 30; // Time remaining
  bool isGameOver = false; // Game over flag
  bool isFlipping = false; // Prevent taps during flip animation
  Timer? gameTimer;

  // Countdown state
  int countdown = 3; // Start at 3
  bool isCountingDown = true; // Countdown active
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();

    // Setup page animation
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // Initialize cards
    _initializeCards();

    // Start countdown
    startCountdown();
  }

  void _initializeCards() {
    // Define 8 unique icons for pairs
    final List<IconData> icons = [
      Icons.star,
      Icons.favorite,
      Icons.circle,
      Icons.square,
      Icons.music_note,
      Icons.lightbulb,
      Icons.water_drop,
      Icons.pets,
    ];

    // Create pairs and shuffle
    cardIcons = [...icons, ...icons]..shuffle(Random());
    cardFaceUp = List.generate(totalCards, (_) => false);
    cardMatched = List.generate(totalCards, (_) => false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    gameTimer?.cancel();
    countdownTimer?.cancel();
    super.dispose();
  }

  void startCountdown() {
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (countdown > 0) {
            countdown--;
          } else {
            isCountingDown = false;
            timer.cancel();
            startGame();
          }
        });
      }
    });
  }

  void startGame() {
    setState(() {
      pairsMatched = 0;
      timeLeft = gameDuration;
      isGameOver = false;
      _initializeCards();
    });

    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (timeLeft > 0) {
            timeLeft--;
          } else {
            timer.cancel();
            endGame(false);
          }
        });
      }
    });
  }

  void flipCard(int index) {
    if (isCountingDown || isGameOver || isFlipping || cardFaceUp[index] || cardMatched[index]) return;

    setState(() {
      cardFaceUp[index] = true;
      flippedCards.add(index);
    });

    if (flippedCards.length == 2) {
      isFlipping = true;
      final first = flippedCards[0];
      final second = flippedCards[1];

      if (cardIcons[first] == cardIcons[second]) {
        // Match found
        setState(() {
          cardMatched[first] = true;
          cardMatched[second] = true;
          pairsMatched++;
          flippedCards.clear();
          isFlipping = false;
          if (pairsMatched >= pairsToWin) {
            endGame(true);
          }
        });
      } else {
        // No match, flip back after delay
        Future.delayed(Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              cardFaceUp[first] = false;
              cardFaceUp[second] = false;
              flippedCards.clear();
              isFlipping = false;
            });
          }
        });
      }
    }
  }

  void endGame(bool won) {
    if (mounted) {
      setState(() {
        isGameOver = true;
      });
    }
    gameTimer?.cancel();
    if (won) {
      handleSuccess();
    } else {
      handleFailure("Time's up or not all pairs matched!");
    }
  }

  void handleSuccess() {
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
                      'You matched all pairs!',
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
                        Get.back();
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

  void handleFailure(String reason) {
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
                Navigator.of(context).pop();
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
          Get.back();
        }
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Card Match Challenge'),
            automaticallyImplyLeading: true,
          ),
          body: Opacity(
            opacity: _animation.value,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'Pairs Matched: $pairsMatched/$pairsToWin',
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
                            flex: timeLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: timeLeft > 20 ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: gameDuration - timeLeft,
                            child: Container(),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20, top: 5),
                      child: Text(
                        '$timeLeft seconds left',
                        style: TextStyle(
                          color: timeLeft > 20 ? Colors.green : Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridSize,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: totalCards,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => flipCard(index),
                              child: AnimatedContainer(
                                duration: flipDuration,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black54),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Stack(
                                  children: [
                                    // Back face
                                    Opacity(
                                      opacity: cardFaceUp[index] || cardMatched[index] ? 0.0 : 1.0,
                                      child: Image.asset('assets/images/card_back.png'),
                                    ),
                                    // Front face
                                    Opacity(
                                      opacity: cardFaceUp[index] || cardMatched[index] ? 1.0 : 0.0,
                                      child: Container(
                                        color: themeCtrl.primaryColor,
                                        child: Center(
                                          child: Icon(
                                            cardIcons[index],
                                            size: 40,
                                            color: themeCtrl.secondaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                if (isCountingDown)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: countdown / 3,
                              strokeWidth: 8,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$countdown',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
}
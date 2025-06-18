import '/imports.dart';
import 'dart:async';
import 'dart:math';

class WhackAMole extends StatefulWidget {
  final String chestId;
  final Function onSuccess;
  final Function onFailure;

  const WhackAMole({
    super.key,
    required this.chestId,
    required this.onSuccess,
    required this.onFailure,
  });

  @override
  WhackAMoleState createState() => WhackAMoleState();
}

class WhackAMoleState extends State<WhackAMole> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Game constants
  final int gridSize = 3; // 3x3 grid
  final int totalHoles = 9;
  final int gameDuration = 30; // 30 seconds
  final int scoreToWin = 20; // Points needed to win
  final int moleStayTime = 1000; // 1 second per mole
  final int minInterval = 1000; // Min 1 second between moles
  final int maxInterval = 2000; // Max 2 seconds between moles

  // Game state
  List<bool> moles = List.generate(9, (_) => false); // Mole visibility
  int score = 0; // Current score
  int timeLeft = 30; // Time remaining
  bool isGameOver = false; // Game over flag
  Timer? gameTimer;
  Timer? moleTimer;

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

    // Start game
    startGame();
  }

  @override
  void dispose() {
    _animationController.dispose();
    gameTimer?.cancel();
    moleTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    setState(() {
      score = 0;
      timeLeft = gameDuration;
      isGameOver = false;
      moles = List.generate(totalHoles, (_) => false);
    });

    // Start game timer
    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (timeLeft > 0) {
            timeLeft--;
          } else {
            timer.cancel();
            endGame(false); // Time's up, game over
          }
        });
      }
    });

    // Start mole appearances
    showMole();
  }

  void showMole() {
    if (isGameOver) return;

    int holeIndex = Random().nextInt(totalHoles);
    if (mounted) {
      setState(() {
        moles[holeIndex] = true;
      });
    }

    // Hide mole after moleStayTime
    Timer(Duration(milliseconds: moleStayTime), () {
      if (moles[holeIndex] && mounted) {
        setState(() {
          moles[holeIndex] = false;
        });
      }
    });

    // Schedule next mole
    int nextInterval = minInterval + Random().nextInt(maxInterval - minInterval);
    moleTimer = Timer(Duration(milliseconds: nextInterval), showMole);
  }

  void hitMole(int index) {
    if (moles[index] && !isGameOver && mounted) {
      setState(() {
        moles[index] = false;
        score++;
        if (score >= scoreToWin) {
          endGame(true); // Win condition met
        }
      });
    }
  }

  void endGame(bool won) {
    if (mounted) {
      setState(() {
        isGameOver = true;
      });
    }
    gameTimer?.cancel();
    moleTimer?.cancel();
    if (won) {
      handleSuccess();
    } else {
      handleFailure("Time's up or not enough points!");
    }
  }

  void handleSuccess() {
    FirebaseFirestore.instance.collection('chests').doc(widget.chestId).get().then((chestDoc) {
      if (chestDoc.exists && mounted) {
        final chestData = chestDoc.data() as Map<String, dynamic>;
        final bonusType = chestData['bonusType'] as String;

        // Generate QR code
        final qrCode = _generateRandomNumericString(15);

        // Create bonus
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

          // Save bonus to Firestore
          FirebaseFirestore.instance.collection('bonus').doc(bonusId).set(bonus.toJson());

          // Update user's chestsOpened counter
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

          // Show success dialog
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
                        widget.onSuccess();
                        Navigator.of(context).pop();
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

          // Remove chest
          FirebaseFirestore.instance.collection('chests').doc(widget.chestId).delete();
        }
      }
    });
  }

  void handleFailure(String reason) {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: true, // Allow tapping outside to dismiss
        builder: (context) => AlertDialog(
          title: Text('Challenge Failed'),
          content: Text('$reason You can try again in 5 minutes.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog only
              },
              child: Text('OK'),
            ),
          ],
        ),
      ).then((_) {
        // Close bottom sheet and trigger onFailure after dialog dismissal
        if (mounted && Navigator.canPop(context)) {
          FirebaseFirestore.instance.collection('chests').doc(widget.chestId).update({
            'cooldownUntil': FieldValue.serverTimestamp(),
          });
          widget.onFailure();
          Navigator.of(context).pop(); // Close bottom sheet
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
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'Whack-a-Mole Challenge',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Score: $score/$scoreToWin',
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
                              color: timeLeft > 10 ? Colors.green : Colors.red,
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
                        color: timeLeft > 10 ? Colors.green : Colors.red,
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
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: totalHoles,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => hitMole(index),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: moles[index]
                                    ? Image.asset('assets/images/char_normal_mole.png')
                                    : Image.asset('assets/images/bg_hole.png'),
                              ),
                            ),
                          );
                        },
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
}
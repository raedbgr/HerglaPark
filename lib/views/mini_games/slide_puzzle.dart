import '/imports.dart';

class SlidePuzzle extends StatefulWidget {
  final String chestId;

  const SlidePuzzle({super.key, required this.chestId});

  @override
  State<SlidePuzzle> createState() => _SlidePuzzleState();
}

class _SlidePuzzleState extends State<SlidePuzzle> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Game constants
  final int gridSize = 3; // 3x3 grid
  final int totalTiles = 9; // 9 tiles (1-8 + empty)
  final int gameDuration = 60; // 60 seconds
  final Duration slideDuration = Duration(milliseconds: 200); // Slide animation

  // Game state
  List<int> tiles = []; // Tile numbers (1-8, 0 for empty)
  int emptyIndex = 8; // Index of empty tile
  int moves = 0; // Move count
  int timeLeft = 60; // Time remaining
  bool isGameOver = false; // Game over flag
  bool isSliding = false; // Prevent taps during slide
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

    // Initialize puzzle
    _initializePuzzle();

    // Start countdown
    startCountdown();
  }

  void _initializePuzzle() {
    // Create solvable puzzle
    do {
      tiles = List.generate(8, (i) => i + 1)..add(0); // [1,2,3,4,5,6,7,8,0]
      tiles.shuffle(Random());
    } while (!_isSolvable(tiles));

    emptyIndex = tiles.indexOf(0);
    moves = 0;
  }

  bool _isSolvable(List<int> puzzle) {
    int inversions = 0;
    for (int i = 0; i < puzzle.length - 1; i++) {
      for (int j = i + 1; j < puzzle.length; j++) {
        if (puzzle[i] != 0 && puzzle[j] != 0 && puzzle[i] > puzzle[j]) {
          inversions++;
        }
      }
    }
    // For 3x3, puzzle is solvable if inversions are even
    return inversions.isEven;
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
      moves = 0;
      timeLeft = gameDuration;
      isGameOver = false;
      _initializePuzzle();
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

  void slideTile(int index) {
    if (isCountingDown || isGameOver || isSliding || tiles[index] == 0) return;

    // Check if tile is adjacent to empty space
    final row = index ~/ gridSize;
    final col = index % gridSize;
    final emptyRow = emptyIndex ~/ gridSize;
    final emptyCol = emptyIndex % gridSize;

    if ((row == emptyRow && (col - emptyCol).abs() == 1) || (col == emptyCol && (row - emptyRow).abs() == 1)) {
      setState(() {
        isSliding = true;
        tiles[emptyIndex] = tiles[index];
        tiles[index] = 0;
        emptyIndex = index;
        moves++;
      });

      // Allow animation to complete
      Future.delayed(slideDuration, () {
        if (mounted) {
          setState(() {
            isSliding = false;
            if (_isSolved()) {
              endGame(true);
            }
          });
        }
      });
    }
  }

  bool _isSolved() {
    for (int i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return tiles.last == 0;
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
      handleFailure("Time's up or puzzle not solved!");
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
                      'You solved the puzzle!',
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
            title: Text('Slide Puzzle Challenge'),
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
                            'Moves: $moves',
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
                      child: Center(
                        child: Container(
                          width: 310,
                          height: 310,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: List.generate(totalTiles, (index) {
                              final row = index ~/ gridSize;
                              final col = index % gridSize;
                              final tile = tiles[index];
                              return AnimatedPositioned(
                                duration: slideDuration,
                                curve: Curves.easeInOut,
                                left: col * 100.0,
                                top: row * 100.0,
                                child: GestureDetector(
                                  onTap: () => slideTile(index),
                                  child: Container(
                                    width: 92,
                                    height: 92,
                                    decoration: BoxDecoration(
                                      color: tile == 0 ? Colors.transparent : themeCtrl.primaryColor,
                                      borderRadius: BorderRadius.circular(8),
                                      // border: Border.all(color: Colors.black54),
                                    ),
                                    child: Center(
                                      child: tile != 0
                                          ? Text(
                                        '$tile',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: themeCtrl.textColor,
                                        ),
                                      )
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
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
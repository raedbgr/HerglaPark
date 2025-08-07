import '/imports.dart';

class SlidePuzzle extends StatefulWidget {
  final String chestId;

  const SlidePuzzle({super.key, required this.chestId});

  @override
  State<SlidePuzzle> createState() => _SlidePuzzleState();
}

class _SlidePuzzleState extends State<SlidePuzzle> with TickerProviderStateMixin {
  late AnimationController _kartAnimationController;
  late Animation<double> _kartAnimation;
  late AnimationController _pageAnimationController;
  late Animation<double> _pageAnimation;

  // Game constants
  final int gridSize = 3; // 3x3 grid
  final int totalTiles = 9; // 9 tiles (1-8 + empty)
  final int gameDuration = 60;
  final Duration slideDuration = Duration(milliseconds: 200); // Slide animation

  // Game state
  List<int> tiles = []; // Tile numbers (1-8, 0 for empty)
  int emptyIndex = 8; // Index of empty tile
  int timeLeft = 60; // Time remaining
  bool isGameOver = false; // Game over flag
  bool isSliding = false; // Prevent taps during slide
  Timer? gameTimer;

  @override
  void initState() {
    super.initState();

    // Setup kart animation controller
    _kartAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: gameDuration), // 90 seconds for kart movement
    );
    _kartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _kartAnimationController, curve: Curves.linear),
    );

    // Setup page animation controller (not used for fade)
    _pageAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500), // Original page fade duration
    );
    _pageAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      // Set begin and end to 1.0 to disable fade
      CurvedAnimation(parent: _pageAnimationController, curve: Curves.linear),
    );
    _pageAnimationController.forward(); // Start with full opacity

    // Initialize puzzle
    _initializePuzzle();
    startGame();
  }

  void _initializePuzzle() {
    // Create solvable puzzle
    do {
      tiles = List.generate(8, (i) => i + 1)..add(0); // [1,2,3,4,5,6,7,8,0]
      tiles.shuffle(Random());
    } while (!_isSolvable(tiles));

    emptyIndex = tiles.indexOf(0);
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
    _kartAnimationController.dispose();
    _pageAnimationController.dispose();
    gameTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    setState(() {
      timeLeft = gameDuration;
      isGameOver = false;
      _initializePuzzle();
    });

    // Reset and start kart animation
    _kartAnimationController.reset();
    _kartAnimationController.reverse(from: 1.0); // Run in reverse for countdown

    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (timeLeft > 0) {
            timeLeft--;
          } else {
            timer.cancel();
            _kartAnimationController.stop();
            endGame(false);
          }
        });
      }
    });
  }

  void slideTile(int index) {
    if (isGameOver || isSliding || tiles[index] == 0) return;

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
      });

      // Allow animation to complete
      Future.delayed(slideDuration, () {
        if (mounted) {
          setState(() {
            isSliding = false;
            if (_isSolved()) {
              _kartAnimationController.stop();
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
    _kartAnimationController.stop();
    if (won) {
      handleSuccess(context, widget.chestId, 2000);
    } else {
      handleFailure(context, widget.chestId, "Le temps est écoulé ou le puzzle n’a pas été résolue !");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pageAnimation,
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              // background
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/kart_slide/ks_bg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // items
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // title & description
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Image.asset('assets/images/kart_slide/title.png'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'Fais glisser les cases et reconstitue l\'image le plus vite possible',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'myFont',
                              fontSize: 24,
                              color: themeCtrl.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // main game
                    Expanded(
                      child: Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final containerSize = MediaQuery.of(context).size.width * 0.85; // 85% of screen width
                            final tileSize = (containerSize - 16) / gridSize; // Subtract padding (8 * 2)
                            return Container(
                              width: containerSize,
                              height: containerSize,
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Stack(
                                  children: List.generate(totalTiles, (index) {
                                    final row = index ~/ gridSize;
                                    final col = index % gridSize;
                                    final tile = tiles[index];
                                    return AnimatedPositioned(
                                      duration: slideDuration,
                                      curve: Curves.easeInOut,
                                      left: col * tileSize,
                                      top: row * tileSize,
                                      child: GestureDetector(
                                        onTap: () => slideTile(index),
                                        child: SizedBox(
                                          width: tileSize,
                                          height: tileSize,
                                          child: Center(
                                            child: tile != 0
                                                ? Image.asset('assets/images/kart_slide/$tile.png')
                                                : Image.asset('assets/images/kart_slide/place_holder.png'),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // stats
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/timer.png', height: 50),
                          Column(
                            children: [
                              Text(
                                '$timeLeft',
                                style: TextStyle(
                                  fontFamily: 'myFont',
                                  color: themeCtrl.textColor,
                                  fontSize: 36,
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
                                    double offsetX = _kartAnimationController.value * 200; // Adjust 200 based on road width
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
        );
      },
    );
  }
}
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
  final int gameDuration = 40;
  final int pairsToWin = 8; // 8 pairs to match
  final Duration flipDuration = Duration(milliseconds: 300); // Flip animation

  // Game state
  List cardIcons = []; // Shuffled icons for cards
  List<bool> cardFaceUp = []; // Is card face-up?
  List<bool> cardMatched = []; // Is card matched?
  List<int> flippedCards = []; // Indices of currently flipped cards
  int pairsMatched = 0; // Number of pairs matched
  int timeLeft = 40; // Time remaining
  bool isGameOver = false; // Game over flag
  bool isFlipping = false; // Prevent taps during flip animation
  Timer? gameTimer;

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
    startGame();
  }

  void _initializeCards() {
    // Define 8 unique icons for pairs
    final List icons = [
      'assets/images/card_match/icon_1.png',
      'assets/images/card_match/icon_2.png',
      'assets/images/card_match/icon_3.png',
      'assets/images/card_match/icon_4.png',
      'assets/images/card_match/icon_5.png',
      'assets/images/card_match/icon_6.png',
      'assets/images/card_match/icon_7.png',
      'assets/images/card_match/icon_8.png',
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
    super.dispose();
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
    if (isGameOver || isFlipping || cardFaceUp[index] || cardMatched[index]) return;

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
      handleSuccess(context, widget.chestId, 1000);
    } else {
      handleFailure(context, widget.chestId, "Le temps est écoulé ou toutes les paires ne sont pas trouvées !");
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      image: AssetImage('assets/images/card_match/cm_bg.png'),
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
                            child: Image.asset('assets/images/card_match/title.png'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'Retourne les cartes et trouve les paires le plus vite possible pour gagner des points !',
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
                      Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: GridView.builder(
                              shrinkWrap: true,
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
                                    child: Stack(
                                      children: [
                                        // Back face
                                        Opacity(
                                          opacity: cardFaceUp[index] || cardMatched[index] ? 0.0 : 1.0,
                                          child: Image.asset('assets/images/card_match/card_back.png'),
                                        ),
                                        // Front face
                                        Opacity(
                                          opacity: cardFaceUp[index] || cardMatched[index] ? 1.0 : 0.0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              image: DecorationImage(image: AssetImage('assets/images/card_match/card_front.png'))
                                            ),
                                            child: Center(
                                              child: Transform.translate(
                                                offset: Offset(-2, -2),
                                                child: Image(
                                                  image: AssetImage(cardIcons[index]),
                                                  height: 40,
                                                ),
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
                      // stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 30,
                        children: [
                          SizedBox(),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                border: Border.all(
                                    color: Color(0xffccab21),
                                    width: 3
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    spacing: 10,
                                    children: [
                                      Image.asset('assets/images/timer.png', height: 60,),
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
                                      )
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    spacing: 10,
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            'Score',
                                            style: TextStyle(
                                                fontFamily: 'myFont',
                                                color: themeCtrl.textColor,
                                                fontSize: 24,
                                            ),
                                          ),
                                          Text(
                                              pairsMatched.toString().padLeft(2, '0'),
                                              style: TextStyle(
                                                  fontFamily: 'myFont',
                                                  color: themeCtrl.textColor,
                                                  fontSize: 36,
                                              )
                                          ),
                                        ],
                                      ),
                                      Image.asset('assets/images/score.png', height: 60,)
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(),
                        ],
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
}
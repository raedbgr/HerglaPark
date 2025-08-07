import '/imports.dart';

class WhackAMole extends StatefulWidget {
  final String chestId;

  const WhackAMole({super.key, required this.chestId});

  @override
  WhackAMoleState createState() => WhackAMoleState();
}

class WhackAMoleState extends State<WhackAMole> with TickerProviderStateMixin {
  final int gridSize = 3;
  final int totalHoles = 9;
  final int gameDuration = 60;
  final int scoreToWin = 30;
  final int moleStayTime = 1000;
  final int minInterval = 1000;
  final int maxInterval = 2000;

  List<bool> moles = List.generate(9, (_) => false);
  List<bool> _isTapped = List.generate(9, (_) => false);
  List<bool> _isMissed = List.generate(
    9,
    (_) => false,
  ); // New list for missed taps
  int score = 0;
  int timeLeft = 60;
  bool isGameOver = false;
  Timer? gameTimer;
  Timer? moleTimer;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  @override
  void dispose() {
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
      _isTapped = List.generate(totalHoles, (_) => false);
      _isMissed = List.generate(totalHoles, (_) => false);
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

    showMole();
  }

  void showMole() {
    if (isGameOver) return;

    // Random number of moles to show: between 1 and 3
    final moleCount = 1 + Random().nextInt(3); // 1 to 3 moles

    // Get random unique hole indices to place moles
    final availableIndices = List.generate(totalHoles, (i) => i)..shuffle();
    final selectedIndices = availableIndices.take(moleCount).toList();

    if (mounted) {
      setState(() {
        for (final i in selectedIndices) {
          moles[i] = true;
        }
      });
    }

    // Hide these moles after a delay
    Timer(Duration(milliseconds: moleStayTime), () {
      if (mounted) {
        setState(() {
          for (final i in selectedIndices) {
            moles[i] = false;
          }
        });
      }
    });

    // Schedule the next batch of moles
    final nextInterval =
        minInterval + Random().nextInt(maxInterval - minInterval);
    moleTimer = Timer(Duration(milliseconds: nextInterval), showMole);
  }

  void hitMole(int index) {
    if (isGameOver) return;

    if (moles[index]) {
      setState(() {
        moles[index] = false;
        _isTapped[index] = true;
        score++;
        if (score >= scoreToWin) endGame(true);
      });

      Future.delayed(Duration(milliseconds: 700), () {
        if (mounted) setState(() => _isTapped[index] = false);
      });
    } else {
      setState(() {
        _isMissed[index] = true;
      });

      Future.delayed(Duration(milliseconds: 700), () {
        if (mounted) setState(() => _isMissed[index] = false);
      });
    }
  }

  void endGame(bool won) {
    if (mounted) {
      setState(() => isGameOver = true);
    }
    gameTimer?.cancel();
    moleTimer?.cancel();
    won ? handleSuccess(context, widget.chestId, 1500) : handleFailure(context, widget.chestId, "Le temps est écoulé ou vous n’avez pas assez de points !");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('Whack-a-Mole Challenge')),
      body: Stack(
        children: [
          // background
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/whack_a_kart/wak_bg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/whack_a_kart/wak_fg.png'),
                    fit: BoxFit.cover
                  ),
                ),
              ),
            ],
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
                      child: Image.asset('assets/images/whack_a_kart/title.png'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Tape 30 casques en une minute et gagne un bonus sur ta carte',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'myFont',
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: themeCtrl.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                // main game
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final moleSize = constraints.maxWidth / gridSize - 10;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: List.generate(totalHoles, (index) {
                          return GestureDetector(
                            onTap: () => hitMole(index),
                            child: SizedBox(
                              width: moleSize,
                              height: moleSize,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned.fill(
                                    child: Transform.scale(
                                      scale: 1.2,
                                      child: Image.asset(
                                        'assets/images/whack_a_kart/bg_tire.png',
                                      ),
                                    ),
                                  ),
                                  if (moles[index])
                                    ClipRect(
                                      clipper: MoleArea(),
                                      child: TweenAnimationBuilder<double>(
                                        key: ValueKey(
                                          'mole_$index',
                                        ), // ensures proper re-animation
                                        tween: Tween(begin: moleSize, end: -moleSize * 0.2),
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                        builder: (_, value, child) {
                                          return Transform.translate(
                                            offset: Offset(0.0, value),
                                            child: child!,
                                          );
                                        },
                                        child: SizedBox(
                                          width: moleSize,
                                          height: moleSize,
                                          child: Transform.scale(
                                            scale: 1.2,
                                            child: Image.asset(
                                              'assets/images/whack_a_kart/headset.png',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned.fill(
                                    child: Transform.scale(
                                      scale: 1.2,
                                      child: Image.asset(
                                        'assets/images/whack_a_kart/fg_tire.png',
                                      ),
                                    ),
                                  ),
                                  if (_isTapped[index])
                                    TweenAnimationBuilder(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: const Duration(milliseconds: 100),
                                      builder:
                                          (_, value, child) => Opacity(
                                            opacity: value,
                                            child: Transform.scale(
                                              scale: value,
                                              child: child,
                                            ),
                                          ),
                                      child: Transform.translate(
                                        offset: Offset(0, -15),
                                        child: Transform.scale(
                                          scale: 1.1,
                                          child: Image.asset(
                                            'assets/images/whack_a_kart/fx_normal.png',
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_isMissed[index])
                                    TweenAnimationBuilder(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: const Duration(milliseconds: 100),
                                      builder:
                                          (_, value, child) => Opacity(
                                            opacity: value,
                                            child: Transform.scale(
                                              scale: value,
                                              child: child,
                                            ),
                                          ),
                                      child: Transform.translate(
                                        offset: Offset(0, -15),
                                        child: Transform.scale(
                                          scale: 1.1,
                                          child: Image.asset(
                                            'assets/images/whack_a_kart/fx_none.png',
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      );
                    },
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
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Image.asset('assets/images/timer.png', height: 70,),
                            Column(
                              children: [
                                Text(
                                    '$timeLeft',
                                    style: TextStyle(
                                        fontFamily: 'myFont',
                                        color: themeCtrl.textColor,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold
                                    ),
                                ),
                                Text(
                                    'SEC',
                                    style: TextStyle(
                                        fontFamily: 'myFont',
                                        color: themeCtrl.textColor,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500
                                    ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
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
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                                    score.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                        fontFamily: 'myFont',
                                        color: themeCtrl.textColor,
                                        fontSize: 36,
                                    )
                                ),
                              ],
                            ),
                            Image.asset('assets/images/score.png', height: 70,)
                          ],
                        ),
                      ),
                    ),
                    SizedBox(),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MoleArea extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width, size.height * 0.65);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

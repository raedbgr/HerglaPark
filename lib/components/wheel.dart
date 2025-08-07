import '/imports.dart';

class GameWheelDialog extends StatefulWidget {
  final String chestId;
  const GameWheelDialog({super.key, required this.chestId});

  @override
  _GameWheelDialogState createState() => _GameWheelDialogState();
}

class _GameWheelDialogState extends State<GameWheelDialog> {
  final List<String> gameOptions = [
    '+5000 Points',
    'Kart Slide',
    'Reviens plus tard',
    'Card Match',
    '+500 Points',
    'Quiz Challenge',
    'Tourne Encors !',
    'Whack a Kart',
  ];
  final StreamController<int> _controller = StreamController<int>.broadcast();
  bool _isSpinning = false;
  int? _lastSelectedIndex;

  @override
  void initState() {
    super.initState();
  }

  final Map<String, String> gameRoutes = {
    'Quiz Challenge': '/quiz',
    'Whack a Kart': '/whack_a_mole',
    'Card Match': '/card_match',
    'Kart Slide': '/slide_puzzle',
  };

  final List<Color> sliceColors = [
    Color(0xfffe8e16),
    Color(0xfffdb015),
    Color(0xfff40d6f),
    Color(0xff2ae4ff),
    Color(0xff500c9b),
    Color(0xff008274),
    Color(0xff8c8c8c),
    Color(0xfffe3a0e),
  ];

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  void _spinWheel() {
    if (_isSpinning) return;

    final selected = Random().nextInt(gameOptions.length);
    _lastSelectedIndex = selected;
    _controller.add(selected);
    setState(() => _isSpinning = true);
  }

  void _showResultDialog(String gameType) {
    String title;
    String icon;
    String message;
    String button;
    VoidCallback? onConfirm;

    switch (gameType) {
      case 'Tourne Encors !':
        title = 'Tourne encore';
        icon = 'again.png';
        message =
            'Coup de chance ! Tu peux faire tourner la roue une nouvelle fois. Bonne Chance !';
        button = 'Continuer';
        onConfirm = () {
          Get.back(); // Close the alert
        };
        break;
      case '+5000 Points':
        title = '+5000 points';
        icon = 'bonus.png';
        message =
            'Félicitations! Tu viens de gagner +5000 points sur votre carte.';
        button = 'Continuer';
        onConfirm = () async {
          await rewardUserPoints(10, 5000, widget.chestId);
          Get.back(); // Close the alert
          Get.back(); // Close the wheel dialog
        };
        break;
      case '+500 Points':
        title = '+500 points';
        icon = 'bonus.png';
        message = 'Bravo ! Tu gagner +500 points bonus, bien joué.';
        button = 'Continuer';
        onConfirm = () async {
          await rewardUserPoints(5, 500, widget.chestId);
          Get.back(); // Close the alert
          Get.back(); // Close the wheel dialog
        };
        break;
      case 'Reviens plus tard':
        icon = 'later.png';
        title = 'Reviens plus tard';
        message =
            'Pas cette fois ! puis reviens dans quelques minutes pour retenter votre chance.';
        button = 'Continuer';
        onConfirm = () {
          FirebaseFirestore.instance
              .collection('chests')
              .doc(widget.chestId)
              .update({'cooldownUntil': FieldValue.serverTimestamp()});
          Get.back(); // Close the alert
          Get.back(); // Close the wheel dialog
        };
        break;
      case 'Card Match':
        icon = 'card_match.png';
        title = 'Card Match';
        message =
            'Retrouve les paires cachées le plus bite possible et marque un max de points !';
        button = 'Jouer';
        onConfirm = () {
          Get.back(); // Close the alert
          Get.back(); // Close the wheel dialog
          final route = gameRoutes[gameType];
          if (route != null) {
            Get.toNamed(route, arguments: {'chestId': widget.chestId});
          }
        };
        break;
      case 'Kart Slide':
        icon = 'kart_slide.png';
        title = 'Kart Slide';
        message =
            'À toi de jouer au puzzle galissant ! Rassemble les piéces avant la fin du chrono.';
        button = 'Jouer';
        onConfirm = () {
          Get.back(); // Close the alert
          Get.back(); // Close the wheel dialog
          final route = gameRoutes[gameType];
          if (route != null) {
            Get.toNamed(route, arguments: {'chestId': widget.chestId});
          }
        };
        break;
      case 'Quiz Challenge':
        icon = 'quiz.png';
        title = 'Quiz Challenge';
        message =
            'Réponds rapidement aux questions et remporte des récompenses !';
        button = 'Jouer';
        onConfirm = () {
          Get.back(); // Close the alert
          Get.back(); // Close the wheel dialog
          final route = gameRoutes[gameType];
          if (route != null) {
            Get.toNamed(route, arguments: {'chestId': widget.chestId});
          }
        };
        break;
      default:
        icon = 'whack_a_kart.png';
        title = 'Whack a Kart';
        message =
            'Tape vite sur les casques avant qu\'ils disparaissent pour remporter ton défi !';
        button = 'Jouer';
        onConfirm = () {
          Get.back(); // Close the alert
          Get.back(); // Close the wheel dialog
          final route = gameRoutes[gameType];
          if (route != null) {
            Get.toNamed(route, arguments: {'chestId': widget.chestId});
          }
        };
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 15,
                children: [
                  Image.asset('assets/images/alerts/$icon', height: 120),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'myFont',
                      fontSize: 24,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(),
                  InkWell(
                    onTap: onConfirm,
                    splashColor: Colors.black.withValues(alpha: 0.3),
                    child: Ink(
                      padding: EdgeInsets.symmetric(
                        vertical: 3,
                        horizontal: 30,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        button,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: themeCtrl.textColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 20,
        children: [
          Container(
            padding: EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xff43c3df),
                  Color(0xfffa3cc8),
                  Color(0xfffedc31),
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xfff32025),
                    Color(0xfff32025),
                    Color(0xffff5626),
                    Color(0xff9d1820),
                    Color(0xff9d1820),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Container(
                padding: EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xfffedc31),
                      Color(0xfffa3cc8),
                      Color(0xff43c3df),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: Stack(
                    children: [
                      FortuneWheel(
                        selected: _controller.stream,
                        animateFirst: false,
                        items: List.generate(gameOptions.length, (index) {
                          return FortuneItem(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 30),
                              child: Transform.translate(
                                offset: Offset(22, 0),
                                child: Text(
                                  gameOptions[index],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: themeCtrl.textColor,
                                    fontFamily: 'myFont',
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                            style: FortuneItemStyle(
                              color: sliceColors[index % sliceColors.length],
                              borderWidth: 0,
                            ),
                          );
                        }),
                        indicators: <FortuneIndicator>[
                          FortuneIndicator(
                            alignment: Alignment.topCenter,
                            child: Transform.translate(
                              offset: Offset(0, -20),
                              child: CustomGradientTriangleIndicator(),
                            ),
                          ),
                        ],
                        onAnimationEnd: () {
                          if (_lastSelectedIndex != null) {
                            final selectedGame =
                                gameOptions[_lastSelectedIndex!];
                            setState(
                              () => _isSpinning = false,
                            ); // Reset spinning state
                            _showResultDialog(
                              selectedGame,
                            ); // Show result alert
                            // Keep dialog open to allow further spins
                          }
                        },
                      ),
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xff43c3df),
                                Color(0xff43c3df),
                                Color(0xff43c3df),
                                Color(0xfffa3cc8),
                                Color(0xfffedc31),
                                Color(0xfffedc31),
                                Color(0xfffedc31),
                              ],
                              begin: Alignment.bottomRight,
                              end: Alignment.topLeft,
                            ),
                          ),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xff121615), Color(0xff303030)],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          InkWell(
            onTap: _isSpinning ? null : _spinWheel,
            splashColor: Colors.black.withValues(alpha: 0.3),
            highlightColor: Colors.black.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(50),
            child: Ink(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 40),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(50),
                gradient: LinearGradient(
                  colors: [
                    Color(0xffde6771),
                    Color(0xffba1b22),
                    Color(0xffaa0000),
                    Color(0xffa70000),
                    Color(0xffa70000),
                    Color(0xffea0000),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Text(
                'SPIN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'myFont',
                  fontSize: 28,
                  color: themeCtrl.textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomGradientTriangleIndicator extends StatelessWidget {
  const CustomGradientTriangleIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40, // Adjust size as needed
      height: 40, // Adjust size as needed
      child: CustomPaint(painter: TrianglePainter()),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..shader = LinearGradient(
            colors: [
              Color(0xfffedc31),
              Color(0xfffa3cc8),
              Color(0xff43c3df),
            ], // Blue to yellow gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path =
        Path()
          ..moveTo(size.width / 2, size.height) // Bottom center
          ..lineTo(0, 0) // Top-left
          ..lineTo(size.width, 0) // Top-right
          ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

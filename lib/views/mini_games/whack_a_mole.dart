import '/imports.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class WhackAMole extends StatefulWidget {
  final String chestId;

  const WhackAMole({super.key, required this.chestId});

  @override
  WhackAMoleState createState() => WhackAMoleState();
}

class WhackAMoleState extends State<WhackAMole> with TickerProviderStateMixin {
  final int gridSize = 3;
  final int totalHoles = 9;
  final int gameDuration = 30;
  final int scoreToWin = 20;
  final int moleStayTime = 1000;
  final int minInterval = 1000;
  final int maxInterval = 2000;

  List<bool> moles = List.generate(9, (_) => false);
  List<bool> _isTapped = List.generate(9, (_) => false);
  int score = 0;
  int timeLeft = 30;
  bool isGameOver = false;
  Timer? gameTimer;
  Timer? moleTimer;

  int countdown = 3;
  bool isCountingDown = true;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    moleTimer?.cancel();
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
      score = 0;
      timeLeft = gameDuration;
      isGameOver = false;
      moles = List.generate(totalHoles, (_) => false);
      _isTapped = List.generate(totalHoles, (_) => false);
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

    int holeIndex = Random().nextInt(totalHoles);
    if (mounted) {
      setState(() {
        moles[holeIndex] = true;
      });
    }

    Timer(Duration(milliseconds: moleStayTime), () {
      if (mounted) {
        setState(() => moles[holeIndex] = false);
      }
    });

    int nextInterval = minInterval + Random().nextInt(maxInterval - minInterval);
    moleTimer = Timer(Duration(milliseconds: nextInterval), showMole);
  }

  void hitMole(int index) {
    if (isCountingDown || isGameOver || !moles[index]) return;

    setState(() {
      moles[index] = false;
      _isTapped[index] = true;
      score++;
      if (score >= scoreToWin) endGame(true);
    });

    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) setState(() => _isTapped[index] = false);
    });
  }

  void endGame(bool won) {
    if (mounted) {
      setState(() => isGameOver = true);
    }
    gameTimer?.cancel();
    moleTimer?.cancel();
    won ? handleSuccess() : handleFailure("Time's up or not enough points!");
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
            final currentCount = userDoc.exists ? (userDoc.data()?['chestsOpened'] ?? 0) : 0;
            FirebaseFirestore.instance.collection('users').doc(userId).set({
              'chestsOpened': currentCount + 1,
            }, SetOptions(merge: true));
          });

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.amber.withOpacity(0.2),
                      child: Icon(Icons.emoji_events, size: 60, color: Colors.amber),
                    ),
                    SizedBox(height: 20),
                    Text('Congratulations!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text('You have successfully opened the chest!', textAlign: TextAlign.center),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          Text('You\'ve earned:', style: TextStyle(fontSize: 16)),
                          SizedBox(height: 10),
                          Text(
                            _getBonusTypeDescription(bonusType),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getBonusTypeColor(bonusType)),
                          ),
                          SizedBox(height: 5),
                          Text('Check your profile to use your reward!', style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getBonusTypeColor(bonusType),
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Get.back();
                      },
                      child: Text('Awesome!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              onPressed: () => Navigator.of(context).pop(),
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
    return List.generate(length, (_) => Random().nextInt(10)).join();
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
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Score: $score / $scoreToWin', style: TextStyle(fontSize: 16)),
                ),
                LinearProgressIndicator(
                  value: timeLeft / gameDuration,
                  backgroundColor: Colors.grey[300],
                  color: timeLeft > 10 ? Colors.green : Colors.red,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Text('$timeLeft seconds left', style: TextStyle(color: timeLeft > 10 ? Colors.green : Colors.red)),
                ),
                Expanded(
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
                                  Positioned.fill(child: Image.asset('assets/images/bg_hole.png')),
                                  if (moles[index])
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 60.0, end: 10.0),
                                      duration: const Duration(milliseconds: 300),
                                      builder: (_, value, child) {
                                        return Positioned(
                                          top: value,
                                          child: ClipRect(
                                            clipper: MoleArea(),
                                            child: SizedBox(
                                              width: moleSize,
                                              height: moleSize,
                                              child: Image.asset('assets/images/char_normal_mole.png'),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  Positioned.fill(child: Image.asset('assets/images/fg_hole.png')),
                                  if (_isTapped[index])
                                    TweenAnimationBuilder(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: const Duration(milliseconds: 200),
                                      builder: (_, value, child) => Opacity(
                                        opacity: value,
                                        child: Transform.scale(scale: value, child: child),
                                      ),
                                      child: Image.asset('assets/images/fx_normal.png'),
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
                      Text('$countdown', style: TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MoleArea extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, 0, size.width, size.height * 0.65);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

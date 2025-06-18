import '/imports.dart';

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
  late WamController _controller;

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

    // Initialize and reset controller
    _controller = Get.put(WamController());
    _controller.reset(); // Reset game state
  }

  @override
  void dispose() {
    _animationController.dispose();
    Get.delete<WamController>(); // Clean up controller
    super.dispose();
  }

  void handleSuccess() {
    FirebaseFirestore.instance.collection('chests').doc(widget.chestId).get().then((chestDoc) {
      if (chestDoc.exists) {
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Challenge Failed'),
        content: Text('$reason You can try again in 5 minutes.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onFailure();
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );

    // Update chest with cooldown
    FirebaseFirestore.instance.collection('chests').doc(widget.chestId).update({
      'cooldownUntil': FieldValue.serverTimestamp(),
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
                        Obx(() => Text(
                          'Score: ${_controller.score.value}/${_controller.scoreToWin}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        )),
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
                    child: Obx(() => Row(
                      children: [
                        Expanded(
                          flex: _controller.timeLeft.value,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: _controller.timeLeft.value > 10 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: _controller.gameDuration - _controller.timeLeft.value,
                          child: Container(),
                        ),
                      ],
                    )),
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20, top: 5),
                    child: Obx(() => Text(
                      '${_controller.timeLeft.value} seconds left',
                      style: TextStyle(
                        color: _controller.timeLeft.value > 10 ? Colors.green : Colors.red,
                        fontSize: 14,
                      ),
                    )),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _controller.gridSize,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _controller.totalHoles,
                        itemBuilder: (context, index) {
                          return Obx(() => GestureDetector(
                            onTap: () => _controller.hitMole(index),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: _controller.moles[index]
                                    ? Image.asset('assets/images/char_normal_mole.png')
                                    : Image.asset('assets/images/bg_hole.png'),
                              ),
                            ),
                          ));
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
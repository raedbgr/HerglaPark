import '/imports.dart';

void handleSuccess(BuildContext context, String chestId, int cPoints) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
  final userDoc = await userRef.get();

  if (userDoc.exists && context.mounted) {
    final userData = userDoc.data() as Map<String, dynamic>;
    final int currentCount = userData['chestsOpened'] ?? 0;
    final int currentPoints = userData['points'] ?? 0;

    // Update user main document
    await userRef.set({
      'chestsOpened': currentCount + 1,
      'points': currentPoints + 15,
    }, SetOptions(merge: true));

    // Add point history to subcollection
    await userRef.collection('history').add({
      'pointsGained': cPoints,
      'timestamp': Timestamp.now(),
    });

    // Show dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/alerts/bonus.png', height: 120),
              Text(
                '+$cPoints points',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'myFont',
                  fontSize: 24,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                'Félicitations! Tu viens de gagner +$cPoints points sur votre carte.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  Get.back();
                },
                splashColor: Colors.black.withAlpha(30),
                child: Ink(
                  padding: EdgeInsets.symmetric(vertical: 3, horizontal: 30),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    'Continuer',
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

    // Delete chest
    await FirebaseFirestore.instance.collection('chests').doc(chestId).delete();
  }
}

void handleFailure(BuildContext context, String chestId, String reason) {
  if (context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
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
              Image.asset('assets/images/alerts/locked.png', height: 120,),
              Text(
                'Défi Échoué',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'myFont',
                    fontSize: 24,
                    fontStyle: FontStyle.italic
                ),
              ),
              Text(
                '$reason Vous pourrez réessayer dans 5 minutes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic
                ),
              ),
              SizedBox(),
              InkWell(
                onTap: () {
                  Get.back();
                },
                splashColor: Colors.black.withValues(alpha: 0.3),
                child: Ink(
                  padding: EdgeInsets.symmetric(vertical: 3, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    'OK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: themeCtrl.textColor,
                        fontSize: 16
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      )
    ).then((_) {
      if (context.mounted) {
        FirebaseFirestore.instance
            .collection('chests')
            .doc(chestId)
            .update({'cooldownUntil': FieldValue.serverTimestamp()});
        Get.back();
      }
    });
  }
}

Future<void> rewardUserPoints(uPoints, int cPoints, String chestId) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
  final userDoc = await userRef.get();

  if (!userDoc.exists) return;

  final data = userDoc.data()!;
  final currentCount = data['chestsOpened'] ?? 0;
  final currentPoints = data['points'] ?? 0;

  await userRef.set({
    'chestsOpened': currentCount + 1,
    'points': currentPoints + uPoints,
  }, SetOptions(merge: true));

  await userRef.collection('history').add({
    'pointsGained': cPoints,
    'timestamp': Timestamp.now(),
  });

  await FirebaseFirestore.instance.collection('chests').doc(chestId).delete();
}

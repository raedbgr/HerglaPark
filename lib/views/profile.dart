import '/imports.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int chestsOpened = 0;
  List<Bonus> bonuses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUserBonuses();
  }

  Future<void> _fetchUserData() async {
    if (FirebaseAuth.instance.currentUser != null) {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Get user data from Firestore
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          chestsOpened = userData['chestsOpened'] ?? 0;
        });
      }
    }
  }

  Future<void> _fetchUserBonuses() async {
    setState(() {
      isLoading = true;
    });

    if (FirebaseAuth.instance.currentUser != null) {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Get user's bonuses from Firestore
      QuerySnapshot bonusSnapshot =
          await FirebaseFirestore.instance
              .collection('bonus')
              .where('ownerId', isEqualTo: userId)
              .where('isUsed', isEqualTo: false) // Only show unused bonuses
              .get();

      List<Bonus> fetchedBonuses = [];
      for (var doc in bonusSnapshot.docs) {
        Bonus bonus = Bonus.fromJson(doc.data() as Map<String, dynamic>);
        fetchedBonuses.add(bonus);
      }

      setState(() {
        bonuses = fetchedBonuses;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper method to get bonus icon based on type
  IconData _getBonusIcon(String type) {
    switch (type?.toLowerCase()) {
      case 'vr':
        return Icons.vrpano_rounded;
      case 'karting':
        return Icons.directions_car_rounded;
      case 'shooting':
        return Icons.sports_esports_rounded;
      default:
        return Icons.confirmation_num_rounded;
    }
  }

  // Helper method to get bonus name based on type
  String _getBonusName(String type) {
    switch (type?.toLowerCase()) {
      case 'vr':
        return 'VR Experience';
      case 'karting':
        return 'Karting Session';
      case 'shooting':
        return 'Shooting Session';
      default:
        return 'Park Activity';
    }
  }

  // Helper method to get bonus color based on type
  Color _getBonusColor(String type) {
    switch (type?.toLowerCase()) {
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
      backgroundColor: themeCtrl.primaryColor,
      body: SafeArea(
        child: Stack(
          children: [
            // background image
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 150, left: 10, right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 40),
                  Text(
                    authCtrl.currentUser.value.username ?? 'Player Name',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: themeCtrl.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Column(
                            spacing: 5,
                            children: [
                              Icon(
                                Icons.star_border_rounded,
                                size: 30,
                                color: Colors.white,
                              ),
                              Text(
                                'POINTS',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '1275',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: themeCtrl.secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            spacing: 5,
                            children: [
                              Icon(
                                Icons.view_in_ar_rounded,
                                size: 30,
                                color: Colors.white,
                              ),
                              Text(
                                'CHESTS OPENED',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                chestsOpened.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: themeCtrl.secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            spacing: 5,
                            children: [
                              Icon(
                                Icons.leaderboard_rounded,
                                size: 30,
                                color: Colors.white,
                              ),
                              Text(
                                'RANK',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '#5',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: themeCtrl.secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        Text(
                          'Inventory',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 20),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.only(
                              left: 15,
                              right: 15,
                              bottom: 20,
                            ),
                            decoration: BoxDecoration(
                              color: themeCtrl.primaryColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: themeCtrl.primaryColor,
                                width: 3,
                              ),
                            ),
                            child:
                                isLoading
                                    ? Center(child: CircularProgressIndicator())
                                    : bonuses.isEmpty
                                    ? Center(
                                      child: Text(
                                        'No rewards yet. Go find some chests!',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: themeCtrl.primaryColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                    : GridView.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            childAspectRatio: 1.0,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                          ),
                                      itemCount: bonuses.length,
                                      itemBuilder: (context, index) {
                                        Bonus bonus = bonuses[index];
                                        return GestureDetector(
                                          onTap: () {
                                            // Show bonus details
                                            _showBonusDetails(bonus);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _getBonusColor(
                                                  bonus.type ?? '',
                                                ),
                                                width: 2,
                                              ),
                                            ),
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    _getBonusIcon(
                                                      bonus.type ?? '',
                                                    ),
                                                    size: 40,
                                                    color: _getBonusColor(
                                                      bonus.type ?? '',
                                                    ),
                                                  ),
                                                  SizedBox(height: 5),
                                                  Text(
                                                    _getBonusName(
                                                      bonus.type ?? '',
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
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
                ],
              ),
            ),
            // Profile avatar
            Positioned(
              top: 75,
              // center the avatar
              left: MediaQuery.of(context).size.width / 2 - 55,
              child: CircleAvatar(
                radius: 55,
                backgroundImage: AssetImage('assets/images/player.png'),
              ),
            ),
            // back button
            Positioned(
              top: 16,
              left: 16,
              child: FloatingActionButton(
                heroTag: "backBtn",
                shape: CircleBorder(),
                backgroundColor: Colors.white,
                onPressed: () {
                  Get.back();
                },
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 25,
                  color: themeCtrl.primaryColor,
                ),
              ),
            ),
            // logout button
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: "logoutBtn",
                shape: CircleBorder(),
                backgroundColor: Colors.white,
                onPressed: () {
                  authCtrl.signOut();
                },
                child: Icon(
                  Icons.logout_rounded,
                  size: 25,
                  color: themeCtrl.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to show bonus details dialog
  void _showBonusDetails(Bonus bonus) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getBonusIcon(bonus.type ?? ''),
                    size: 60,
                    color: _getBonusColor(bonus.type ?? ''),
                  ),
                  SizedBox(height: 20),
                  Text(
                    _getBonusName(bonus.type ?? ''),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'QR Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          bonus.qrCode ?? 'No QR Code',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Show this code to the park staff',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Expires on: ${_formatDate(bonus.expiresAt)}',
                    style: TextStyle(fontSize: 14, color: Colors.red),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeCtrl.primaryColor,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Helper method to format date
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';

    DateTime date = timestamp.toDate();
    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

import '/imports.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
                  image: AssetImage('assets/background.png'),
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
                                authCtrl.currentUser.value.chestsOpened
                                    .toString(),
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
                  Expanded(child: Column(
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
                          margin: EdgeInsets.only(left: 15, right: 15, bottom: 20),
                          decoration: BoxDecoration(
                            color: themeCtrl.primaryColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: themeCtrl.primaryColor,
                              width: 3,
                            ),
                          ),
                          child: GridView(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.0,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            children: List.generate(6, (index) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.confirmation_num_rounded,
                                        size: 40,
                                        color: themeCtrl.primaryColor,
                                      ),
                                      Text(
                                        'VR Ticket',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          )
                        ),
                      ),
                    ],
                  )),
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
                backgroundImage: AssetImage('assets/player.png'),
              ),
            ),
            // back button
            Positioned(
              top: 16,
              left: 16,
              child: FloatingActionButton(
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
}

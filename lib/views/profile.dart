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
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    color: themeCtrl.primaryColor,
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Text(
                              'Chests Opened',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              authCtrl.currentUser.value.chestsOpened.toString(),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      ]
                    ),
                  )
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
                shape: CircleBorder(),
                backgroundColor: themeCtrl.primaryColor,
                onPressed: () {
                  Get.back();
                },
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 25,
                  color: Colors.white,
                ),
              ),
            ),
            // logout button
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton(
                shape: CircleBorder(),
                backgroundColor: themeCtrl.primaryColor,
                onPressed: () {
                  authCtrl.signOut();
                },
                child: Icon(
                  Icons.logout_rounded,
                  size: 25,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
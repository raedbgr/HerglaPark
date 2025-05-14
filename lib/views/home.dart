import '/imports.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: homeCtrl.onMapCreated,
              initialCameraPosition: homeCtrl.initialPosition,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),
            // Leaderboard Button (Top-Left)
            Positioned(
              top: 16,
              left: 16,
              child: FloatingActionButton(
                shape: CircleBorder(),
                backgroundColor: Color(0xfff3edce),
                onPressed: () {
                  // leaderboard logic
                  Get.toNamed('/leaderboard');
                },
                child: Icon(
                  Icons.emoji_events,
                  size: 25,
                  color: Color(0xff15b0b1),
                ),
              ),
            ),

            // Profile Button (Top-Right)
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton(
                shape: CircleBorder(),
                backgroundColor: Color(0xfff3edce),
                onPressed: () {
                  Get.toNamed('/profile');
                },
                child: Icon(
                  Icons.person_rounded,
                  size: 25,
                  color: Color(0xff15b0b1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

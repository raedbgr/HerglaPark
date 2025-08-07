import '/imports.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int chestsOpened = 0;
  int points = 0;
  List<PointHistory> history = [];
  bool isLoading = true;
  int userRank = 0;
  final ScrollController _scrollController = ScrollController();
  bool isFetchingMore = false;
  bool hasMore = true;
  DocumentSnapshot? lastDocument;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _fetchInitialUserData();
    _fetchUserRank();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialUserData() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    final userId = FirebaseAuth.instance.currentUser!.uid;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      chestsOpened = userData['chestsOpened'] ?? 0;
      points = userData['points'] ?? 0;
    }

    // Fetch first page of history
    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .limit(_limit);

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      final List<PointHistory> fetched = snapshot.docs
          .map((doc) => PointHistory.fromJson(doc.data()))
          .toList();

      setState(() {
        history = fetched;
        lastDocument = snapshot.docs.last;
        hasMore = snapshot.docs.length == _limit;
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> _fetchMoreHistory() async {
    if (isFetchingMore || !hasMore || FirebaseAuth.instance.currentUser == null) return;

    isFetchingMore = true;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .startAfterDocument(lastDocument!)
        .limit(_limit);

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      final List<PointHistory> fetched = snapshot.docs
          .map((doc) => PointHistory.fromJson(doc.data()))
          .toList();

      setState(() {
        history.addAll(fetched);
        lastDocument = snapshot.docs.last;
        hasMore = snapshot.docs.length == _limit;
      });
    } else {
      hasMore = false;
    }

    isFetchingMore = false;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchMoreHistory();
    }
  }

  // Add this new method to fetch user's rank
  Future<void> _fetchUserRank() async {
    if (FirebaseAuth.instance.currentUser != null) {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      try {
        // Fetch users ordered by chests opened (same as in leaderboard)
        final QuerySnapshot snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .orderBy('points', descending: true)
                .get();

        // Find current user's position in the results
        int rank = 0;
        for (int i = 0; i < snapshot.docs.length; i++) {
          if (snapshot.docs[i].id == userId) {
            rank = i + 1; // +1 because ranks start at 1, not 0
            break;
          }
        }

        setState(() {
          userRank = rank;
        });
      } catch (e) {
        print('Error fetching user rank: $e');
      }
    }
  }

  List<Widget> _buildHistorySections() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));

    List<PointHistory> todayHistory = [];
    List<PointHistory> thisWeekHistory = [];
    List<PointHistory> olderHistory = [];

    for (var entry in history) {
      final entryDate = entry.timestamp.toDate();
      if (entryDate.isAfter(today)) {
        todayHistory.add(entry);
      } else if (entryDate.isAfter(weekStart)) {
        thisWeekHistory.add(entry);
      } else {
        olderHistory.add(entry);
      }
    }

    List<Widget> sections = [];
    if (todayHistory.isNotEmpty) {
      sections.add(_buildSectionHeader('Aujourd’hui'));
      sections.addAll(todayHistory.map((entry) => _buildHistoryCard(entry)));
    }
    if (thisWeekHistory.isNotEmpty) {
      sections.add(_buildSectionHeader('Cette semaine'));
      sections.addAll(thisWeekHistory.map((entry) => _buildHistoryCard(entry)));
    }
    if (olderHistory.isNotEmpty) {
      sections.add(_buildSectionHeader('Plus ancien'));
      sections.addAll(olderHistory.map((entry) => _buildHistoryCard(entry)));
    }

    return sections;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'myFont',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: themeCtrl.primaryColor,
        ),
      ),
    );
  }

  Widget _buildHistoryCard(PointHistory entry) {
    final date = entry.timestamp.toDate();
    final formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: themeCtrl.backgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: themeCtrl.primaryColor, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '+${entry.pointsGained} points',
            style: TextStyle(
              fontFamily: 'myFont',
              fontSize: 16,
              color: themeCtrl.secondaryColor,
            ),
          ),
          Text(
            formattedDate,
            style: TextStyle(
              fontFamily: 'myFont',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeCtrl.primaryColor,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 150, left: 10, right: 10),
            decoration: BoxDecoration(
              color: themeCtrl.backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: 50),
                Text(
                  authCtrl.currentUser.value.username ?? 'Player Name',
                  style: TextStyle(
                      fontFamily: 'myFont', fontSize: 28),
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
                              color: themeCtrl.backgroundColor,
                            ),
                            Text(
                              'POINTS',
                              style: TextStyle(
                                fontFamily: 'myFont',
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            // Update the points display in the UI
                            // Replace the hardcoded '1275' with the actual points value
                            Text(
                              points.toString(), // Use the points variable instead of hardcoded value
                              style: TextStyle(
                                fontFamily: 'myFont',
                                fontSize: 20,
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
                              color: themeCtrl.backgroundColor,
                            ),
                            Text(
                              'COFFRES OUVERTS',
                              style: TextStyle(
                                fontFamily: 'myFont',
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            Text(
                              chestsOpened.toString(),
                              style: TextStyle(
                                fontFamily: 'myFont',
                                fontSize: 20,
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
                              color: themeCtrl.backgroundColor,
                            ),
                            Text(
                              'RANK',
                              style: TextStyle(
                                fontFamily: 'myFont',
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            Text(
                              userRank > 0 ? '#$userRank' : '-',
                              style: TextStyle(
                                fontFamily: 'myFont',
                                fontSize: 20,
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
                        'Historique',
                        style: TextStyle(
                          fontFamily: 'myFont',
                          fontSize: 22,
                        ),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          margin: EdgeInsets.only(
                            left: 15,
                            right: 15,
                            bottom: 20,
                          ),
                          decoration: BoxDecoration(
                            color: themeCtrl.primaryColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: themeCtrl.primaryColor,
                              width: 3,
                            ),
                          ),
                          child: isLoading
                              ? Center(child: CircularProgressIndicator())
                              : history.isEmpty
                              ? Center(
                            child: Text(
                              'Aucun historique pour le moment. Allez trouver des coffres !',
                              style: TextStyle(
                                fontFamily: 'myFont',
                                fontSize: 16,
                                color: themeCtrl.primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                              : ListView(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            children: [
                              ..._buildHistorySections(),
                              if (hasMore || isFetchingMore)
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                            ],
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
            left: MediaQuery.of(context).size.width / 2 - 55,
            child: GestureDetector(
              onTap: _showAvatarPicker,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: themeCtrl.backgroundColor, width: 3),
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundImage: AssetImage(
                    'assets/images/avatars/${authCtrl.currentUser.value.avatar ?? 'avatar_1'}.png',
                  ),
                ),
              ),
            ),
          ),
          // back button
          Positioned(
            top: 16,
            left: 16,
            child: FloatingActionButton(
              heroTag: "backBtn",
              shape: CircleBorder(),
              backgroundColor: themeCtrl.backgroundColor,
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
              backgroundColor: themeCtrl.backgroundColor,
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
    );
  }

  void _showAvatarPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            height: 400,
            child: Column(
              children: [
                Text(
                  'Choisissez votre avatar',
                  style: TextStyle(
                      fontFamily: 'myFont', fontSize: 20,),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    itemCount: 11,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final avatarName = 'avatar_${index + 1}';
                      return GestureDetector(
                        onTap: () => _selectAvatar(avatarName),
                        child: CircleAvatar(
                          backgroundImage: AssetImage('assets/images/avatars/$avatarName.png'),
                          radius: 30,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectAvatar(String avatarName) async {
    Navigator.of(context).pop(); // Close the dialog

    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'avatar': avatarName,
      });

      // Update locally as well
      authCtrl.currentUser.update((user) {
        user?.avatar = avatarName;
      });

      setState(() {}); // Refresh avatar UI
    } catch (e) {
      print('Failed to update avatar: $e');
    }
  }
}

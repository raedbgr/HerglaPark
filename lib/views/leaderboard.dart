import '/imports.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboardData();
  }

  Future<void> _fetchLeaderboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch users ordered by chests opened
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .orderBy('chestsOpened', descending: true)
              .limit(20) // Top 20 players
              .get();

      List<Map<String, dynamic>> leaderboardEntries = [];
      int rank = 1;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        leaderboardEntries.add({
          'rank': rank,
          'userId': doc.id,
          'username': data['username'] ?? 'Unknown Player',
          'chestsOpened': data['chestsOpened'] ?? 0,
          'points': data['points'] ?? 0,
        });
        rank++;
      }

      setState(() {
        _leaderboardData = leaderboardEntries;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching leaderboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeCtrl.primaryColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Header section
            Container(
              padding: EdgeInsets.symmetric(vertical: 90),
              color: themeCtrl.primaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _headerColumn('RANK', Icons.format_list_numbered),
                  _headerColumn('PLAYER', Icons.person),
                  _headerColumn('CHESTS', Icons.emoji_events),
                  _headerColumn('POINTS', Icons.star),
                ],
              ),
            ),
            // Leaderboard list
            Expanded(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.only(top: 150, left: 10, right: 10),
                decoration: BoxDecoration(
                  color: themeCtrl.backgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child:
                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            color: themeCtrl.secondaryColor,
                          ),
                        )
                        : _leaderboardData.isEmpty
                        ? Center(child: Text('No data available'))
                        : ListView.builder(
                          padding: EdgeInsets.only(top: 20),
                          itemCount: _leaderboardData.length,
                          itemBuilder: (context, index) {
                            final entry = _leaderboardData[index];
                            final bool isCurrentUser =
                                entry['userId'] ==
                                FirebaseAuth.instance.currentUser?.uid;

                            return Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isCurrentUser
                                        ? themeCtrl.secondaryColor.withOpacity(
                                          0.1,
                                        )
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Rank
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _getRankColor(entry['rank']),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '#${entry['rank']}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  // Username
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      entry['username'],
                                      style: TextStyle(
                                        fontWeight:
                                            isCurrentUser
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        fontSize: 16,
                                        color: themeCtrl.primaryColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Chests opened
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.emoji_events,
                                          color: themeCtrl.secondaryColor,
                                          size: 20,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '${entry['chestsOpened']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Points
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 20,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '${entry['points']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
          ],
        ),
      ),
    );
  }

  Widget _headerColumn(String title, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: themeCtrl.backgroundColor, size: 24),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: themeCtrl.backgroundColor.withOpacity(0.8),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Color(0xFFC0C0C0); // Silver
      case 3:
        return Color(0xFFCD7F32); // Bronze
      default:
        return themeCtrl.primaryColor;
    }
  }
}

import '/imports.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _isLoading = true;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isFetchingMore = false;
  final ScrollController _scrollController = ScrollController();
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboardData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _fetchMoreLeaderboardData();
      }
    });
  }

  Future<void> _fetchLeaderboardData() async {
    setState(() {
      _isLoading = true;
      _hasMore = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('points', descending: true)
          .limit(_limit)
          .get();

      List<Map<String, dynamic>> leaderboardEntries = [];
      int rank = 1;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        leaderboardEntries.add({
          'rank': rank,
          'userId': doc.id,
          'username': data['username'] ?? 'Unknown Player',
          'avatar': data['avatar'] ?? 'avatar_1',
          'points': data['points'] ?? 0,
        });
        rank++;
      }

      setState(() {
        _leaderboardData = leaderboardEntries;
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == _limit;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching leaderboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMoreLeaderboardData() async {
    if (!_hasMore || _isFetchingMore || _lastDocument == null) return;

    setState(() => _isFetchingMore = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('points', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_limit)
          .get();

      int rank = _leaderboardData.length + 1;

      List<Map<String, dynamic>> newEntries = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        newEntries.add({
          'rank': rank,
          'userId': doc.id,
          'username': data['username'] ?? 'Unknown Player',
          'avatar': data['avatar'] ?? 'avatar_1',
          'points': data['points'] ?? 0,
        });
        rank++;
      }

      setState(() {
        _leaderboardData.addAll(newEntries);
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastDocument;
        _hasMore = snapshot.docs.length == _limit;
        _isFetchingMore = false;
      });
    } catch (e) {
      print('Error fetching more leaderboard data: $e');
      setState(() => _isFetchingMore = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeCtrl.primaryColor,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 100, left: 10, right: 10),
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
                    : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.only(top: 20),
                            controller: _scrollController,
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
                                          ? themeCtrl.secondaryColor.withValues(alpha: 0.1)
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Rank circle
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
                                            fontFamily: 'myFont',
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),

                                    // Avatar
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundImage: AssetImage(
                                        'assets/images/avatars/${entry['avatar']}.png',
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    // Username
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        entry['username'],
                                        style: TextStyle(
                                          fontFamily: 'myFont',
                                          fontSize: 18,
                                          color: themeCtrl.primaryColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // Points
                                    Row(
                                      children: [
                                        Text(
                                          '${entry['points']}',
                                          style: TextStyle(
                                            fontFamily: 'myFont',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.emoji_events,
                                          color: themeCtrl.secondaryColor,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
    );
  }
}

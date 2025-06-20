import '/imports.dart';

class Routes {
  static final routes = [
    GetPage(name: '/', page: () => Middleware()),
    GetPage(name: '/auth', page: () => AuthPage()),
    GetPage(name: '/login', page: () => LoginPage()),
    GetPage(name: '/register', page: () => RegisterPage()),
    GetPage(name: '/home', page: () => HomePage()),
    GetPage(name: '/profile', page: () => ProfilePage(), transition: Transition.rightToLeft),
    GetPage(name: '/leaderboard', page: () => LeaderboardPage(), transition: Transition.leftToRight),
    GetPage(
      name: '/quiz',
      page: () => QuizScreen(
        chestId: Get.arguments['chestId'] as String,
      ),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: '/whack_a_mole',
      page: () => WhackAMole(
        chestId: Get.arguments['chestId'] as String,
      ),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: '/card_match',
      page: () => CardMatch(
        chestId: Get.arguments['chestId'] as String,
      ),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: '/slide_puzzle',
      page: () => SlidePuzzle(
        chestId: Get.arguments['chestId'] as String,
      ),
      transition: Transition.fadeIn,
    ),
  ];
}
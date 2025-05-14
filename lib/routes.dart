
import 'imports.dart';

class Routes {
  static final routes = [
    GetPage(name: '/auth', page: () => AuthPage()),
    GetPage(name: '/login', page: () => LoginPage()),
    GetPage(name: '/register', page: () => RegisterPage()),
    GetPage(name: '/home', page: () => ChestMapScreen()),
    GetPage(name: '/profile', page: () => ProfilePage(), transition: Transition.rightToLeft),
    GetPage(name: '/leaderboard', page: () => LeaderboardPage(), transition: Transition.leftToRight),
  ];
}
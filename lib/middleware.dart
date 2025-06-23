import 'imports.dart';

class Middleware extends StatelessWidget {
  const Middleware({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: themeCtrl.primaryColor),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: themeCtrl.secondaryColor),
              ),
            );
          } else {
            if (snapshot.data == null) {
              return AuthPage();
            } else {
              authCtrl.fetchUserData(snapshot.data!.uid);
              return HomePage();
            }
          }
        },
      ),
    );
  }
}

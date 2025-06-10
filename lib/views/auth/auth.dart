import '/imports.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeCtrl.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: SingleChildScrollView(
              reverse: true,
              child: Column(
                spacing: 20,
                children: [
                  Container(
                    height: 320,
                    width: 320,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.toNamed('/login');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      height: 60,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: themeCtrl.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: themeCtrl.primaryColor),
                      ),
                      child: Center(
                        child: Text(
                          'Continue with Email',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: themeCtrl.textColor,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.toNamed('/login');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      height: 60,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: themeCtrl.backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: themeCtrl.primaryColor),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 10,
                          children: [
                            const Image(
                              image: AssetImage('assets/images/google.png'),
                              height: 30,
                              width: 30,
                            ),
                            Text(
                              'Continue with Google',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: themeCtrl.primaryColor,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.toNamed('/login');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      height: 60,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: themeCtrl.backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: themeCtrl.primaryColor),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 10,
                          children: [
                            const Image(
                              image: AssetImage('assets/images/apple.png'),
                              height: 30,
                              width: 30,
                            ),
                            Text(
                              'Continue with Apple',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: themeCtrl.primaryColor,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
      backgroundColor: Color(0xfff3edce),
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
                        color: const Color(0xff15b0b1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFb3c3c0)),
                      ),
                      child: Center(
                        child: const Text(
                          'Continue with Email',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xfffdfefe),
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
                        color: const Color(0xfffdfefe),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFb3c3c0)),
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
                            const Text(
                              'Continue with Google',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xff15b0b1),
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
                        color: const Color(0xfffdfefe),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFb3c3c0)),
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
                            const Text(
                              'Continue with Apple',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xff15b0b1),
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

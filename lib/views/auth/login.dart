import '/imports.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
                  MyTextField(
                    controller: authCtrl.emailController,
                    hintText: 'Email',
                    obscureText: false,
                  ),
                  Column(
                    spacing: 5,
                    children: [
                      MyTextField(
                        hintText: 'Password',
                        obscureText: true,
                        controller: authCtrl.passwordController,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Get.toNamed('/forgot-password');
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: themeCtrl.secondaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      if (authCtrl.emailController.text.isEmpty ||
                          authCtrl.passwordController.text.isEmpty) {
                        Get.snackbar("Error", "Please fill all fields",
                            snackPosition: SnackPosition.BOTTOM);
                      } else {
                        authCtrl.signIn(
                          authCtrl.emailController.text,
                          authCtrl.passwordController.text,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: themeCtrl.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: themeCtrl.primaryColor,
                        ),
                      ),
                      child: Text(
                        'Sign In',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: themeCtrl.textColor,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Not a member yet ? ',
                          style: TextStyle(
                            fontSize: 16,
                          )),
                      GestureDetector(
                        onTap: () {
                          Get.toNamed('/register');
                        },
                        child: Text('Sign Up',
                            style: TextStyle(
                              color: themeCtrl.secondaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

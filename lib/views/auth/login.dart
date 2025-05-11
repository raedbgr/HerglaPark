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
                        image: AssetImage('assets/logo.png'),
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
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xff15b0b1),
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
                      // Handle login logic here
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xff15b0b1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFb3c3c0),
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xfffdfefe),
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
                        child: const Text('Sign Up',
                            style: TextStyle(
                              color: Color(0xff15b0b1),
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

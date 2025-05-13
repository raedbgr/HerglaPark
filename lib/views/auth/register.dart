import '/imports.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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
                    hintText: 'Username',
                    obscureText: false,
                    controller: authCtrl.usernameController,
                  ),
                  MyTextField(
                    controller: authCtrl.emailController,
                    hintText: 'Email',
                    obscureText: false,
                  ),
                  MyTextField(
                    hintText: 'Password',
                    obscureText: true,
                    controller: authCtrl.passwordController,
                  ),
                  MyTextField(
                    hintText: 'Confirm Password',
                    obscureText: true,
                    controller: authCtrl.confirmPasswordController,
                  ),
                  GestureDetector(
                    onTap: () {
                      if (authCtrl.usernameController.text.isEmpty ||
                          authCtrl.emailController.text.isEmpty ||
                          authCtrl.passwordController.text.isEmpty ||
                          authCtrl.confirmPasswordController.text.isEmpty) {
                        Get.snackbar("Error", "Please fill all fields", snackPosition: SnackPosition.BOTTOM);
                      } else {
                        authCtrl.signUp(
                          authCtrl.usernameController.text,
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
                        color: const Color(0xff15b0b1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFb3c3c0),
                        ),
                      ),
                      child: const Text(
                        'Sign Up',
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
                      const Text('Already a member ? ',
                          style: TextStyle(
                            fontSize: 16,
                          )),
                      GestureDetector(
                        onTap: () {
                          Get.toNamed('/login');
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

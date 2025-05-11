import '/imports.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  Future<User?> register(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the created user
      User? user = userCredential.user;

      if (user != null) {
        print("User registered: ${user.email}");
        emailController.clear();
        passwordController.clear();
        confirmPasswordController.clear();
        Get.offAllNamed('/'); // Navigate to home after registration
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print("Register Error: ${e.message}");
      Get.snackbar("Registration Error", e.message ?? "Something went wrong", snackPosition: SnackPosition.BOTTOM);
      return null;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        print("Sign in successful ${userCredential.user!.uid}");
        emailController.clear();
        passwordController.clear();
        // plantsCtrl.uploadPlantsToFirestore();
        Get.offAllNamed('/');
      }
    } on FirebaseAuthException catch (e) {
      print("Error: ${e.message}");
      Get.snackbar("Login Failed", e.message ?? "An error occurred",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      print("User signed out successfully");
      Get.offAllNamed('/login');
    } catch (e) {
      print("Sign out error: $e");
      Get.snackbar("Error", "Failed to sign out",
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
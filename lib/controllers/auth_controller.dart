import '/imports.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  var currentUser =
      UserModel(
        id: '',
        username: '',
        email: '',
        avatar: 'assets/images/player.png',
        chestsOpened: 0,
      ).obs;
  // Add a boolean to track loading state
  var isLoading = false.obs;

  // Fetch user data from Firestore
  Future<void> fetchUserData(String uid) async {
    try {
      isLoading(true); // Start loading
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        currentUser.value = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
        print("User data fetched: ${currentUser.value.username}");
      } else {
        print("User document does not exist");
      }
    } catch (e) {
      print("Error fetching user data: $e");
    } finally {
      isLoading(false); // Stop loading
    }
  }

  Future<User?> signUp(String username, String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        print("User registered: ${user.email}");
        final Timestamp now = Timestamp.now();

        // Create user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'id': user.uid,
          'username': username,
          'email': email,
          'avatar': null,
          'chestsOpened': 0,
          'createdAt': now,
        });

        print("User document created in Firestore");
        // Clear the text fields
        usernameController.clear();
        emailController.clear();
        passwordController.clear();
        confirmPasswordController.clear();
        // Fetch the user data after registration
        await fetchUserData(user.uid);
        Get.offAllNamed('/home');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print("Register Error: ${e.message}");
      Get.snackbar(
        "Registration Error",
        e.message ?? "Something went wrong",
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (e) {
      print("Firestore Error: $e");
      Get.snackbar(
        "Firestore Error",
        "Failed to create user document",
        snackPosition: SnackPosition.BOTTOM,
      );
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
        // Fetch the user data after login
        await fetchUserData(userCredential.user!.uid);
        Get.offAllNamed('/home');
      }
    } on FirebaseAuthException catch (e) {
      print("Error: ${e.message}");
      Get.snackbar(
        "Login Failed",
        e.message ?? "An error occurred",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print("User signed out successfully");
      Get.offAllNamed('/login');
    } catch (e) {
      print("Sign out error: $e");
      Get.snackbar(
        "Error",
        "Failed to sign out",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

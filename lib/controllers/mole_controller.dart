import '/imports.dart';

class WamController extends GetxController {
  final int gridSize = 3; // 3x3 grid
  final int totalHoles = 9;
  final int gameDuration = 30; // 30 seconds
  final int scoreToWin = 20; // Points needed to win
  final int moleStayTime = 1000; // 1 second per mole
  final int minInterval = 1000; // Min 1 second between moles
  final int maxInterval = 2000; // Max 2 seconds between moles

  RxList<bool> moles = List.generate(9, (_) => false).obs; // Mole visibility
  RxInt score = 0.obs; // Current score
  RxInt timeLeft = 30.obs; // Time remaining
  RxBool isGameOver = false.obs; // Game over flag

  Timer? gameTimer;
  Timer? moleTimer;

  @override
  void onInit() {
    super.onInit();
    startGame();
  }

  @override
  void onClose() {
    gameTimer?.cancel();
    moleTimer?.cancel();
    super.onClose();
  }

  void startGame() {
    score.value = 0;
    timeLeft.value = gameDuration;
    isGameOver.value = false;
    moles.value = List.generate(totalHoles, (_) => false);

    // Start game timer
    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timeLeft.value > 0) {
        timeLeft.value--;
      } else {
        timer.cancel();
        endGame(false); // Time's up, game over
      }
    });

    // Start mole appearances
    showMole();
  }

  void showMole() {
    if (isGameOver.value) return;

    int holeIndex = Random().nextInt(totalHoles);
    moles[holeIndex] = true;
    moles.refresh(); // Ensure UI updates

    // Hide mole after moleStayTime
    Timer(Duration(milliseconds: moleStayTime), () {
      if (moles[holeIndex]) {
        moles[holeIndex] = false;
        moles.refresh(); // Ensure UI updates
      }
    });

    // Schedule next mole
    int nextInterval = minInterval + Random().nextInt(maxInterval - minInterval);
    moleTimer = Timer(Duration(milliseconds: nextInterval), showMole);
  }

  void hitMole(int index) {
    if (moles[index] && !isGameOver.value) {
      moles[index] = false;
      moles.refresh(); // Ensure UI updates
      score.value++;
      if (score.value >= scoreToWin) {
        endGame(true); // Win condition met
      }
    }
  }

  void endGame(bool won) {
    isGameOver.value = true;
    gameTimer?.cancel();
    moleTimer?.cancel();
    if (won) {
      Get.find<WhackAMoleState>().handleSuccess();
    } else {
      Get.find<WhackAMoleState>().handleFailure("Time's up or not enough points!");
    }
  }
}
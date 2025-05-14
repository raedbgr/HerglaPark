import '/imports.dart';

class FadingLine extends StatelessWidget {
  final double height;
  final double width;
  final Color color;

  const FadingLine({
    super.key,
    required this.height,
    required this.width,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            color,
            Colors.transparent,
          ],
          stops: [0.0, 0.5, 1.0], // Optional: center the solid part
        ),
      ),
    );
  }
}
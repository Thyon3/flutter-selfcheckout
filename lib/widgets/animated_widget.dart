import 'package:flutter/material.dart';

class AnimatedContainer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const AnimatedContainer({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  }) : super(key: key);

  @override
  _AnimatedContainerState createState() => _AnimatedContainerState();
}

class _AnimatedContainerState extends State<AnimatedContainer>
  bool _isVisible = false;

  void toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: widget.duration,
      curve: widget.curve,
      child: widget.child,
    );
  }
}

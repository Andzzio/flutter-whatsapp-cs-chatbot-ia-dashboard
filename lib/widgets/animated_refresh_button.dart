import 'package:flutter/material.dart';

class AnimatedRefreshButton extends StatefulWidget {
  final Future<void> Function() onPressed;

  const AnimatedRefreshButton({super.key, required this.onPressed});

  @override
  State<AnimatedRefreshButton> createState() => _AnimatedRefreshButtonState();
}

class _AnimatedRefreshButtonState extends State<AnimatedRefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });
    _controller.repeat();

    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        _controller.stop();
        _controller.reset();
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: IconButton(
        icon: Icon(
          Icons.refresh_rounded,
          color: Theme.of(context).primaryColor,
        ),
        tooltip: "Recargar contactos",
        onPressed: _handlePress,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Expandable FAB that shows multiple action buttons when tapped
class ExpandableFab extends StatefulWidget {
  final List<FabAction> actions;
  final IconData icon;
  final IconData closeIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double distance;

  const ExpandableFab({
    super.key,
    required this.actions,
    this.icon = Icons.add,
    this.closeIcon = Icons.close,
    this.backgroundColor,
    this.foregroundColor,
    this.distance = 80,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    setState(() {
      _isOpen = false;
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final fgColor = widget.foregroundColor ?? Colors.white;

    return SizedBox(
      width: 56 + widget.distance + 100,
      height: 56 + (widget.actions.length * (widget.distance + 10)),
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // Overlay to close when tapped outside
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                child: Container(color: Colors.transparent),
              ),
            ),
          // Action buttons
          ..._buildExpandingActionButtons(),
          // Main FAB
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _expandAnimation.value * math.pi / 4,
                child: child,
              );
            },
            child: FloatingActionButton(
              heroTag: 'expandable_fab_main',
              onPressed: _toggle,
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              elevation: _isOpen ? 8 : 6,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  _isOpen ? widget.closeIcon : widget.icon,
                  key: ValueKey(_isOpen),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.actions.length;

    for (var i = 0; i < count; i++) {
      final action = widget.actions[i];
      children.add(
        _ExpandingActionButton(
          distance: widget.distance * (i + 1),
          progress: _expandAnimation,
          action: action,
          onPressed: () {
            _close();
            action.onPressed();
          },
        ),
      );
    }

    return children;
  }
}

/// Single action for the expandable FAB
class FabAction {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onPressed;

  const FabAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });
}

class _ExpandingActionButton extends StatelessWidget {
  final double distance;
  final Animation<double> progress;
  final FabAction action;
  final VoidCallback onPressed;

  const _ExpandingActionButton({
    required this.distance,
    required this.progress,
    required this.action,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset(0, -distance * progress.value);
        return Positioned(
          right: 0,
          bottom: 0,
          child: Transform.translate(
            offset: offset,
            child: Opacity(
              opacity: progress.value,
              child: child,
            ),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                action.label,
                style: TextStyle(
                  color: action.color ?? Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Mini FAB
          FloatingActionButton.small(
            heroTag: 'fab_action_${action.label}',
            onPressed: onPressed,
            backgroundColor: action.color ?? Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            child: Icon(action.icon),
          ),
        ],
      ),
    );
  }
}

/// Simple builder widget for animations
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

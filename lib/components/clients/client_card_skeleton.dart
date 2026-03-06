// lib/components/clients/client_card_skeleton.dart
import 'package:flutter/material.dart';

/// Skeleton animado que imita el layout de [ClientCard].
class ClientCardSkeleton extends StatefulWidget {
  const ClientCardSkeleton({super.key});

  @override
  State<ClientCardSkeleton> createState() => _ClientCardSkeletonState();
}

class _ClientCardSkeletonState extends State<ClientCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.25, end: 0.55).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => _SkeletonBody(opacity: _opacity.value),
    );
  }
}

class _SkeletonBody extends StatelessWidget {
  final double opacity;

  const _SkeletonBody({required this.opacity});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface.withValues(alpha: opacity);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          _Box(width: 44, height: 44, radius: 12, color: base),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre + badge
                Row(
                  children: [
                    Expanded(
                      child: _Box(height: 13, radius: 4, color: base),
                    ),
                    const SizedBox(width: 8),
                    _Box(width: 64, height: 20, radius: 10, color: base),
                  ],
                ),
                const SizedBox(height: 8),
                // Plan + sector
                _Box(height: 11, radius: 4, color: base),
                const SizedBox(height: 7),
                // Saldo
                _Box(width: 110, height: 11, radius: 4, color: base),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Chevron
          _Box(width: 14, height: 14, radius: 4, color: base),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final Color color;

  const _Box({
    this.width,
    required this.height,
    required this.radius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Lista de [n] skeletons para usar mientras carga.
class ClientCardSkeletonList extends StatelessWidget {
  final int count;

  const ClientCardSkeletonList({super.key, this.count = 8});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: count,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: ClientCardSkeleton(),
      ),
    );
  }
}

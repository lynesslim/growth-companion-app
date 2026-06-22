import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_gradients.dart';

final List<Color> _avatarColors = [
  const Color(0xFF9E82F0),
  const Color(0xFFF0A8D2),
  const Color(0xFFE882B8),
  const Color(0xFFE75B1B),
  const Color(0xFF6366F1),
  const Color(0xFF14B8A6),
  const Color(0xFFEC4899),
  const Color(0xFF8B5CF6),
];

Color _avatarColor(String name) => _avatarColors[name.hashCode % _avatarColors.length];

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  if (parts.length == 1 && parts.first.isNotEmpty) return parts.first[0].toUpperCase();
  return '?';
}

class AvatarCircle extends StatelessWidget {
  final double size;
  final String name;

  const AvatarCircle({super.key, required this.size, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _avatarColor(name),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class AvatarRing extends StatelessWidget {
  final double size;
  final String name;
  final double borderWidth;

  const AvatarRing({
    super.key,
    required this.size,
    required this.name,
    this.borderWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + borderWidth * 2 + 4,
      height: size + borderWidth * 2 + 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.avatarRing,
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(2),
        child: AvatarCircle(size: size, name: name),
      ),
    );
  }
}

class StreakBadge extends StatelessWidget {
  final int count;

  const StreakBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 11, fontFamily: 'Apple Color Emoji')),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

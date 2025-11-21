import 'package:flutter/material.dart';
import 'animation_variants.dart';

/// Widget that demonstrates all available animation types with top preview
class AnimationPreview extends StatefulWidget {
  const AnimationPreview({super.key});

  @override
  State<AnimationPreview> createState() => _AnimationPreviewState();
}

class _AnimationPreviewState extends State<AnimationPreview>
    with TickerProviderStateMixin {
  late AnimationType _currentAnimation;
  late AnimationController _previewController;

  @override
  void initState() {
    super.initState();
    _currentAnimation = AnimationVariants.currentType;
    _previewController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _startPreviewAnimation();
  }

  @override
  void dispose() {
    _previewController.dispose();
    super.dispose();
  }

  void _startPreviewAnimation() {
    _previewController.forward(from: 0);
  }

  void _updateAnimation(AnimationType type) {
    setState(() {
      _currentAnimation = type;
      AnimationVariants.setAnimationType(type);
    });
    _startPreviewAnimation();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.grey.shade900;
    final subtleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: const Text(
          'Animation Showcase',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Preview Section
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.08),
                    primaryColor.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryColor.withOpacity(0.15),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Preview Title
                  Text(
                    'Current Animation',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subtleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ) ??
                        TextStyle(
                          color: subtleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Animation Name
                  Text(
                    AnimationVariants.getAnimationName(_currentAnimation),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ) ??
                        TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    _getAnimationDescription(_currentAnimation),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: subtleColor,
                          height: 1.5,
                        ) ??
                        TextStyle(
                          fontSize: 14,
                          color: subtleColor,
                          height: 1.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Large Preview Box
                  _buildLargePreview(context, _currentAnimation),
                  const SizedBox(height: 20),

                  // Test Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _previewAnimation(context, _currentAnimation),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Test This Animation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: isDark
                            ? const Color(0xFF121212)
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                color: primaryColor.withOpacity(0.1),
              ),
            ),

            // Section Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Animations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ) ??
                        const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to select, swipe to preview',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subtleColor,
                        ) ??
                        TextStyle(
                          fontSize: 12,
                          color: subtleColor,
                        ),
                  ),
                ],
              ),
            ),

            // Animation Grid/List
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: _buildAnimationTiles(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargePreview(BuildContext context, AnimationType type) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.15),
            primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(parent: _previewController, curve: Curves.easeOutBack),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForAnimation(type),
                size: 48,
                color: primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                _getAnimationEmoji(type),
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAnimationTiles() {
    return AnimationType.values.map((type) {
      final isSelected = type == _currentAnimation;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimationTile(
          type: type,
          isSelected: isSelected,
          onSelect: () => _updateAnimation(type),
          onPreview: () => _previewAnimation(context, type),
        ),
      );
    }).toList();
  }

  String _getAnimationDescription(AnimationType type) {
    switch (type) {
      case AnimationType.fadeSlide:
        return 'Smooth fade and slide from bottom - elegant entry';
      case AnimationType.slideLeft:
        return 'Quick slide from left - modern and direct';
      case AnimationType.slideRight:
        return 'Quick slide from right - playful alternative';
      case AnimationType.scaleRotate:
        return 'Smooth expand in - subtle and refined';
      case AnimationType.morphing:
        return 'Vertical swipe - fluid and smooth';
      case AnimationType.bouncy:
        return 'Slide from left - sleek transition';
      case AnimationType.liquid:
        return 'Slide from right - smooth modern';
      case AnimationType.staggered:
        return 'Diagonal swipe - flowing and elegant';
      case AnimationType.kaleidoscope:
        return 'Scale bloom - modern bright entry';
      case AnimationType.elasticBounce:
        return 'Tilt entry - sophisticated transition';
    }
  }

  IconData _getIconForAnimation(AnimationType type) {
    switch (type) {
      case AnimationType.fadeSlide:
        return Icons.arrow_upward_rounded;
      case AnimationType.slideLeft:
        return Icons.arrow_back_rounded;
      case AnimationType.slideRight:
        return Icons.arrow_forward_rounded;
      case AnimationType.scaleRotate:
        return Icons.zoom_in_rounded;
      case AnimationType.morphing:
        return Icons.bubble_chart_rounded;
      case AnimationType.bouncy:
        return Icons.sports_basketball_rounded;
      case AnimationType.liquid:
        return Icons.water_rounded;
      case AnimationType.staggered:
        return Icons.layers_rounded;
      case AnimationType.kaleidoscope:
        return Icons.dashboard_rounded;
      case AnimationType.elasticBounce:
        return Icons.toys_rounded;
    }
  }

  String _getAnimationEmoji(AnimationType type) {
    switch (type) {
      case AnimationType.fadeSlide:
        return '✨';
      case AnimationType.slideLeft:
        return '⬅️';
      case AnimationType.slideRight:
        return '➡️';
      case AnimationType.scaleRotate:
        return '🔄';
      case AnimationType.morphing:
        return '🫧';
      case AnimationType.bouncy:
        return '🏀';
      case AnimationType.liquid:
        return '💧';
      case AnimationType.staggered:
        return '📚';
      case AnimationType.kaleidoscope:
        return '🎪';
      case AnimationType.elasticBounce:
        return '🎾';
    }
  }

  void _previewAnimation(BuildContext context, AnimationType type) {
    final previousType = AnimationVariants.currentType;
    AnimationVariants.setAnimationType(type);

    Navigator.of(context).push(
      AnimationVariants.createRoute(
        const AnimationPreviewPage(),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop();
        AnimationVariants.setAnimationType(previousType);
      }
    });
  }
}

/// Individual animation tile
class AnimationTile extends StatefulWidget {
  final AnimationType type;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  const AnimationTile({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onSelect,
    required this.onPreview,
  });

  @override
  State<AnimationTile> createState() => _AnimationTileState();
}

class _AnimationTileState extends State<AnimationTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.grey.shade900;
    final subtleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onSelect();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? primaryColor.withOpacity(isDark ? 0.15 : 0.08)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? primaryColor.withOpacity(0.4)
                  : primaryColor.withOpacity(0.1),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getIconForAnimation(widget.type),
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AnimationVariants.getAnimationName(widget.type),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ) ??
                                TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                          ),
                        ),
                        if (widget.isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: isDark
                                      ? const Color(0xFF121212)
                                      : Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Selected',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF121212)
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _getShortDescription(widget.type),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: subtleColor,
                            fontSize: 11,
                          ) ??
                          TextStyle(
                            fontSize: 11,
                            color: subtleColor,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Preview button
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onPreview,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: primaryColor,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForAnimation(AnimationType type) {
    switch (type) {
      case AnimationType.fadeSlide:
        return Icons.arrow_upward_rounded;
      case AnimationType.slideLeft:
        return Icons.arrow_back_rounded;
      case AnimationType.slideRight:
        return Icons.arrow_forward_rounded;
      case AnimationType.scaleRotate:
        return Icons.zoom_in_rounded;
      case AnimationType.morphing:
        return Icons.bubble_chart_rounded;
      case AnimationType.bouncy:
        return Icons.sports_basketball_rounded;
      case AnimationType.liquid:
        return Icons.water_rounded;
      case AnimationType.staggered:
        return Icons.layers_rounded;
      case AnimationType.kaleidoscope:
        return Icons.dashboard_rounded;
      case AnimationType.elasticBounce:
        return Icons.toys_rounded;
    }
  }

  String _getShortDescription(AnimationType type) {
    switch (type) {
      case AnimationType.fadeSlide:
        return 'Fade & slide up';
      case AnimationType.slideLeft:
        return 'Slide from left';
      case AnimationType.slideRight:
        return 'Slide from right';
      case AnimationType.scaleRotate:
        return 'Expand in';
      case AnimationType.morphing:
        return 'Vertical swipe';
      case AnimationType.bouncy:
        return 'Bouncy entry';
      case AnimationType.liquid:
        return 'Liquid swipe';
      case AnimationType.staggered:
        return 'Staggered cascade';
      case AnimationType.kaleidoscope:
        return 'Scale bloom';
      case AnimationType.elasticBounce:
        return 'Elastic entry';
    }
  }
}

/// Simple page for animation preview
class AnimationPreviewPage extends StatelessWidget {
  const AnimationPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    primaryColor.withOpacity(0.6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle,
                size: 60,
                color: isDark ? const Color(0xFF121212) : Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Animation Applied!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ) ??
                  const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'This page was navigated to with the selected animation',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor:
                    isDark ? const Color(0xFF121212) : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
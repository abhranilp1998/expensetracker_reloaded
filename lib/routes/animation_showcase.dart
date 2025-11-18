import 'package:flutter/material.dart';
import 'animation_variants.dart';

/// Widget that demonstrates all available animation types
class AnimationPreview extends StatefulWidget {
  const AnimationPreview({super.key});

  @override
  State<AnimationPreview> createState() => _AnimationPreviewState();
}

class _AnimationPreviewState extends State<AnimationPreview> {
  late AnimationType _currentAnimation;

  @override
  void initState() {
    super.initState();
    _currentAnimation = AnimationVariants.currentType;
  }

  void _updateAnimation(AnimationType type) {
    setState(() {
      _currentAnimation = type;
      AnimationVariants.setAnimationType(type);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Preview'),
        backgroundColor: Colors.green.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Animation Types',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Current: ${AnimationVariants.getAnimationName(_currentAnimation)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildAnimationCards(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnimationCards() {
    return AnimationType.values.map((type) {
      final isActive = type == _currentAnimation;
      return AnimationCard(
        type: type,
        isActive: isActive,
        onSelect: () => _updateAnimation(type),
      );
    }).toList();
  }
}

/// Card displaying a single animation type with preview
class AnimationCard extends StatelessWidget {
  final AnimationType type;
  final bool isActive;
  final VoidCallback onSelect;

  const AnimationCard({
    super.key,
    required this.type,
    required this.isActive,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? Colors.green.shade600 : Colors.grey.shade300,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AnimationVariants.getAnimationName(type),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Current',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getAnimationDescription(type),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildAnimationPreview(type),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? Colors.green.shade600 : Colors.grey.shade400,
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    child: Text(
                      isActive ? 'Selected' : 'Select',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _previewAnimation(context, type);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    child: const Text(
                      'Preview',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationPreview(AnimationType type) {
    switch (type) {
      case AnimationType.fadeSlide:
        return Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade300,
                Colors.green.shade600,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_downward, color: Colors.white, size: 24),
                SizedBox(height: 4),
                Text(
                  'Fades in & Slides up',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        );

      case AnimationType.slideLeft:
        return Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade300, Colors.blue.shade600],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 24),
                SizedBox(height: 4),
                Text(
                  'Slides from left',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        );

      case AnimationType.slideRight:
        return Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade300, Colors.purple.shade600],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_forward, color: Colors.white, size: 24),
                SizedBox(height: 4),
                Text(
                  'Slides from right',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        );

      case AnimationType.scaleRotate:
        return Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade300, Colors.orange.shade600],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flip, color: Colors.white, size: 24),
                SizedBox(height: 4),
                Text(
                  'Scales & rotates',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        );
    }
  }

  String _getAnimationDescription(AnimationType type) {
    switch (type) {
      case AnimationType.fadeSlide:
        return 'Smooth fade and slide from bottom - elegant and subtle';
      case AnimationType.slideLeft:
        return 'Quick slide from left - modern and direct';
      case AnimationType.slideRight:
        return 'Quick slide from right - playful alternative';
      case AnimationType.scaleRotate:
        return 'Scale and rotate - fun and eye-catching';
    }
  }

  void _previewAnimation(BuildContext context, AnimationType type) {
    final previousType = AnimationVariants.currentType;
    AnimationVariants.setAnimationType(type);

    // Create a simple preview page
    Navigator.of(context).push(
      AnimationVariants.createRoute(
        const AnimationPreviewPage(),
      ),
    );

    // Restore previous type after pop
    Navigator.of(context).popUntil((route) => route.isFirst);
    AnimationVariants.setAnimationType(previousType);
  }
}

/// Simple page for animation preview
class AnimationPreviewPage extends StatelessWidget {
  const AnimationPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Preview'),
        backgroundColor: Colors.green.shade600,
      ),
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
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
              ),
              child: const Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'This page was navigated to with the selected animation',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Go Back',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

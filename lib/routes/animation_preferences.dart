import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'animation_variants.dart';

/// Service to manage animation preferences
class AnimationPreferencesService {
  static const String _prefKey = 'animationType';

  /// Save animation type preference
  static Future<void> saveAnimationType(AnimationType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, type.toString());
    AnimationVariants.setAnimationType(type);
  }

  /// Load animation type preference
  static Future<AnimationType> loadAnimationType() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);

    if (saved == null) {
      return AnimationType.fadeSlide; // Default
    }

    // Parse the saved value
    for (final type in AnimationType.values) {
      if (type.toString() == saved) {
        AnimationVariants.setAnimationType(type);
        return type;
      }
    }

    return AnimationType.fadeSlide;
  }

  /// Get all available animation types
  static List<AnimationType> getAllAnimationTypes() {
    return AnimationType.values;
  }

  /// Get animation type by index
  static AnimationType getAnimationTypeByIndex(int index) {
    if (index < 0 || index >= AnimationType.values.length) {
      return AnimationType.fadeSlide;
    }
    return AnimationType.values[index];
  }

  /// Get description for animation type
  static String getDescription(AnimationType type) {
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
}

/// Widget to display animation variants for selection
class AnimationVariantSelector extends StatefulWidget {
  final Function(AnimationType) onChanged;
  final AnimationType initialSelection;

  const AnimationVariantSelector({
    super.key,
    required this.onChanged,
    required this.initialSelection,
  });

  @override
  State<AnimationVariantSelector> createState() =>
      _AnimationVariantSelectorState();
}

class _AnimationVariantSelectorState extends State<AnimationVariantSelector> {
  late AnimationType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Animation Style',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: AnimationType.values.length,
          itemBuilder: (context, index) {
            final type = AnimationType.values[index];
            final isSelected = _selectedType == type;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? Colors.green.shade600
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                title: Text(
                  AnimationVariants.getAnimationName(type),
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  AnimationPreferencesService.getDescription(type),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: isSelected
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.shade600,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      )
                    : null,
                onTap: () {
                  setState(() {
                    _selectedType = type;
                  });
                  widget.onChanged(type);
                  AnimationPreferencesService.saveAnimationType(type);

                  // Show confirmation with animation preview
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Animation changed to ${AnimationVariants.getAnimationName(type)}',
                      ),
                      duration: const Duration(milliseconds: 1500),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Widget showing animation type dropdown
class AnimationTypeDropdown extends StatefulWidget {
  final Function(AnimationType) onChanged;
  final AnimationType initialSelection;

  const AnimationTypeDropdown({
    super.key,
    required this.onChanged,
    required this.initialSelection,
  });

  @override
  State<AnimationTypeDropdown> createState() => _AnimationTypeDropdownState();
}

class _AnimationTypeDropdownState extends State<AnimationTypeDropdown> {
  late AnimationType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<AnimationType>(
      value: _selectedType,
      isExpanded: true,
      items: AnimationType.values
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(AnimationVariants.getAnimationName(type)),
              ))
          .toList(),
      onChanged: (newType) {
        if (newType != null) {
          setState(() {
            _selectedType = newType;
          });
          widget.onChanged(newType);
          AnimationPreferencesService.saveAnimationType(newType);
        }
      },
    );
  }
}

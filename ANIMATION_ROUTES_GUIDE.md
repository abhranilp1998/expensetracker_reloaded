# 🎬 Animation Routes System - Complete Guide

## Overview

The app now features a **complete animation routes system** with 4 different transition variants that can be:
- ✅ Applied to all screen navigations automatically
- ✅ Switched globally at runtime
- ✅ Persisted in user preferences
- ✅ Previewed in a showcase screen

---

## 📦 Components

### 1. **AnimationVariants** (`lib/routes/animation_variants.dart`)

Main class managing all animation types with global switching capability.

**Features:**
- 4 built-in animation variants
- Static methods for creating routes with current variant
- Animation type enumeration
- Backward compatibility with direct route creation

**Animation Types:**

#### 🟢 **Fade + Slide** (Default)
```
Duration: 450ms
Behavior: Content fades in while sliding up from bottom
Best for: Elegant, smooth transitions
Curve: easeOut
```

#### 🔵 **Slide Left**
```
Duration: 350ms
Behavior: Content slides in from the left edge
Best for: Modern, direct navigation
Curve: easeInOutCubic
```

#### 🟣 **Slide Right**
```
Duration: 350ms
Behavior: Content slides in from the right edge
Best for: Playful alternatives, back navigation
Curve: easeInOutCubic
```

#### 🟠 **Scale + Rotate**
```
Duration: 500ms
Behavior: Content scales up from 80% and rotates slightly
Best for: Eye-catching, fun interactions
Curve: easeOutCubic
```

### 2. **AnimationPreferencesService** (`lib/routes/animation_preferences.dart`)

Service for managing animation preferences with SharedPreferences persistence.

**Key Methods:**
```dart
// Save and load preferences
await AnimationPreferencesService.saveAnimationType(AnimationType.slideLeft);
final savedType = await AnimationPreferencesService.loadAnimationType();

// Get all types
List<AnimationType> types = AnimationPreferencesService.getAllAnimationTypes();

// Get descriptions
String desc = AnimationPreferencesService.getDescription(AnimationType.fadeSlide);
```

### 3. **UI Widgets** (`lib/routes/animation_preferences.dart`)

Two ready-to-use widgets for user preference selection:

#### AnimationVariantSelector
Full-featured selector with descriptions and cards:
```dart
AnimationVariantSelector(
  initialSelection: AnimationVariants.currentType,
  onChanged: (newType) {
    // Handle change
  },
)
```

#### AnimationTypeDropdown
Compact dropdown selector:
```dart
AnimationTypeDropdown(
  initialSelection: AnimationVariants.currentType,
  onChanged: (newType) {
    // Handle change
  },
)
```

### 4. **AnimationShowcase** (`lib/routes/animation_showcase.dart`)

Full demonstration page showing all animation variants with:
- Preview cards with descriptions
- Live animation previews
- Test navigation buttons
- Visual indicators of current selection

---

## 🚀 Usage

### Basic Usage

**All navigations automatically use the selected animation:**

```dart
import 'package:expensetracker_reloaded/routes/app_routes.dart';

// Navigate - will use current animation variant
Navigator.of(context).pushNamed(AppRoutes.home);

// Or manually with createRoute
Navigator.of(context).push(createRoute(const MyPage()));
```

### Switch Animation Type Globally

```dart
import 'package:expensetracker_reloaded/routes/animation_variants.dart';
import 'package:expensetracker_reloaded/routes/animation_preferences.dart';

// Change animation type
AnimationVariants.setAnimationType(AnimationType.slideLeft);

// Save to preferences (persisted across app restarts)
await AnimationPreferencesService.saveAnimationType(AnimationType.slideLeft);
```

### Add Animation Selector to Settings Page

```dart
import 'package:expensetracker_reloaded/routes/animation_preferences.dart';
import 'package:expensetracker_reloaded/routes/animation_variants.dart';

class SettingsPage extends StatefulWidget {
  // ...
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimationVariantSelector(
          initialSelection: AnimationVariants.currentType,
          onChanged: (newType) {
            // Automatically saved by the widget
          },
        ),
      ),
    );
  }
}
```

### Show Animation Showcase

```dart
Navigator.of(context).push(
  createRoute(const AnimationPreview()),
);
```

---

## 🔄 Architecture

### How It Works

```
App Launch
    ↓
main() loads saved animation preference
    ↓
AnimationVariants.setAnimationType(savedType)
    ↓
Navigation called (pushNamed, push)
    ↓
createRoute(page) called
    ↓
AnimationVariants.createRoute(page) uses current type
    ↓
Appropriate PageRouteBuilder selected
    ↓
Animation applied to page transition
```

### Flow Diagram

```
User Settings Page
        ↓
AnimationVariantSelector (UI)
        ↓
onChanged callback
        ↓
AnimationPreferencesService.saveAnimationType()
        ↓
SharedPreferences.setString() [Persisted]
AnimationVariants.setAnimationType() [Current]
        ↓
Next navigation uses new animation
```

---

## 📝 Code Examples

### Example 1: Complete Settings Integration

```dart
import 'package:flutter/material.dart';
import 'package:expensetracker_reloaded/routes/animation_preferences.dart';
import 'package:expensetracker_reloaded/routes/animation_variants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Preferences', style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 16),
          
          // Animation selector
          AnimationVariantSelector(
            initialSelection: AnimationVariants.currentType,
            onChanged: (newType) {
              // Changes are saved automatically
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Animation: ${AnimationVariants.getAnimationName(newType)}',
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Preview button
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                createRoute(const AnimationPreview()),
              );
            },
            child: const Text('Preview All Animations'),
          ),
        ],
      ),
    );
  }
}
```

### Example 2: Custom Route Creation

```dart
// Use specific animation variant directly
import 'package:expensetracker_reloaded/routes/animation_variants.dart';

// Create route with specific animation
Route route = CustomAnimationRoute.slideLeft(const MyPage());
Navigator.of(context).push(route);

// Or use animation variants directly
AnimationVariants.setAnimationType(AnimationType.scaleRotate);
Route route = AnimationVariants.createRoute(const MyPage());
```

### Example 3: Load Preferences on Startup

```dart
// Already done in main.dart!
// But here's how to do it manually:

import 'package:expensetracker_reloaded/routes/animation_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load saved animation preference
  await AnimationPreferencesService.loadAnimationType();
  
  runApp(const MyApp());
}
```

---

## 🎨 Customization

### Add a New Animation Variant

1. **Add to enum** (`animation_variants.dart`):
```dart
enum AnimationType {
  fadeSlide,
  slideLeft,
  slideRight,
  scaleRotate,
  myCustomAnimation,  // New!
}
```

2. **Create the animation builder**:
```dart
static Route<dynamic> _myCustomAnimationRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Your custom animation logic
      return child; // Apply your transitions
    },
  );
}
```

3. **Add to routes map**:
```dart
static final Map<AnimationType, Function(Widget)> _routeBuilders = {
  // ... existing entries
  AnimationType.myCustomAnimation: _myCustomAnimationRoute,
};
```

4. **Add to getter names**:
```dart
static String getAnimationName(AnimationType type) {
  switch (type) {
    // ... existing cases
    case AnimationType.myCustomAnimation:
      return 'My Custom Animation';
  }
}
```

---

## 🧪 Testing

### Test All Animations

```dart
void testAllAnimations() async {
  for (final type in AnimationType.values) {
    AnimationVariants.setAnimationType(type);
    print('Testing: ${AnimationVariants.getAnimationName(type)}');
    
    // Create and verify route
    final route = AnimationVariants.createRoute(const MyTestPage());
    expect(route, isNotNull);
  }
}
```

### Test Persistence

```dart
void testPersistence() async {
  // Save
  await AnimationPreferencesService.saveAnimationType(AnimationType.slideLeft);
  
  // Load
  final loaded = await AnimationPreferencesService.loadAnimationType();
  
  expect(loaded, equals(AnimationType.slideLeft));
}
```

---

## 📊 File Structure

```
lib/routes/
├── app_routes.dart                 # Main route definitions
├── animation_variants.dart         # Animation types & builders
├── animation_preferences.dart      # Preferences service & UI widgets
└── animation_showcase.dart         # Demo/preview page
```

---

## ⚡ Performance Notes

- ✅ Animations are GPU-accelerated
- ✅ No performance impact on app startup
- ✅ Smooth on most devices
- ✅ Preference loading is async and non-blocking

---

## 🔍 Debugging

### Check Current Animation

```dart
print(AnimationVariants.currentType);
print(AnimationVariants.getAnimationName(AnimationVariants.currentType));
```

### Monitor Preference Changes

```dart
AnimationVariants.setAnimationType(AnimationType.slideLeft);
final current = await AnimationPreferencesService.loadAnimationType();
print('Saved: $current');
```

---

## 🎯 Summary

| Feature | Status | Details |
|---------|--------|---------|
| Multiple animations | ✅ | 4 variants ready |
| Global switching | ✅ | Change anytime |
| Persistence | ✅ | SharedPreferences |
| UI selectors | ✅ | Card & Dropdown |
| Showcase/Demo | ✅ | Preview all types |
| Customizable | ✅ | Easy to add more |
| No breaking changes | ✅ | Backward compatible |

---

## 🚀 Next Steps

1. **Add animation selector to Settings page** - Use `AnimationVariantSelector` widget
2. **Test all animations** - Navigate between screens and try each variant
3. **Customize if needed** - Add your own animation types
4. **Share with users** - Let them choose their favorite animation style!

---

**Created:** November 18, 2025  
**Status:** ✅ Production Ready

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'models/task_model.dart';
import 'models/upload_models.dart';
import 'services/device_contacts_service.dart';
import 'services/file_upload_service.dart';
import 'services/task_sync_service.dart';

// ── POLISH HELPERS ───────────────────────────────────────────────────────────
void _hapticLight() => HapticFeedback.lightImpact();

class _TapSurface extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool haptic;

  const _TapSurface({
    required this.child,
    required this.onTap,
    this.borderRadius,
    this.haptic = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? BorderRadius.circular(12);
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: r,
        splashColor: cs.primary.withValues(alpha: 0.14),
        highlightColor: cs.primary.withValues(alpha: 0.08),
        onTap: onTap == null
            ? null
            : () {
                if (haptic) _hapticLight();
                onTap!();
              },
        child: child,
      ),
    );
  }
}

class AppTheme {
  const AppTheme._();

  // Primary brand
  static const Color primary50 = Color(0xFFEEF2FF);
  static const Color primary100 = Color(0xFFE0E7FF);
  static const Color primary400 = Color(0xFF818CF8);
  static const Color primary500 = Color(0xFF6366F1);
  static const Color primary600 = Color(0xFF4F46E5);
  static const Color primary700 = Color(0xFF4338CA);

  // Accent / CTA
  static const Color accent400 = Color(0xFF34D399);
  static const Color accent500 = Color(0xFF10B981);

  // Neutrals
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray900 = Color(0xFF111827);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Dark mode
  static const Color bgDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color borderDark = Color(0xFF2A2A2A);
  static const Color textDark = Color(0xFFFFFFFF);

  // Layout primitives
  static const double containerMaxWidth = 1280;
  static const EdgeInsets containerPadding = EdgeInsets.symmetric(
    horizontal: 24,
  );

  static TextTheme _textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(brightness: brightness).textTheme;
    final inter = GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: isDark ? textDark : gray900,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: isDark ? textDark : gray900,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: isDark ? textDark : gray900,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: isDark ? textDark : gray900,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? textDark : gray900,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: isDark ? textDark : gray900,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: isDark ? textDark : gray600,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? gray400 : gray600,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? textDark : gray900,
      ),
    );
    return inter;
  }

  static TextStyle monoStyle({Color? color, double size = 13}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static ThemeData light() {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary500,
        onPrimary: Colors.white,
        secondary: accent500,
        onSecondary: Colors.white,
        error: error,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: gray900,
      ),
      scaffoldBackgroundColor: gray50,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.linux: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.fuchsia: _FadeSlidePageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: gray50,
        foregroundColor: gray900,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: gray900,
          letterSpacing: -0.35,
        ),
      ),
      dividerColor: gray200,
      cardTheme: CardThemeData(
        color: Colors.white,
        margin: const EdgeInsets.all(0),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: gray200),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        indicatorColor: primary50,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(
          color: gray700,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(color: gray400),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary500, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: primary500,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontWeight: FontWeight.w500),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ).copyWith(
              overlayColor: WidgetStatePropertyAll(
                Colors.white.withValues(alpha: 0.08),
              ),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary600,
          side: const BorderSide(color: primary100),
          backgroundColor: primary50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary600,
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary500,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: gray400),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary500;
          return Colors.transparent;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return gray100;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent500;
          return gray400;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: gray600,
        textColor: gray900,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearMinHeight: 8,
        color: primary500,
        linearTrackColor: gray200,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: gray900,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        backgroundColor: primary50,
        labelStyle: const TextStyle(
          color: primary600,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide.none,
      ),
    );
    return base.copyWith(textTheme: _textTheme(Brightness.light));
  }

  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.white,
        onSecondary: Colors.black,
        error: error,
        onError: Colors.white,
        surface: surfaceDark,
        onSurface: textDark,
      ),
      scaffoldBackgroundColor: bgDark,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.linux: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.fuchsia: _FadeSlidePageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: textDark,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textDark,
          letterSpacing: -0.35,
        ),
      ),
      dividerColor: borderDark,
      cardTheme: CardThemeData(
        color: surfaceDark,
        margin: const EdgeInsets.all(0),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderDark),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        indicatorColor: Colors.white.withValues(alpha: 0.14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        labelStyle: const TextStyle(
          color: textDark,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(color: gray400),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white70, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: borderDark),
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: gray400),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.transparent;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return gray400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white54;
          return borderDark;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: gray400,
        textColor: textDark,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearMinHeight: 8,
        color: Colors.white,
        linearTrackColor: borderDark,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceDark,
        contentTextStyle: TextStyle(color: textDark),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        backgroundColor: Colors.white.withValues(alpha: 0.14),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide.none,
      ),
    );
    return base.copyWith(textTheme: _textTheme(Brightness.dark));
  }
}

class _FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

// ── ENTRY POINT ─────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  final appState = AppState();
  runApp(TaskMateApp(appState: appState));
}

String _friendlyFirestoreError(
  Object? error, {
  required String fallback,
  String? indexHint,
}) {
  final msg = (error?.toString() ?? '').toLowerCase();
  if (msg.contains('permission-denied')) {
    return 'Permission denied. Please check Firestore rules.';
  }
  if (msg.contains('failed-precondition') || msg.contains('index')) {
    return indexHint ?? 'Required index is building. Please try again shortly.';
  }
  if (msg.contains('unavailable') || msg.contains('network')) {
    return 'Network unavailable. Check your internet connection.';
  }
  return fallback;
}

// ── PHONE CONTACT MODEL (simulates device contacts) ──────────────────────────
class PhoneContact {
  final String name;
  final String phone;
  PhoneContact({required this.name, required this.phone});

  Map<String, String> toMap() => {'name': name, 'phone': phone};

  static PhoneContact fromMap(Map<dynamic, dynamic> raw) {
    return PhoneContact(
      name: (raw['name'] as String? ?? '').trim(),
      phone: (raw['phone'] as String? ?? '').trim(),
    );
  }
}

class InviteDispatchSummary {
  final int inAppInviteCount;
  final int emailInviteCount;
  final List<String> manualSmsRecipients;

  const InviteDispatchSummary({
    this.inAppInviteCount = 0,
    this.emailInviteCount = 0,
    this.manualSmsRecipients = const [],
  });

  int get manualSmsCount => manualSmsRecipients.length;
}

// Fallback mock contacts shown when contact sync is unavailable.
final kMockPhoneContacts = [
  PhoneContact(name: 'Nishan Dhanuk', phone: '+977 98410 11111'),
  PhoneContact(name: 'Hemant Chaulagain', phone: '+977 98420 22222'),
  PhoneContact(name: 'Anmol Karki', phone: '+977 98430 33333'),
  PhoneContact(name: 'Bhuban Gurung', phone: '+977 98440 44444'),
  PhoneContact(name: 'Raj Basnet', phone: '+977 98450 55555'),
  PhoneContact(name: 'Sita Sharma', phone: '+977 98460 66666'),
  PhoneContact(name: 'Priya Thapa', phone: '+977 98470 77777'),
  PhoneContact(name: 'Arun KC', phone: '+977 98480 88888'),
  PhoneContact(name: 'Deepak Pandey', phone: '+977 98490 99999'),
  PhoneContact(name: 'Manisha Rai', phone: '+977 98400 10101'),
];

// ── GROUP MEMBER MODEL ───────────────────────────────────────────────────────
class GroupMember {
  final String name;
  final String phone;
  bool isAdmin;
  final bool isAppUser; // false = invited externally, not yet joined
  /// Firebase Auth uid when this member is a TaskMate user (synced via `groups`).
  final String? userId;

  GroupMember({
    required this.name,
    required this.phone,
    this.isAdmin = false,
    this.isAppUser = false,
    this.userId,
  });

  Map<String, dynamic> toFirestoreMap() => {
    'name': name,
    'phone': phone,
    'isAdmin': isAdmin,
    'isAppUser': isAppUser,
    if (userId != null && userId!.isNotEmpty) 'userId': userId,
  };

  static GroupMember fromFirestoreMap(Map<String, dynamic> m) {
    return GroupMember(
      name: m['name'] as String? ?? '',
      phone: m['phone'] as String? ?? '',
      isAdmin: m['isAdmin'] as bool? ?? false,
      isAppUser: m['isAppUser'] as bool? ?? false,
      userId: m['userId'] as String?,
    );
  }
}

// ── TASKMATE USER MODEL (Firestore `users` collection) ───────────────────────
class TaskMateUser {
  final String uid;
  final String displayName;
  final String email;
  final String? phoneNumber;

  TaskMateUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.phoneNumber,
  });

  static TaskMateUser fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return TaskMateUser(
      uid: (data['uid'] as String?) ?? doc.id,
      email: (data['email'] as String?) ?? '',
      displayName: ((data['displayName'] as String?) ?? '').trim(),
      phoneNumber: data['phoneNumber'] as String?,
    );
  }

  String get bestLabel {
    final n = displayName.trim();
    if (n.isNotEmpty) return n;
    if (email.trim().isNotEmpty) return email.trim();
    return uid;
  }
}

// ── MODELS ───────────────────────────────────────────────────────────────────
class AppEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final bool allDay;
  final String? location;
  final String? groupId;
  final List<String> participantUids;
  final String createdByUid;
  final bool isReminder;
  final Color color;
  AppEvent({
    required this.id,
    required this.title,
    this.description,
    required this.start,
    required this.end,
    this.allDay = false,
    this.location,
    this.groupId,
    this.participantUids = const [],
    this.createdByUid = '',
    this.isReminder = false,
    required this.color,
  });

  DateTime get date => start;
}

class ActivityEntry {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime time;
  ActivityEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.time,
  });
}

class UserModel extends ChangeNotifier {
  String uid = '';
  String email = '';
  String displayName = '';
  String? phoneNumber;
  String? photoUrl;
  String? avatarPresetId;
  bool isLoggedIn = false;

  void login(String e, String name, {String? userId}) {
    uid = userId ?? uid;
    email = e;
    displayName = name;
    isLoggedIn = true;
    notifyListeners();
  }

  void loginFromFirebaseUser(fa.User user, {String? fallbackDisplayName}) {
    uid = user.uid;
    email = user.email ?? '';
    displayName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : (fallbackDisplayName ?? '').trim();
    final normalizedPhoto = (user.photoURL ?? '').trim();
    photoUrl = normalizedPhoto.isNotEmpty ? normalizedPhoto : null;
    isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    uid = '';
    email = '';
    displayName = '';
    phoneNumber = null;
    photoUrl = null;
    avatarPresetId = null;
    notifyListeners();
  }

  void updateName(String n) {
    displayName = n;
    notifyListeners();
  }

  void updatePhone(String p) {
    phoneNumber = p;
    notifyListeners();
  }

  void updateEmail(String e) {
    email = e;
    notifyListeners();
  }

  void updateAvatar({String? photoUrl, String? avatarPresetId}) {
    this.photoUrl = (photoUrl ?? '').trim().isEmpty ? null : photoUrl!.trim();
    this.avatarPresetId = (avatarPresetId ?? '').trim().isEmpty
        ? null
        : avatarPresetId!.trim();
    notifyListeners();
  }
}

class _AvatarPreset {
  final String id;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const _AvatarPreset({
    required this.id,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });
}

const List<_AvatarPreset> _kAvatarPresets = [
  _AvatarPreset(
    id: 'person_indigo',
    icon: Icons.person_rounded,
    backgroundColor: Color(0xFFE0E7FF),
    foregroundColor: Color(0xFF4338CA),
  ),
  _AvatarPreset(
    id: 'work_blue',
    icon: Icons.work_rounded,
    backgroundColor: Color(0xFFDBEAFE),
    foregroundColor: Color(0xFF1D4ED8),
  ),
  _AvatarPreset(
    id: 'rocket_purple',
    icon: Icons.rocket_launch_rounded,
    backgroundColor: Color(0xFFEDE9FE),
    foregroundColor: Color(0xFF7C3AED),
  ),
  _AvatarPreset(
    id: 'star_orange',
    icon: Icons.star_rounded,
    backgroundColor: Color(0xFFFFEDD5),
    foregroundColor: Color(0xFFEA580C),
  ),
  _AvatarPreset(
    id: 'verified_teal',
    icon: Icons.verified_rounded,
    backgroundColor: Color(0xFFCCFBF1),
    foregroundColor: Color(0xFF0F766E),
  ),
  _AvatarPreset(
    id: 'favorite_rose',
    icon: Icons.favorite_rounded,
    backgroundColor: Color(0xFFFFE4E6),
    foregroundColor: Color(0xFFBE123C),
  ),
];

_AvatarPreset? _avatarPresetFromId(String? id) {
  if (id == null || id.trim().isEmpty) return null;
  for (final preset in _kAvatarPresets) {
    if (preset.id == id) return preset;
  }
  return null;
}

class _UserAvatar extends StatelessWidget {
  final UserModel user;
  final double radius;
  final bool emphasized;

  const _UserAvatar({
    required this.user,
    this.radius = 20,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final preset = _avatarPresetFromId(user.avatarPresetId);
    final hasPhoto = (user.photoUrl ?? '').trim().isNotEmpty;
    final initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';
    final backgroundColor =
        preset?.backgroundColor ??
        (emphasized ? AppTheme.primary500 : AppTheme.primary100);
    final foregroundColor =
        preset?.foregroundColor ??
        (emphasized ? Colors.white : AppTheme.primary500);
    final fallbackChild = preset != null
        ? Icon(preset.icon, color: foregroundColor, size: radius * 0.95)
        : Text(
            initial,
            style: TextStyle(
              color: foregroundColor,
              fontSize: radius * 0.82,
              fontWeight: FontWeight.bold,
            ),
          );

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      foregroundImage: hasPhoto ? NetworkImage(user.photoUrl!.trim()) : null,
      onForegroundImageError: hasPhoto ? (_, _) {} : null,
      child: fallbackChild,
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  final GroupModel group;
  final double radius;

  const _GroupAvatar({required this.group, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (group.photoUrl ?? '').trim().isNotEmpty;
    final initial = group.name.trim().isNotEmpty
        ? group.name.trim()[0].toUpperCase()
        : 'G';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primary500,
      foregroundImage: hasPhoto ? NetworkImage(group.photoUrl!.trim()) : null,
      onForegroundImageError: hasPhoto ? (_, _) {} : null,
      child: hasPhoto
          ? null
          : Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.9,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class FolderCategory {
  final String name;
  final IconData icon;
  final Color color;
  final bool isCustom;
  FolderCategory({
    required this.name,
    required this.icon,
    required this.color,
    this.isCustom = false,
  });
}

// ── GROUP MODEL ──────────────────────────────────────────────────────────────
class GroupModel {
  final String id;
  String name;
  final String code;
  String? photoUrl;
  final List<GroupMember> members;
  final DateTime createdAt;
  DateTime? deadline;
  String? description;
  bool lockChat;
  bool disappearingMessages;
  String? creatorUid;

  GroupModel({
    required this.id,
    required this.name,
    required this.code,
    this.photoUrl,
    required this.members,
    required this.createdAt,
    this.deadline,
    this.description,
    this.lockChat = false,
    this.disappearingMessages = false,
    this.creatorUid,
  });

  int get memberCount => members.length + 1; // +1 for the creator (you)

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final rawMembers = d['members'];
    final members = <GroupMember>[];
    if (rawMembers is List) {
      for (final e in rawMembers) {
        if (e is Map) {
          members.add(
            GroupMember.fromFirestoreMap(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    final createdAt =
        (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return GroupModel(
      id: (d['id'] as String?) ?? doc.id,
      name: (d['name'] as String?) ?? '',
      code: (d['code'] as String?) ?? '',
      photoUrl: ((d['photoUrl'] as String?)?.trim().isNotEmpty ?? false)
          ? (d['photoUrl'] as String).trim()
          : null,
      members: members,
      createdAt: createdAt,
      deadline: (d['deadline'] as Timestamp?)?.toDate(),
      description: d['description'] as String?,
      lockChat: d['lockChat'] as bool? ?? false,
      disappearingMessages: d['disappearingMessages'] as bool? ?? false,
      creatorUid: d['creatorUid'] as String?,
    );
  }
}

// ── APP STATE ────────────────────────────────────────────────────────────────
class AppState extends ChangeNotifier {
  AppState({
    FileUploadService? fileUploadService,
    TaskSyncService? taskSyncService,
  }) : _fileUploadService = fileUploadService ?? FileUploadService(),
       _taskSyncService = taskSyncService ?? TaskSyncService();

  ThemeMode themeMode = ThemeMode.light;
  Color chatAccentColor = AppTheme.primary500;
  bool notificationsEnabled = true;
  bool privateProfile = false;
  bool readReceipts = true;
  bool taskReminders = true;
  bool groupMessages = true;
  bool mentionAlerts = true;
  bool soundEnabled = true;
  bool vibrateEnabled = false;
  bool googleCalendarConnected = false;
  bool outlookCalendarConnected = false;
  bool isCalendarSyncing = false;
  DateTime? calendarLastSyncedAt;
  final List<AppEvent> events = [];
  final List<ActivityEntry> activityLog = [];
  final UserModel user = UserModel();
  final List<GroupModel> groups = [];
  final List<TaskModel> tasks = [];
  final Map<String, double> uploadProgressByFile = {};
  bool isUploading = false;

  final FileUploadService _fileUploadService;
  final TaskSyncService _taskSyncService;

  StreamSubscription<QuerySnapshot>? _groupsSub;
  StreamSubscription<QuerySnapshot>? _eventsSub;
  StreamSubscription<QuerySnapshot>? _tasksSub;

  void stopUserSync() {
    stopGroupsSync();
    _eventsSub?.cancel();
    _eventsSub = null;
    _tasksSub?.cancel();
    _tasksSub = null;
  }

  void stopGroupsSync() {
    _groupsSub?.cancel();
    _groupsSub = null;
  }

  /// Keeps [groups] in sync with Firestore for every group where the user is in [memberUids].
  void startGroupsSync(String myUid) {
    if (myUid.isEmpty) return;
    try {
      if (Firebase.apps.isEmpty) return;
    } catch (_) {
      return;
    }
    _groupsSub?.cancel();
    _groupsSub = FirebaseFirestore.instance
        .collection('groups')
        .where('memberUids', arrayContains: myUid)
        .snapshots()
        .listen((snapshot) {
          final remoteById = <String, GroupModel>{};
          for (final doc in snapshot.docs) {
            try {
              final g = GroupModel.fromFirestore(doc);
              remoteById[g.id] = g;
            } catch (_) {}
          }
          final merged = <GroupModel>[];
          for (final g in groups) {
            if (!remoteById.containsKey(g.id)) merged.add(g);
          }
          merged.addAll(remoteById.values);
          merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          groups
            ..clear()
            ..addAll(merged);
          notifyListeners();
        });
  }

  void startEventsSync(String myUid) {
    if (myUid.isEmpty) return;
    try {
      if (Firebase.apps.isEmpty) return;
    } catch (_) {
      return;
    }
    _eventsSub?.cancel();
    _eventsSub = FirebaseFirestore.instance
        .collection('events')
        .where('participantUids', arrayContains: myUid)
        .snapshots()
        .listen((snapshot) {
          final next = <AppEvent>[];
          for (final doc in snapshot.docs) {
            final m = (doc.data() as Map<String, dynamic>?) ?? {};
            final start = (m['start'] as Timestamp?)?.toDate();
            final end = (m['end'] as Timestamp?)?.toDate();
            if (start == null || end == null) continue;
            final colorInt =
                (m['color'] as int?) ?? const Color(0xFF4F46E5).toARGB32();
            next.add(
              AppEvent(
                id: doc.id,
                title: (m['title'] as String?) ?? '',
                description: (m['description'] as String?),
                start: start,
                end: end,
                allDay: (m['allDay'] as bool?) ?? false,
                location: (m['location'] as String?),
                groupId: (m['groupId'] as String?),
                participantUids:
                    ((m['participantUids'] as List?)?.cast<String>() ??
                    const []),
                createdByUid: (m['createdByUid'] as String?) ?? '',
                isReminder: (m['isReminder'] as bool?) ?? false,
                color: Color(colorInt),
              ),
            );
          }
          next.sort((a, b) => a.start.compareTo(b.start));
          events
            ..clear()
            ..addAll(next);
          notifyListeners();
        });
  }

  void startTasksSync(String myUid) {
    if (myUid.isEmpty) return;
    try {
      if (Firebase.apps.isEmpty) return;
    } catch (_) {
      return;
    }
    _tasksSub?.cancel();
    _tasksSub = FirebaseFirestore.instance
        .collection('tasks')
        .where('participantUids', arrayContains: myUid)
        .snapshots()
        .listen((snapshot) {
          final next = _taskSyncService.tasksFromSnapshot(snapshot);
          tasks
            ..clear()
            ..addAll(next);
          notifyListeners();
        });
  }

  Future<void> persistGroupToFirestore(GroupModel group) async {
    try {
      if (Firebase.apps.isEmpty) return;
    } catch (_) {
      return;
    }
    final creator = group.creatorUid ?? user.uid;
    final memberUids = <String>{};
    if (creator.isNotEmpty) memberUids.add(creator);
    for (final m in group.members) {
      if (m.userId != null && m.userId!.isNotEmpty) memberUids.add(m.userId!);
    }
    await FirebaseFirestore.instance.collection('groups').doc(group.id).set({
      'id': group.id,
      'name': group.name,
      'code': group.code,
      'photoUrl': group.photoUrl,
      'creatorUid': creator,
      'memberUids': memberUids.toList(),
      'members': group.members.map((m) => m.toFirestoreMap()).toList(),
      'createdAt': Timestamp.fromDate(group.createdAt),
      if (group.deadline != null)
        'deadline': Timestamp.fromDate(group.deadline!),
      if (group.description != null) 'description': group.description,
      'lockChat': group.lockChat,
      'disappearingMessages': group.disappearingMessages,
    });
  }

  Future<void> syncGroupToFirestore(GroupModel group) async {
    try {
      if (Firebase.apps.isEmpty) return;
    } catch (_) {
      return;
    }
    final creator = group.creatorUid ?? user.uid;
    final memberUids = <String>{};
    if (creator.isNotEmpty) memberUids.add(creator);
    for (final m in group.members) {
      if (m.userId != null && m.userId!.isNotEmpty) memberUids.add(m.userId!);
    }
    await FirebaseFirestore.instance.collection('groups').doc(group.id).set({
      'name': group.name,
      'code': group.code,
      'photoUrl': group.photoUrl,
      'creatorUid': creator,
      'memberUids': memberUids.toList(),
      'members': group.members.map((m) => m.toFirestoreMap()).toList(),
      if (group.deadline != null)
        'deadline': Timestamp.fromDate(group.deadline!),
      if (group.description != null) 'description': group.description,
      'lockChat': group.lockChat,
      'disappearingMessages': group.disappearingMessages,
    }, SetOptions(merge: true));
  }

  void updateGroupName(String groupId, String newName) {
    final g = groups.firstWhere((g) => g.id == groupId);
    g.name = newName;
    notifyListeners();
    try {
      if (Firebase.apps.isEmpty) return;
    } catch (_) {
      return;
    }
    FirebaseFirestore.instance.collection('groups').doc(groupId).set({
      'name': newName,
    }, SetOptions(merge: true));
  }

  void addMembersToGroup(String groupId, List<GroupMember> newMembers) {
    final g = groups.firstWhere((g) => g.id == groupId);
    g.members.addAll(newMembers);
    notifyListeners();
  }

  bool isGroupAdmin(String groupId, String userUid) {
    final uidTrimmed = userUid.trim();
    if (uidTrimmed.isEmpty) return false;
    GroupModel? group;
    for (final g in groups) {
      if (g.id == groupId) {
        group = g;
        break;
      }
    }
    if (group == null) return false;
    if ((group.creatorUid ?? '').trim() == uidTrimmed) return true;
    for (final m in group.members) {
      if ((m.userId ?? '').trim() == uidTrimmed && m.isAdmin) return true;
    }
    return false;
  }

  Future<bool> removeMemberFromGroup({
    required String groupId,
    required GroupMember member,
    required String actingUid,
  }) async {
    if (!isGroupAdmin(groupId, actingUid)) return false;
    GroupModel? group;
    for (final g in groups) {
      if (g.id == groupId) {
        group = g;
        break;
      }
    }
    if (group == null) return false;

    final creatorUid = (group.creatorUid ?? '').trim();
    final targetUid = (member.userId ?? '').trim();
    if (targetUid.isNotEmpty && targetUid == creatorUid) return false;

    final beforeCount = group.members.length;
    group.members.removeWhere((m) {
      final sameUid =
          targetUid.isNotEmpty && (m.userId ?? '').trim() == targetUid;
      final samePhone =
          targetUid.isEmpty && m.phone.trim() == member.phone.trim();
      return sameUid || samePhone;
    });
    if (group.members.length == beforeCount) return false;

    notifyListeners();
    await syncGroupToFirestore(group);
    return true;
  }

  Future<bool> leaveGroup({
    required String groupId,
    required String userUid,
  }) async {
    final uidTrimmed = userUid.trim();
    if (uidTrimmed.isEmpty) return false;
    GroupModel? group;
    for (final g in groups) {
      if (g.id == groupId) {
        group = g;
        break;
      }
    }
    if (group == null) return false;
    if ((group.creatorUid ?? '').trim() == uidTrimmed) {
      // Creator/admin should delete workspace instead of leaving it orphaned.
      return false;
    }

    final beforeCount = group.members.length;
    group.members.removeWhere((m) => (m.userId ?? '').trim() == uidTrimmed);
    if (group.members.length == beforeCount) return false;

    await syncGroupToFirestore(group);
    groups.removeWhere((g) => g.id == groupId);
    notifyListeners();
    return true;
  }

  Future<bool> deleteGroupIfAdmin({
    required String groupId,
    required String actingUid,
  }) async {
    if (!isGroupAdmin(groupId, actingUid)) return false;
    groups.removeWhere((g) => g.id == groupId);
    notifyListeners();
    try {
      if (Firebase.apps.isEmpty) return true;
    } catch (_) {
      return true;
    }
    await FirebaseFirestore.instance.collection('groups').doc(groupId).delete();
    return true;
  }

  final List<FolderCategory> folderCategories = [
    FolderCategory(
      name: 'Images',
      icon: Icons.photo_library_rounded,
      color: AppTheme.info,
    ),
    FolderCategory(
      name: 'PDFs',
      icon: Icons.picture_as_pdf_outlined,
      color: AppTheme.error,
    ),
    FolderCategory(
      name: 'Word Docs',
      icon: Icons.description_rounded,
      color: AppTheme.primary500,
    ),
    FolderCategory(
      name: 'Videos',
      icon: Icons.videocam,
      color: AppTheme.primary400,
    ),
    FolderCategory(
      name: 'Important',
      icon: Icons.star,
      color: AppTheme.warning,
    ),
  ];

  // Chat list derived only from real created groups — no hardcoded data
  List<Map<String, dynamic>> get chatList => groups
      .map(
        (g) => {
          'name': g.name,
          'preview': 'Workspace · ${g.memberCount} members',
          'isUnread': false,
          'hasMention': false,
          'hasFile': false,
          'time': _formatChatTime(g.createdAt),
          'isGroup': true,
          'groupId': g.id,
        },
      )
      .toList();

  String _formatChatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inSeconds < 60) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24)
      return '${t.hour}:${t.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return 'Yesterday';
    return '${t.day}/${t.month}';
  }

  void setTheme(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }

  void setChatAccentColor(Color color) {
    chatAccentColor = color;
    notifyListeners();
  }

  bool get hasConnectedCalendarProvider =>
      googleCalendarConnected || outlookCalendarConnected;

  Future<void> connectCalendarProvider(String provider) async {
    if (provider == 'google') {
      final headers = await _googleCalendarHeaders(promptIfNecessary: true);
      if (headers == null || headers.isEmpty) {
        googleCalendarConnected = false;
        notifyListeners();
        return;
      }
      final res = await http.get(
        Uri.parse(
          'https://www.googleapis.com/calendar/v3/users/me/calendarList?maxResults=1',
        ),
        headers: headers,
      );
      googleCalendarConnected = res.statusCode >= 200 && res.statusCode < 300;
    } else if (provider == 'outlook') {
      outlookCalendarConnected = true;
    }
    notifyListeners();
  }

  void disconnectCalendarProvider(String provider) {
    if (provider == 'google') {
      googleCalendarConnected = false;
    } else if (provider == 'outlook') {
      outlookCalendarConnected = false;
    }
    notifyListeners();
  }

  Future<bool> syncCalendarsNow() async {
    if (!hasConnectedCalendarProvider || isCalendarSyncing) return false;
    isCalendarSyncing = true;
    notifyListeners();
    try {
      var syncedAny = false;
      if (googleCalendarConnected) {
        syncedAny = await _syncWithGoogleCalendar() || syncedAny;
      }
      if (outlookCalendarConnected) {
        // Phase 2 scaffold: provider state only. Full Outlook API flow comes next.
        syncedAny = true;
      }
      calendarLastSyncedAt = DateTime.now();
      _logActivity(
        ActivityEntry(
          title: 'Calendar Sync Complete',
          subtitle:
              '${googleCalendarConnected ? 'Google' : ''}${googleCalendarConnected && outlookCalendarConnected ? ' + ' : ''}${outlookCalendarConnected ? 'Outlook' : ''}',
          icon: Icons.sync_rounded,
          color: AppTheme.info,
          time: calendarLastSyncedAt!,
        ),
      );
      return syncedAny;
    } finally {
      isCalendarSyncing = false;
      notifyListeners();
    }
  }

  Future<Map<String, String>?> _googleCalendarHeaders({
    required bool promptIfNecessary,
  }) async {
    try {
      final google = GoogleSignIn.instance;
      const scopes = ['https://www.googleapis.com/auth/calendar'];
      GoogleSignInAccount? account;
      final lightweight = google.attemptLightweightAuthentication();
      if (lightweight != null) {
        account = await lightweight;
      }
      account ??= await google.authenticate();
      return await account.authorizationClient.authorizationHeaders(
        scopes,
        promptIfNecessary: promptIfNecessary,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _syncWithGoogleCalendar() async {
    final headers = await _googleCalendarHeaders(promptIfNecessary: false);
    if (headers == null || headers.isEmpty) return false;

    final timeMin = DateTime.now()
        .subtract(const Duration(days: 30))
        .toUtc()
        .toIso8601String();
    final listUrl = Uri.parse(
      'https://www.googleapis.com/calendar/v3/calendars/primary/events?singleEvents=true&showDeleted=false&maxResults=2500&timeMin=$timeMin',
    );
    final listRes = await http.get(listUrl, headers: headers);
    if (listRes.statusCode < 200 || listRes.statusCode >= 300) {
      return false;
    }
    final payload =
        (jsonDecode(listRes.body) as Map<String, dynamic>?) ?? const {};
    final remoteItems =
        (payload['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    final remoteByTaskMateId = <String, Map<String, dynamic>>{};
    for (final item in remoteItems) {
      final ext = (item['extendedProperties'] as Map?)?['private'];
      final privateMap = ext is Map ? Map<String, dynamic>.from(ext) : null;
      final taskMateId = (privateMap?['taskMateEventId'] as String?)?.trim();
      if (taskMateId != null && taskMateId.isNotEmpty) {
        remoteByTaskMateId[taskMateId] = item;
      }
    }

    var pushed = 0;
    var imported = 0;
    for (final e in events) {
      if (remoteByTaskMateId.containsKey(e.id)) continue;
      final body = <String, dynamic>{
        'summary': e.title,
        'description': e.description ?? '',
        'start': e.allDay
            ? {
                'date':
                    '${e.start.year.toString().padLeft(4, '0')}-${e.start.month.toString().padLeft(2, '0')}-${e.start.day.toString().padLeft(2, '0')}',
              }
            : {'dateTime': e.start.toUtc().toIso8601String()},
        'end': e.allDay
            ? {
                'date':
                    '${e.end.year.toString().padLeft(4, '0')}-${e.end.month.toString().padLeft(2, '0')}-${e.end.day.toString().padLeft(2, '0')}',
              }
            : {'dateTime': e.end.toUtc().toIso8601String()},
        'extendedProperties': {
          'private': {
            'taskMateEventId': e.id,
            if (e.groupId != null && e.groupId!.isNotEmpty)
              'taskMateGroupId': e.groupId!,
          },
        },
      };
      final createRes = await http.post(
        Uri.parse(
          'https://www.googleapis.com/calendar/v3/calendars/primary/events',
        ),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (createRes.statusCode >= 200 && createRes.statusCode < 300) {
        pushed++;
      }
    }

    final localIds = events.map((e) => e.id).toSet();
    final myUid = fa.FirebaseAuth.instance.currentUser?.uid ?? '';
    for (final item in remoteItems) {
      final ext = (item['extendedProperties'] as Map?)?['private'];
      final privateMap = ext is Map ? Map<String, dynamic>.from(ext) : null;
      final taskMateId = (privateMap?['taskMateEventId'] as String?)?.trim();
      if (taskMateId != null && taskMateId.isNotEmpty) continue;

      final remoteId = (item['id'] as String?)?.trim();
      if (remoteId == null || remoteId.isEmpty) continue;
      final localId = 'gcal_$remoteId';
      if (localIds.contains(localId)) continue;

      final title = (item['summary'] as String?)?.trim();
      if (title == null || title.isEmpty) continue;

      final startMap = (item['start'] as Map?)?.cast<String, dynamic>() ?? {};
      final endMap = (item['end'] as Map?)?.cast<String, dynamic>() ?? {};
      final startDateTimeRaw = (startMap['dateTime'] as String?)?.trim();
      final endDateTimeRaw = (endMap['dateTime'] as String?)?.trim();
      final startDateRaw = (startMap['date'] as String?)?.trim();
      final endDateRaw = (endMap['date'] as String?)?.trim();

      DateTime? start;
      DateTime? end;
      var allDay = false;
      if (startDateTimeRaw != null && endDateTimeRaw != null) {
        start = DateTime.tryParse(startDateTimeRaw)?.toLocal();
        end = DateTime.tryParse(endDateTimeRaw)?.toLocal();
      } else if (startDateRaw != null && endDateRaw != null) {
        start = DateTime.tryParse(startDateRaw);
        end = DateTime.tryParse(endDateRaw);
        allDay = true;
      }
      if (start == null || end == null) continue;

      final importedEvent = AppEvent(
        id: localId,
        title: title,
        description: (item['description'] as String?)?.trim(),
        start: start,
        end: end,
        allDay: allDay,
        location: (item['location'] as String?)?.trim(),
        groupId: null,
        participantUids: [if (myUid.isNotEmpty) myUid],
        createdByUid: myUid,
        isReminder: false,
        color: AppTheme.info,
      );
      events.add(importedEvent);
      localIds.add(localId);
      imported++;
      unawaited(_persistEvent(importedEvent));
    }

    if (imported > 0) {
      events.sort((a, b) => a.start.compareTo(b.start));
      notifyListeners();
    }
    return pushed > 0 || imported > 0 || remoteItems.isNotEmpty;
  }

  /// Call after mutating nested group data (e.g. `GroupModel.members`) so app-wide listeners update.
  void refresh() => notifyListeners();

  void toggle(String key, bool val) {
    switch (key) {
      case 'notifications':
        notificationsEnabled = val;
        break;
      case 'private':
        privateProfile = val;
        break;
      case 'receipts':
        readReceipts = val;
        break;
      case 'taskReminders':
        taskReminders = val;
        break;
      case 'groupMessages':
        groupMessages = val;
        break;
      case 'mentions':
        mentionAlerts = val;
        break;
      case 'sound':
        soundEnabled = val;
        break;
      case 'vibrate':
        vibrateEnabled = val;
        break;
    }
    notifyListeners();
  }

  void addEvent(AppEvent e) {
    events.add(e);
    _logActivity(
      ActivityEntry(
        title: 'Event Added',
        subtitle: e.title,
        icon: Icons.event_rounded,
        color: e.color,
        time: DateTime.now(),
      ),
    );
    notifyListeners();
    _persistEvent(e);
  }

  void removeEvent(AppEvent e) {
    final myUid = fa.FirebaseAuth.instance.currentUser?.uid ?? '';
    final canDelete =
        myUid.isNotEmpty &&
        (e.createdByUid == myUid || e.participantUids.contains(myUid));
    if (!canDelete) return;
    events.remove(e);
    notifyListeners();
    _deleteEvent(e);
  }

  Future<void> _persistEvent(AppEvent e) async {
    final myUid = fa.FirebaseAuth.instance.currentUser?.uid ?? '';
    if (myUid.isEmpty) return;
    try {
      if (Firebase.apps.isEmpty) return;
    } catch (_) {
      return;
    }
    final docId = e.id.isNotEmpty
        ? e.id
        : '${e.start.millisecondsSinceEpoch}_${myUid.substring(0, 6)}';
    final participants = <String>{myUid, ...e.participantUids};
    await FirebaseFirestore.instance.collection('events').doc(docId).set({
      'title': e.title,
      'description': e.description,
      'start': Timestamp.fromDate(e.start),
      'end': Timestamp.fromDate(e.end),
      'allDay': e.allDay,
      'location': e.location,
      'groupId': e.groupId,
      'participantUids': participants.toList(),
      'createdByUid': myUid,
      'isReminder': e.isReminder,
      'color': e.color.toARGB32(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Lightweight “notify them”: create a notification doc for each participant (in-app).
    for (final uid in participants) {
      if (uid == myUid) continue;
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid': uid,
        'type': 'event',
        'title': 'New event',
        'body': e.title,
        'createdAt': FieldValue.serverTimestamp(),
        'eventId': docId,
      });
    }
  }

  Future<void> _deleteEvent(AppEvent e) async {
    final myUid = fa.FirebaseAuth.instance.currentUser?.uid ?? '';
    if (myUid.isEmpty) return;
    try {
      if (Firebase.apps.isEmpty) return;
    } catch (_) {
      return;
    }
    await FirebaseFirestore.instance.collection('events').doc(e.id).delete();
  }

  void _logActivity(ActivityEntry a) {
    activityLog.insert(0, a);
    if (activityLog.length > 50) activityLog.removeLast();
  }

  void logChatActivity(String name, String preview) {
    _logActivity(
      ActivityEntry(
        title: 'Message in $name',
        subtitle: preview,
        icon: Icons.chat_bubble_outline_rounded,
        color: AppTheme.primary500,
        time: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void addFolderCategory(FolderCategory cat) {
    folderCategories.add(cat);
    notifyListeners();
  }

  Future<UploadBatchResult> uploadFiles({
    required List<PlatformFile> files,
    String? groupId,
    String? chatId,
  }) async {
    final my = fa.FirebaseAuth.instance.currentUser;
    if (my == null) {
      return UploadBatchResult(
        attemptedCount: files.length,
        uploadedEntries: const [],
        failedEntries: files
            .map(
              (f) => FileUploadFailure(
                sourceFile: f,
                reason: 'Sign in required to upload files.',
                retryable: false,
              ),
            )
            .toList(),
      );
    }
    final myUid = my.uid;

    isUploading = true;
    uploadProgressByFile.clear();
    notifyListeners();
    try {
      final result = await _fileUploadService.uploadFiles(
        files: files,
        ownerUid: myUid,
        groupId: groupId,
        chatId: chatId,
        onProgress: (fileKey, progress) {
          uploadProgressByFile[fileKey] = progress.clamp(0, 1);
          notifyListeners();
        },
      );
      if (result.hasSuccesses) {
        _logActivity(
          ActivityEntry(
            title: 'Files Uploaded',
            subtitle:
                '${result.uploadedCount} file${result.uploadedCount == 1 ? '' : 's'} uploaded',
            icon: Icons.upload_file_rounded,
            color: AppTheme.primary500,
            time: DateTime.now(),
          ),
        );
      }
      return result;
    } finally {
      isUploading = false;
      uploadProgressByFile.clear();
      notifyListeners();
    }
  }

  Future<UploadBatchResult> retryFailedUploads({
    required UploadBatchResult previousResult,
    String? groupId,
    String? chatId,
  }) {
    final retryable = previousResult.retryableFiles;
    if (retryable.isEmpty) {
      return Future.value(
        UploadBatchResult(
          attemptedCount: 0,
          uploadedEntries: const [],
          failedEntries: const [],
        ),
      );
    }
    return uploadFiles(files: retryable, groupId: groupId, chatId: chatId);
  }

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  String _generateInviteToken() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    return List.generate(32, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  bool _looksLikePhoneNumber(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9+]'), '');
    final digitsOnly = cleaned.startsWith('+') ? cleaned.substring(1) : cleaned;
    return digitsOnly.length >= 7 && !value.contains('@');
  }

  bool _looksLikeEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
  }

  String _inviteMessageBody(GroupModel group) {
    return 'You are invited to join "${group.name}" on TaskMate. Join code: ${group.code}';
  }

  Future<void> openManualSmsComposer({
    required GroupModel group,
    String? phoneNumber,
  }) async {
    final uri = Uri(
      scheme: 'sms',
      path: (phoneNumber ?? '').trim(),
      queryParameters: {'body': _inviteMessageBody(group)},
    );
    await launchUrl(uri);
  }

  Future<InviteDispatchSummary> sendWorkspaceInvites(
    GroupModel group, {
    List<GroupMember>? recipients,
  }) async {
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    final emailEndpoint = Uri.parse(
      'https://us-central1-$projectId.cloudfunctions.net/sendWorkspaceInviteEmail',
    );
    final invitees = recipients ?? group.members;
    if (invitees.isEmpty) return const InviteDispatchSummary();

    final now = DateTime.now();
    final expireAt = now.add(const Duration(days: 7));
    final inviteCollection = FirebaseFirestore.instance.collection(
      'groupInvites',
    );
    var inAppInviteCount = 0;
    var emailInviteCount = 0;
    final manualSmsRecipients = <String>[];

    for (final m in invitees) {
      final inviteRef = inviteCollection.doc();
      final token = _generateInviteToken();
      final destination = m.phone.trim();
      final isEmail = _looksLikeEmail(destination);
      final isPhone = _looksLikePhoneNumber(destination);
      final isAppUser = m.userId != null && m.userId!.isNotEmpty;
      final channel = isAppUser
          ? 'in_app'
          : (isEmail ? 'email' : (isPhone ? 'manual_sms' : 'unknown'));
      await inviteRef.set({
        'id': inviteRef.id,
        'groupId': group.id,
        'groupName': group.name,
        'code': group.code,
        if (isEmail) 'email': destination,
        if (!isEmail) 'phone': destination,
        'inviteeName': m.name,
        'status': 'pending',
        'token': token,
        'channel': channel,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expireAt),
        'createdByUid': user.uid,
        if (m.userId != null && m.userId!.isNotEmpty) 'inviteeUid': m.userId,
      });

      if (isAppUser) {
        inAppInviteCount += 1;
        await FirebaseFirestore.instance.collection('notifications').add({
          'toUid': m.userId,
          'type': 'workspace_invite',
          'title': 'Workspace invite',
          'body':
              '${user.displayName.trim().isNotEmpty ? user.displayName.trim() : user.email} invited you to ${group.name}',
          'createdAt': FieldValue.serverTimestamp(),
          'groupId': group.id,
          'groupCode': group.code,
          'inviteId': inviteRef.id,
        });
        continue;
      }

      if (isEmail) {
        emailInviteCount += 1;
        try {
          await http
              .post(
                emailEndpoint,
                headers: const {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'inviteId': inviteRef.id,
                  'token': token,
                  'email': destination,
                  'workspaceName': group.name,
                  'inviteeName': m.name,
                  'joinCode': group.code,
                  'groupId': group.id,
                  'inviterName': user.displayName.trim().isNotEmpty
                      ? user.displayName.trim()
                      : user.email,
                }),
              )
              .timeout(const Duration(seconds: 15));
        } catch (_) {
          // Keep invite pending so it can be retried later.
        }
        continue;
      }

      if (isPhone) {
        manualSmsRecipients.add(destination);
        await inviteRef.set({
          'deliveryStatus': 'pending_manual_sms',
        }, SetOptions(merge: true));
      }
    }

    return InviteDispatchSummary(
      inAppInviteCount: inAppInviteCount,
      emailInviteCount: emailInviteCount,
      manualSmsRecipients: manualSmsRecipients,
    );
  }

  GroupModel createGroup(
    String name,
    List<GroupMember> members, {
    DateTime? deadline,
    String? description,
    String? creatorUid,
  }) {
    final group = GroupModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      code: _generateCode(),
      members: members,
      createdAt: DateTime.now(),
      deadline: deadline,
      description: description,
      creatorUid: creatorUid,
    );
    groups.add(group);
    _logActivity(
      ActivityEntry(
        title: 'Workspace Created: $name',
        subtitle:
            '${members.length} member${members.length != 1 ? 's' : ''} invited',
        icon: Icons.group,
        color: AppTheme.primary500,
        time: DateTime.now(),
      ),
    );
    notifyListeners();
    return group;
  }

  bool joinGroup(String code) {
    final exists = groups.any((g) => g.code == code);
    if (exists) {
      final g = groups.firstWhere((g) => g.code == code);
      _logActivity(
        ActivityEntry(
          title: 'Joined Workspace',
          subtitle: g.name,
          icon: Icons.group_add,
          color: AppTheme.success,
          time: DateTime.now(),
        ),
      );
      notifyListeners();
    }
    return exists;
  }

  /// Join a group by share code (Firestore). Other members see the group via [startGroupsSync].
  Future<bool> joinGroupByCode(String code) async {
    final norm = code.trim().toUpperCase();
    if (norm.isEmpty) return false;
    final myUid = user.uid;
    if (myUid.isEmpty) return false;
    try {
      if (Firebase.apps.isEmpty) return joinGroup(norm);
    } catch (_) {
      return joinGroup(norm);
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('groups')
          .where('code', isEqualTo: norm)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return false;
      final doc = snap.docs.first;
      final ref = doc.reference;
      final data = doc.data();
      final memberUids = List<String>.from(
        (data['memberUids'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
      );
      if (memberUids.contains(myUid)) return true;
      memberUids.add(myUid);
      final members = List<Map<String, dynamic>>.from(
        (data['members'] as List<dynamic>?)?.map(
              (e) => Map<String, dynamic>.from(e as Map),
            ) ??
            [],
      );
      final labelName = user.displayName.trim().isNotEmpty
          ? user.displayName.trim()
          : user.email.split('@').first;
      final labelPhone = (user.phoneNumber?.trim().isNotEmpty ?? false)
          ? user.phoneNumber!.trim()
          : user.email;
      members.add({
        'name': labelName,
        'phone': labelPhone,
        'isAppUser': true,
        'isAdmin': false,
        'userId': myUid,
      });
      await ref.update({'memberUids': memberUids, 'members': members});
      _logActivity(
        ActivityEntry(
          title: 'Joined Workspace',
          subtitle: (data['name'] as String?) ?? 'Workspace',
          icon: Icons.group_add,
          color: AppTheme.success,
          time: DateTime.now(),
        ),
      );
      notifyListeners();
      return true;
    } catch (_) {
      return joinGroup(norm);
    }
  }

  void updateGroupLock(String groupId, bool val) {
    final g = groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => groups.first,
    );
    g.lockChat = val;
    notifyListeners();
    try {
      if (Firebase.apps.isEmpty) return;
    } catch (_) {
      return;
    }
    FirebaseFirestore.instance.collection('groups').doc(groupId).set({
      'lockChat': val,
    }, SetOptions(merge: true));
  }

  void addTask(TaskModel task) {
    tasks.add(task);
    _logActivity(
      ActivityEntry(
        title: 'Task Created: ${task.title}',
        subtitle:
            'Assigned to ${task.assignedToNames.isEmpty ? '—' : task.assignedToNames.join(', ')} · ${_priorityLabel(task.priority)}',
        icon: Icons.task_alt,
        color: _priorityColor(task.priority),
        time: DateTime.now(),
      ),
    );
    notifyListeners();
    _persistTask(task);
  }

  void removeTask(TaskModel t) {
    final myUid = fa.FirebaseAuth.instance.currentUser?.uid ?? '';
    final canDelete =
        myUid.isNotEmpty &&
        (t.createdByUid == myUid || t.assignedToUids.contains(myUid));
    if (!canDelete) return;
    tasks.removeWhere((x) => x.id == t.id);
    notifyListeners();
    _deleteTask(t.id);
  }

  Future<void> _deleteTask(String taskId) async {
    final myUid = fa.FirebaseAuth.instance.currentUser?.uid ?? '';
    if (myUid.isEmpty) return;
    try {
      if (Firebase.apps.isEmpty) return;
    } catch (_) {
      return;
    }
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
  }

  Future<void> _persistTask(TaskModel t) async {
    final myUid = fa.FirebaseAuth.instance.currentUser?.uid ?? '';
    if (myUid.isEmpty) return;
    try {
      if (Firebase.apps.isEmpty) return;
    } catch (_) {
      return;
    }
    final participants = <String>{myUid, ...t.assignedToUids};
    await FirebaseFirestore.instance.collection('tasks').doc(t.id).set({
      'title': t.title,
      'description': t.description,
      'assignedToUids': t.assignedToUids,
      'assignedToNames': t.assignedToNames,
      'participantUids': participants.toList(),
      'priority': t.priority.name,
      'status': t.status.name,
      'dueDate': t.dueDate == null ? null : Timestamp.fromDate(t.dueDate!),
      'groupId': t.groupId,
      'createdByUid': myUid,
      'createdByName': user.displayName.trim().isNotEmpty
          ? user.displayName.trim()
          : (user.email.trim().isNotEmpty ? user.email.trim() : myUid),
      'createdAt': Timestamp.fromDate(t.createdAt),
    }, SetOptions(merge: true));

    for (final uid in participants) {
      if (uid == myUid) continue;
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid': uid,
        'type': 'task',
        'title': 'New task',
        'body': t.title,
        'createdAt': FieldValue.serverTimestamp(),
        'taskId': t.id,
      });
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final idx = tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = tasks[idx];
    final prev = task.status;
    task.status = status;
    _logActivity(
      ActivityEntry(
        title: 'Task Updated',
        subtitle: '${task.title} → ${_statusLabel(status)}',
        icon: Icons.update,
        color: _statusColor(status),
        time: DateTime.now(),
      ),
    );
    notifyListeners();

    try {
      await _taskSyncService.updateTaskFields(task.id, {'status': status.name});
    } catch (_) {
      task.status = prev;
      notifyListeners();
    }
  }

  Future<void> updateTaskPriority(String taskId, TaskPriority priority) async {
    final idx = tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = tasks[idx];
    final prev = task.priority;
    task.priority = priority;
    notifyListeners();
    try {
      await _taskSyncService.updateTaskFields(task.id, {
        'priority': priority.name,
      });
    } catch (_) {
      task.priority = prev;
      notifyListeners();
    }
  }

  String _priorityLabel(TaskPriority p) =>
      const {'low': 'Low', 'medium': 'Medium', 'high': 'High'}[p.name] ??
      'Medium';
  String _statusLabel(TaskStatus s) =>
      const {
        'todo': 'To Do',
        'inProgress': 'In Progress',
        'done': 'Done',
      }[s.name] ??
      'To Do';
  Color _priorityColor(TaskPriority p) => p == TaskPriority.low
      ? AppTheme.success
      : p == TaskPriority.high
      ? AppTheme.error
      : AppTheme.warning;
  Color _statusColor(TaskStatus s) => s == TaskStatus.done
      ? AppTheme.success
      : s == TaskStatus.inProgress
      ? AppTheme.info
      : AppTheme.gray400;
}

// ── APP ROOT ─────────────────────────────────────────────────────────────────
class TaskMateApp extends StatelessWidget {
  final AppState appState;
  const TaskMateApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (_, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: appState.themeMode,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: SplashScreen(appState: appState),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SPLASH SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  final AppState appState;
  const SplashScreen({super.key, required this.appState});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim, _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6)));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), _routeFromAuthState);
  }

  Future<void> _routeFromAuthState() async {
    if (!mounted) return;

    // In normal app startup, `main()` initializes Firebase before runApp.
    // In widget tests, Firebase may not be initialized; fall back to Login.
    if (Firebase.apps.isEmpty) {
      _replaceWith(LoginScreen(appState: widget.appState));
      return;
    }

    final current = fa.FirebaseAuth.instance.currentUser;
    if (current == null) {
      _replaceWith(LoginScreen(appState: widget.appState));
      return;
    }

    var introCompleted = false;
    // Hydrate app user from Firebase + Firestore profile.
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(current.uid)
          .get();
      final data = doc.data();
      final displayName = (data?['displayName'] as String?)?.trim();
      final phone = (data?['phoneNumber'] as String?)?.trim();
      final photoUrl = (data?['photoUrl'] as String?)?.trim();
      final avatarPresetId = (data?['avatarPresetId'] as String?)?.trim();
      introCompleted = (data?['introCompleted'] as bool?) ?? false;

      widget.appState.user.loginFromFirebaseUser(
        current,
        fallbackDisplayName: (displayName != null && displayName.isNotEmpty)
            ? displayName
            : (current.email?.split('@').first),
      );
      if (phone != null && phone.isNotEmpty) {
        widget.appState.user.updatePhone(phone);
      }
      widget.appState.user.updateAvatar(
        photoUrl: (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl : null,
        avatarPresetId: (avatarPresetId != null && avatarPresetId.isNotEmpty)
            ? avatarPresetId
            : null,
      );

      // Keep last login timestamp fresh.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(current.uid)
          .set({
            'uid': current.uid,
            'email': current.email,
            'displayName': widget.appState.user.displayName,
            'phoneNumber': widget.appState.user.phoneNumber,
            'photoUrl': widget.appState.user.photoUrl,
            'avatarPresetId': widget.appState.user.avatarPresetId,
            'lastLoginAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {
      // If Firestore read fails (rules/offline), still allow entry using Firebase user.
      widget.appState.user.loginFromFirebaseUser(
        current,
        fallbackDisplayName: current.email?.split('@').first,
      );
    }

    if (!mounted) return;
    final showIntro = !introCompleted;
    _replaceWith(
      MainNav(appState: widget.appState, showIntroOnLaunch: showIntro),
    );
  }

  void _replaceWith(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary500,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    color: AppTheme.primary500,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'TaskMate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Stay organised. Stay ahead.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOGIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  final AppState appState;
  const LoginScreen({super.key, required this.appState});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _signupName = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPass = TextEditingController();
  bool _obscureLogin = true, _obscureSignup = true, _loading = false;
  bool _googleProviderReady = false;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareGoogleProvider());
  }

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPass.dispose();
    _signupName.dispose();
    _signupEmail.dispose();
    _signupPass.dispose();
    super.dispose();
  }

  void _toast(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
      ),
    );
  }

  Future<void> _prepareGoogleProvider() async {
    try {
      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb ? DefaultFirebaseOptions.webGoogleClientId : null,
      );
      if (mounted) {
        setState(() => _googleProviderReady = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _googleProviderReady = false);
      }
    }
  }

  Future<bool> _ensureFirebaseReady() async {
    if (Firebase.apps.isNotEmpty) return true;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    } catch (_) {
      _toast('Firebase is not initialized. Please restart the app.');
      return false;
    }
  }

  Future<GoogleSignInAccount?> _trySignInSilentlyCompat() async {
    final google = GoogleSignIn.instance;
    // Compatibility shim: older API used signInSilently().
    try {
      final dynamic legacy = google;
      final dynamic result = await legacy.signInSilently();
      if (result is GoogleSignInAccount) return result;
    } catch (_) {
      // Ignore and use the current API below.
    }
    final lightweight = google.attemptLightweightAuthentication();
    if (lightweight == null) return null;
    return await lightweight;
  }

  Future<bool> _syncUserProfileAfterAuth(
    fa.User user, {
    String? fallbackDisplayName,
    String? fallbackEmail,
  }) async {
    final email = (user.email ?? fallbackEmail ?? '').trim();
    bool showIntro = true;
    widget.appState.user.loginFromFirebaseUser(
      user,
      fallbackDisplayName: (fallbackDisplayName ?? '').trim().isNotEmpty
          ? fallbackDisplayName!.trim()
          : (email.contains('@') ? email.split('@').first : email),
    );

    try {
      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final profile = profileDoc.data();
      showIntro = !((profile?['introCompleted'] as bool?) ?? false);
      final displayName = (profile?['displayName'] as String?)?.trim();
      final phone = (profile?['phoneNumber'] as String?)?.trim();
      final photoUrl = (profile?['photoUrl'] as String?)?.trim();
      final avatarPresetId = (profile?['avatarPresetId'] as String?)?.trim();
      if (displayName != null && displayName.isNotEmpty) {
        widget.appState.user.updateName(displayName);
      }
      if (phone != null && phone.isNotEmpty) {
        widget.appState.user.updatePhone(phone);
      }
      widget.appState.user.updateAvatar(
        photoUrl: (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl : null,
        avatarPresetId: (avatarPresetId != null && avatarPresetId.isNotEmpty)
            ? avatarPresetId
            : null,
      );
    } catch (_) {}

    final resolvedName = widget.appState.user.displayName.trim().isNotEmpty
        ? widget.appState.user.displayName.trim()
        : ((fallbackDisplayName ?? '').trim().isNotEmpty
              ? fallbackDisplayName!.trim()
              : (email.contains('@')
                    ? email.split('@').first
                    : 'TaskMate User'));
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': email,
      'displayName': resolvedName,
      'phoneNumber': widget.appState.user.phoneNumber,
      'photoUrl': widget.appState.user.photoUrl,
      'avatarPresetId': widget.appState.user.avatarPresetId,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'introCompleted': !showIntro ? true : false,
    }, SetOptions(merge: true));
    return showIntro;
  }

  Future<void> _doGoogleSignIn() async {
    if (_loading) return;
    if (!await _ensureFirebaseReady()) return;
    setState(() => _loading = true);
    try {
      final auth = fa.FirebaseAuth.instance;
      fa.UserCredential credential;
      if (kIsWeb) {
        if (!_googleProviderReady) {
          await _prepareGoogleProvider();
        }
        if (!_googleProviderReady) {
          _toast('Google Sign-In provider is not ready yet.');
          return;
        }
        final silentAccount = await _trySignInSilentlyCompat();
        if (silentAccount != null) {
          final silentAuth = silentAccount.authentication;
          final silentCred = fa.GoogleAuthProvider.credential(
            idToken: silentAuth.idToken,
          );
          credential = await auth.signInWithCredential(silentCred);
        } else {
          // Web-compatible fallback flow.
          final provider = fa.GoogleAuthProvider();
          provider.setCustomParameters({'prompt': 'select_account'});
          credential = await auth.signInWithPopup(provider);
        }
      } else {
        final google = GoogleSignIn.instance;
        if (!_googleProviderReady) {
          await _prepareGoogleProvider();
        }
        if (!_googleProviderReady) {
          _toast('Google Sign-In provider is not ready yet.');
          return;
        }
        final account = await google.authenticate();
        final googleAuth = account.authentication;
        final cred = fa.GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        credential = await auth.signInWithCredential(cred);
      }
      final user = credential.user;
      if (user == null) {
        _toast('Google sign in failed. Please try again.');
        return;
      }
      final showIntro = await _syncUserProfileAfterAuth(
        user,
        fallbackDisplayName: user.displayName,
        fallbackEmail: user.email,
      );
      if (!mounted) return;
      _goHome(showIntro: showIntro);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _toast('Google sign in canceled.', isError: false);
      } else {
        _toast('Google sign in failed. Please try again.');
      }
    } on fa.FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Google sign in failed. Please try again.');
    } catch (_) {
      _toast('Google sign in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      _toast('Enter a valid email address.', isError: true);
      return;
    }
    try {
      final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
      final endpoint = Uri.parse(
        'https://us-central1-$projectId.cloudfunctions.net/requestPasswordReset',
      );
      final response = await http
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _toast(
          'If an account exists for $email, a reset email was sent.',
          isError: false,
        );
        return;
      }
    } catch (_) {
      // Fallback to Firebase's default reset flow if function is unavailable.
    }

    final actionCodeSettings = fa.ActionCodeSettings(
      url: 'https://taskmate-chat-test.firebaseapp.com/reset-password',
      handleCodeInApp: false,
      iOSBundleId: 'com.saiman.taskmate.capstoneProject',
      androidPackageName: 'com.saiman.taskmate.capstone_project',
      androidInstallApp: true,
    );
    await fa.FirebaseAuth.instance.sendPasswordResetEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
    _toast(
      'Password reset link sent to $email. Check your inbox.',
      isError: false,
    );
  }

  void _openForgotPassword() {
    final ctrl = TextEditingController(text: _loginEmail.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'you@example.com',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final email = ctrl.text.trim();
              Navigator.pop(ctx);
              try {
                await _sendPasswordReset(email);
              } on fa.FirebaseAuthException catch (e) {
                final msg = switch (e.code) {
                  'invalid-email' => 'Invalid email address.',
                  _ => e.message ?? 'Could not send reset email.',
                };
                _toast(msg);
              } catch (_) {
                _toast('Could not send reset email. Please try again.');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary500),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
  }

  void _doLogin() async {
    final email = _loginEmail.text.trim();
    final pass = _loginPass.text;
    if (email.isEmpty || pass.isEmpty) {
      _toast('Email and password are required.');
      return;
    }

    setState(() => _loading = true);
    try {
      final cred = await fa.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
      final user = cred.user;
      if (user == null) {
        _toast('Login failed. Please try again.');
        return;
      }

      final showIntro = await _syncUserProfileAfterAuth(
        user,
        fallbackDisplayName: email.contains('@')
            ? email.split('@').first
            : email,
        fallbackEmail: email,
      );

      if (!mounted) return;
      setState(() => _loading = false);
      _goHome(showIntro: showIntro);
    } on fa.FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = switch (e.code) {
        'invalid-email' => 'Invalid email address.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' => 'No account found for this email.',
        'wrong-password' => 'Incorrect password.',
        'invalid-credential' => 'Incorrect email or password.',
        _ => e.message ?? 'Login failed. Please try again.',
      };
      _toast(msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast('Login failed. Please try again.');
    }
  }

  void _doSignup() async {
    final name = _signupName.text.trim();
    final email = _signupEmail.text.trim();
    final pass = _signupPass.text;
    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      _toast('Name, email and password are required.');
      return;
    }
    if (pass.length < 6) {
      _toast('Password must be at least 6 characters.');
      return;
    }

    setState(() => _loading = true);
    try {
      final cred = await fa.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);
      final user = cred.user;
      if (user == null) {
        _toast('Sign up failed. Please try again.');
        return;
      }

      await user.updateDisplayName(name);
      await user.reload();
      final refreshed = fa.FirebaseAuth.instance.currentUser;
      if (refreshed != null) {
        widget.appState.user.loginFromFirebaseUser(
          refreshed,
          fallbackDisplayName: name,
        );
      } else {
        widget.appState.user.login(email, name, userId: user.uid);
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'displayName': name,
        'phoneNumber': widget.appState.user.phoneNumber,
        'photoUrl': widget.appState.user.photoUrl,
        'avatarPresetId': widget.appState.user.avatarPresetId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'introCompleted': false,
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _loading = false);
      _goHome(showIntro: true);
    } on fa.FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = switch (e.code) {
        'email-already-in-use' => 'An account already exists for this email.',
        'invalid-email' => 'Invalid email address.',
        'operation-not-allowed' =>
          'Email/password sign-in is not enabled in Firebase.',
        'weak-password' => 'Password is too weak.',
        _ => e.message ?? 'Sign up failed. Please try again.',
      };
      _toast(msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast('Sign up failed. Please try again.');
    }
  }

  void _goHome({required bool showIntro}) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            MainNav(appState: widget.appState, showIntroOnLaunch: showIntro),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _openProviderSheet({required bool defaultSignup}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2026),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              _providerTile(
                icon: Icons.mail_outline_rounded,
                label: defaultSignup
                    ? 'Sign up with Email'
                    : 'Log in with Email',
                onTap: () {
                  Navigator.pop(context);
                  _openEmailAuthSheet(defaultSignup: defaultSignup);
                },
              ),
              const SizedBox(height: 10),
              _providerTile(
                icon: Icons.g_mobiledata_rounded,
                label: 'Continue with Google',
                onTap: () {
                  Navigator.pop(context);
                  _doGoogleSignIn();
                },
              ),
              const SizedBox(height: 10),
              _providerTile(
                icon: Icons.window_rounded,
                label: 'Continue with Microsoft',
                onTap: () => _toast('Microsoft sign-in is not configured yet.'),
              ),
              const SizedBox(height: 10),
              _providerTile(
                icon: Icons.apple_rounded,
                label: 'Continue with Apple',
                onTap: () => _toast('Apple sign-in is not configured yet.'),
              ),
              const SizedBox(height: 10),
              _providerTile(
                icon: Icons.tag_faces_rounded,
                label: 'Continue with Slack',
                onTap: () => _toast('Slack sign-in is not configured yet.'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEmailAuthSheet({required bool defaultSignup}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseFill = isDark ? const Color(0xFF2A2C35) : AppTheme.gray100;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1F2026) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DefaultTabController(
        length: 2,
        initialIndex: defaultSignup ? 1 : 0,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 10,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                TabBar(
                  dividerColor: Colors.transparent,
                  indicatorColor: AppTheme.primary500,
                  labelColor: isDark ? Colors.white : AppTheme.gray900,
                  unselectedLabelColor: AppTheme.gray400,
                  tabs: const [
                    Tab(text: 'Log in'),
                    Tab(text: 'Sign up'),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 324,
                  child: TabBarView(
                    children: [
                      Column(
                        children: [
                          _field(
                            _loginEmail,
                            'Email',
                            Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            filledColor: baseFill,
                            dark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            _loginPass,
                            'Password',
                            Icons.lock_rounded,
                            obscure: _obscureLogin,
                            toggleObscure: () =>
                                setState(() => _obscureLogin = !_obscureLogin),
                            filledColor: baseFill,
                            dark: isDark,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading ? null : _openForgotPassword,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 4),
                          _submitBtn('Log in', _doLogin),
                        ],
                      ),
                      Column(
                        children: [
                          _field(
                            _signupName,
                            'Full name',
                            Icons.person_outline_rounded,
                            filledColor: baseFill,
                            dark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            _signupEmail,
                            'Email',
                            Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            filledColor: baseFill,
                            dark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            _signupPass,
                            'Password',
                            Icons.lock_rounded,
                            obscure: _obscureSignup,
                            toggleObscure: () => setState(
                              () => _obscureSignup = !_obscureSignup,
                            ),
                            filledColor: baseFill,
                            dark: isDark,
                          ),
                          const SizedBox(height: 20),
                          _submitBtn('Create account', _doSignup),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _providerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return _TapSurface(
      onTap: _loading ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2C35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const baseFill = AppTheme.gray50;
    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 48),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primary500,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'TaskMate',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stay organised. Stay ahead.',
                  style: TextStyle(color: AppTheme.gray600, fontSize: 14),
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.gray100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppTheme.primary600,
                    unselectedLabelColor: AppTheme.gray600,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'Login'),
                      Tab(text: 'Sign Up'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 350,
                  child: TabBarView(
                    children: [
                      Column(
                        children: [
                          _field(
                            _loginEmail,
                            'Email',
                            Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            filledColor: baseFill,
                            dark: false,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            _loginPass,
                            'Password',
                            Icons.lock_rounded,
                            obscure: _obscureLogin,
                            toggleObscure: () =>
                                setState(() => _obscureLogin = !_obscureLogin),
                            filledColor: baseFill,
                            dark: false,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading ? null : _openForgotPassword,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _submitBtn('Login', _doLogin),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                Text(
                                  'By logging in, you agree to the ',
                                  style: TextStyle(
                                    color: AppTheme.gray600,
                                    fontSize: 12,
                                  ),
                                ),
                                InkWell(
                                  onTap: _openUserNotice,
                                  child: const Text(
                                    'User Notice',
                                    style: TextStyle(
                                      color: AppTheme.primary600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                Text(
                                  ' and ',
                                  style: TextStyle(
                                    color: AppTheme.gray600,
                                    fontSize: 12,
                                  ),
                                ),
                                InkWell(
                                  onTap: _openPrivacyPolicy,
                                  child: const Text(
                                    'Privacy Policy',
                                    style: TextStyle(
                                      color: AppTheme.primary600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                Text(
                                  '.',
                                  style: TextStyle(
                                    color: AppTheme.gray600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          _field(
                            _signupName,
                            'Full Name',
                            Icons.person,
                            filledColor: baseFill,
                            dark: false,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            _signupEmail,
                            'Email',
                            Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            filledColor: baseFill,
                            dark: false,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            _signupPass,
                            'Password',
                            Icons.lock_rounded,
                            obscure: _obscureSignup,
                            toggleObscure: () => setState(
                              () => _obscureSignup = !_obscureSignup,
                            ),
                            filledColor: baseFill,
                            dark: false,
                          ),
                          const SizedBox(height: 20),
                          _submitBtn('Create Account', _doSignup),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.gray200)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or continue with',
                        style: TextStyle(color: AppTheme.gray400, fontSize: 13),
                      ),
                    ),
                    Expanded(child: Divider(color: AppTheme.gray200)),
                  ],
                ),
                const SizedBox(height: 16),
                _googleButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextInputType? keyboardType,
    required Color filledColor,
    required bool dark,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: dark ? Colors.white70 : AppTheme.primary500,
        ),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: dark ? Colors.white70 : AppTheme.gray600,
                ),
                onPressed: toggleObscure,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dark ? Colors.white12 : AppTheme.gray200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primary500, width: 2),
        ),
        filled: true,
        fillColor: filledColor,
        isDense: true,
      ),
      style: TextStyle(color: dark ? Colors.white : AppTheme.gray900),
    );
  }

  Widget _submitBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _loading ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primary500,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _openUserNotice() async {
    await _showLegalDialog(
      title: 'User Notice',
      body:
          'TaskMate helps you organise tasks, chats, and schedules. Continue using the app only for lawful and respectful collaboration.',
    );
  }

  Future<void> _openPrivacyPolicy() async {
    await _showLegalDialog(
      title: 'Privacy Policy',
      body:
          'TaskMate stores your account details and workspace content to provide core features. Your data is handled securely and only used to operate the service.',
    );
  }

  Future<void> _showLegalDialog({
    required String title,
    required String body,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body, style: const TextStyle(height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _googleButton() {
    final canUseGoogle = !_loading && (kIsWeb || _googleProviderReady);
    return SizedBox(
      width: double.infinity,
      child: _TapSurface(
        onTap: canUseGoogle ? _doGoogleSignIn : null,
        borderRadius: BorderRadius.circular(14),
        haptic: true,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.gray200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const _GoogleGlyph(size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Continue with Google',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.gray900,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              if (_loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.gray700,
                  ),
                )
              else
                const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  final double size;
  const _GoogleGlyph({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 6,
      height: size + 6,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => const SweepGradient(
          startAngle: 0.2,
          endAngle: 6.0,
          colors: [
            Color(0xFF4285F4),
            Color(0xFF34A853),
            Color(0xFFFBBC05),
            Color(0xFFEA4335),
            Color(0xFF4285F4),
          ],
        ).createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: Text(
          'G',
          style: TextStyle(
            fontSize: size * 0.92,
            fontWeight: FontWeight.w800,
            height: 1,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class IntroCarouselScreen extends StatefulWidget {
  final AppState appState;
  const IntroCarouselScreen({super.key, required this.appState});

  @override
  State<IntroCarouselScreen> createState() => _IntroCarouselScreenState();
}

class _IntroCarouselScreenState extends State<IntroCarouselScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _slides =
      <({Color bg, IconData icon, String title, String subtitle})>[
        (
          bg: Color(0xFF57D9A3),
          icon: Icons.pets_rounded,
          title: 'Celebrate progress',
          subtitle: 'Check off tasks and watch your wins stack up.',
        ),
        (
          bg: Color(0xFF72A9FF),
          icon: Icons.camera_alt_outlined,
          title: 'Capture to-dos instantly',
          subtitle: 'Add cards in seconds, from anywhere, with your team.',
        ),
        (
          bg: Color(0xFF6C7AFF),
          icon: Icons.draw_rounded,
          title: 'Plan with whiteboards',
          subtitle: 'Create shared whiteboards for each workspace discussion.',
        ),
      ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= _slides.length - 1) {
      Navigator.pop(context);
      return;
    }
    _ctrl.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    return Scaffold(
      backgroundColor: slide.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _ctrl,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) {
                    final s = _slides[i];
                    return Column(
                      children: [
                        const SizedBox(height: 70),
                        Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(s.icon, size: 120, color: Colors.white),
                        ),
                        const SizedBox(height: 44),
                        Text(
                          s.title,
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.gray900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            s.subtitle,
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppTheme.gray900,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2026),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _page == _slides.length - 1 ? 'Get started' : 'Next',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF57D9A3),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Skip introduction',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.gray900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WELCOME GROUP POPUP
// ═══════════════════════════════════════════════════════════════════════════
class WelcomeGroupDialog extends StatelessWidget {
  final AppState appState;
  const WelcomeGroupDialog({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primary50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group_work_rounded,
                color: AppTheme.primary600,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome to TaskMate!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a workspace and invite your team, or join an existing one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.gray600, fontSize: 14),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => CreateGroupDialog(appState: appState),
                  barrierDismissible: false,
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Create a Workspace'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary500,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => JoinGroupDialog(appState: appState),
                  barrierDismissible: false,
                );
              },
              icon: const Icon(
                Icons.group_add_outlined,
                color: AppTheme.primary600,
              ),
              label: const Text(
                'Join a Workspace',
                style: TextStyle(color: AppTheme.primary600),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: const BorderSide(color: AppTheme.primary500),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Skip for now',
                style: TextStyle(color: AppTheme.gray400, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTACT PICKER BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════
class ContactPickerSheet extends StatefulWidget {
  final List<PhoneContact> initialSelectedContacts;
  const ContactPickerSheet({
    super.key,
    this.initialSelectedContacts = const [],
  });
  @override
  State<ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<ContactPickerSheet> {
  late final Set<String> _selectedPhones;
  final DeviceContactsService _deviceContactsService = DeviceContactsService();
  List<PhoneContact> _phoneContacts = List<PhoneContact>.from(
    kMockPhoneContacts,
  );
  bool _loadingContacts = false;
  String? _contactsError;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedPhones = widget.initialSelectedContacts
        .map((c) => c.phone.trim())
        .where((p) => p.isNotEmpty)
        .toSet();
    _loadDeviceContacts();
  }

  Future<void> _loadDeviceContacts() async {
    if (!mounted) return;
    setState(() {
      _loadingContacts = true;
      _contactsError = null;
    });
    try {
      final contacts = await _deviceContactsService.loadPhoneContacts();
      if (!mounted) return;
      setState(() {
        if (contacts.isNotEmpty) {
          _phoneContacts = contacts
              .map((c) => PhoneContact(name: c.name, phone: c.phone))
              .toList(growable: false);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _contactsError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingContacts = false;
      });
    }
  }

  Map<String, dynamic> _pickerResult({String? manual}) => {
    'selectedContacts': _phoneContacts
        .where((c) => _selectedPhones.contains(c.phone.trim()))
        .map((c) => c.toMap())
        .toList(growable: false),
    'manual': manual,
  };

  List<MapEntry<int, PhoneContact>> get _filtered {
    final all = _phoneContacts.asMap().entries.toList();
    if (_query.isEmpty) return all;
    return all
        .where(
          (e) =>
              e.value.name.toLowerCase().contains(_query) ||
              e.value.phone.contains(_query),
        )
        .toList();
  }

  Future<void> _openManualEntryDialog() async {
    final manualCtrl = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Phone or Email'),
        content: TextField(
          controller: manualCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Enter phone (+977...) or email',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, manualCtrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (value == null || value.isEmpty || !mounted) return;

    final isEmail = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    ).hasMatch(value.toLowerCase());
    final phoneDigits = value.replaceAll(RegExp(r'[^0-9+]'), '');
    final isPhoneLike =
        phoneDigits.replaceFirst('+', '').length >= 7 && !value.contains('@');
    if (!isEmail && !isPhoneLike) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid phone number or email address.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.pop(context, _pickerResult(manual: value));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.gray200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Add Members',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_selectedPhones.isNotEmpty)
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, _pickerResult(manual: null)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary500,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Done (${_selectedPhones.length})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search contacts...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.gray600,
                      ),
                      filled: true,
                      fillColor: AppTheme.gray100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.gray100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed: _openManualEntryDialog,
                    tooltip: 'Add phone or email',
                    icon: const Icon(Icons.dialpad, color: AppTheme.primary500),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_loadingContacts)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          if (!_loadingContacts &&
              _contactsError != null &&
              _contactsError!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Using saved contacts. Phone sync is unavailable right now.',
                style: TextStyle(color: AppTheme.warning, fontSize: 12),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final entry = _filtered[i];
                final idx = entry.key;
                final contact = entry.value;
                final isSelected = _selectedPhones.contains(
                  contact.phone.trim(),
                );
                final avatarColor =
                    Colors.primaries[idx % Colors.primaries.length];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: avatarColor,
                    child: Text(
                      contact.name[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    contact.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    contact.phone,
                    style: TextStyle(color: AppTheme.gray600, fontSize: 12),
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    activeColor: AppTheme.primary500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (v) => setState(
                      () => v!
                          ? _selectedPhones.add(contact.phone.trim())
                          : _selectedPhones.remove(contact.phone.trim()),
                    ),
                  ),
                  onTap: () => setState(
                    () => isSelected
                        ? _selectedPhones.remove(contact.phone.trim())
                        : _selectedPhones.add(contact.phone.trim()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CREATE GROUP DIALOG — with phone picker + deadline
// ═══════════════════════════════════════════════════════════════════════════
class CreateGroupDialog extends StatefulWidget {
  final AppState appState;
  const CreateGroupDialog({super.key, required this.appState});
  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<PhoneContact> _selectedContacts = [];
  final List<String> _manualNumbers = [];
  DateTime? _deadline;
  bool _loading = false;

  Future<void> _openContactPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          ContactPickerSheet(initialSelectedContacts: _selectedContacts),
    );
    if (result != null) {
      setState(() {
        _selectedContacts.clear();
        _selectedContacts.addAll(
          ((result['selectedContacts'] as List<dynamic>? ?? [])).map(
            (e) => PhoneContact.fromMap(e as Map<dynamic, dynamic>),
          ),
        );
        if (result['manual'] != null &&
            (result['manual'] as String).isNotEmpty) {
          _manualNumbers.add(result['manual'] as String);
        }
      });
    }
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
    );
    if (time == null) return;
    setState(
      () => _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  String _formatDeadline(DateTime d) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _createGroup() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    if (_selectedContacts.isEmpty && _manualNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one member'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final members = <GroupMember>[];
    for (final c in _selectedContacts) {
      members.add(GroupMember(name: c.name, phone: c.phone, isAppUser: false));
    }
    for (final num in _manualNumbers) {
      members.add(GroupMember(name: num, phone: num, isAppUser: false));
    }

    final group = widget.appState.createGroup(
      _nameCtrl.text.trim(),
      members,
      deadline: _deadline,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      creatorUid: widget.appState.user.uid.isNotEmpty
          ? widget.appState.user.uid
          : null,
    );
    InviteDispatchSummary inviteSummary = const InviteDispatchSummary();
    try {
      await widget.appState.persistGroupToFirestore(group);
      inviteSummary = await widget.appState.sendWorkspaceInvites(group);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not sync workspace to the cloud. Check your connection and Firestore rules.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (_) => GroupCreatedSuccessDialog(
        group: group,
        appState: widget.appState,
        inviteSummary: inviteSummary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSelected = _selectedContacts.length + _manualNumbers.length;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Create Workspace',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Name
                  const _FieldLabel('Workspace Name'),
                  TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. INF305 Project Team',
                      prefixIcon: const Icon(
                        Icons.group,
                        color: AppTheme.primary500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.gray200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.gray200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primary500,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppTheme.gray50,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Description
                  const _FieldLabel('Description (optional)'),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'What is this workspace for?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.gray200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.gray200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primary500,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppTheme.gray50,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Deadline
                  const _FieldLabel('Deadline'),
                  _TapSurface(
                    onTap: _pickDeadline,
                    haptic: true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _deadline != null
                            ? AppTheme.primary500.withValues(alpha: 0.06)
                            : AppTheme.gray50,
                        border: Border.all(
                          color: _deadline != null
                              ? AppTheme.primary500.withValues(alpha: 0.3)
                              : AppTheme.gray200,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event,
                            color: _deadline != null
                                ? AppTheme.primary500
                                : AppTheme.gray600,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _deadline == null
                                ? 'Set deadline date & time'
                                : _formatDeadline(_deadline!),
                            style: TextStyle(
                              color: _deadline != null
                                  ? AppTheme.primary500
                                  : AppTheme.gray600,
                              fontSize: 14,
                              fontWeight: _deadline != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          if (_deadline != null)
                            IconButton(
                              onPressed: () {
                                _hapticLight();
                                setState(() => _deadline = null);
                              },
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: AppTheme.gray600,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              splashRadius: 18,
                              tooltip: 'Clear deadline',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Members
                  Row(
                    children: [
                      const _FieldLabel('Members'),
                      const Spacer(),
                      if (totalSelected > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary500,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$totalSelected selected',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _TapSurface(
                    onTap: _openContactPicker,
                    haptic: true,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.gray50,
                        border: Border.all(color: AppTheme.gray200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primary500.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.contacts,
                              color: AppTheme.primary500,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Choose from Contacts',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  totalSelected == 0
                                      ? 'Tap to add members'
                                      : '$totalSelected member${totalSelected != 1 ? 's' : ''} will receive an invite',
                                  style: TextStyle(
                                    color: AppTheme.gray600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppTheme.gray600,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Selected members chips
                  if (totalSelected > 0) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ..._selectedContacts.map((c) {
                          return Chip(
                            label: Text(
                              c.name.split(' ')[0],
                              style: const TextStyle(fontSize: 12),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => setState(() {
                              _selectedContacts.removeWhere(
                                (entry) =>
                                    entry.name == c.name &&
                                    entry.phone == c.phone,
                              );
                            }),
                            backgroundColor: AppTheme.primary500.withValues(
                              alpha: 0.08,
                            ),
                            side: BorderSide(
                              color: AppTheme.primary500.withValues(alpha: 0.2),
                            ),
                          );
                        }),
                        ..._manualNumbers.map(
                          (phone) => Chip(
                            label: Text(
                              phone,
                              style: const TextStyle(fontSize: 11),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () =>
                                setState(() => _manualNumbers.remove(phone)),
                            backgroundColor: AppTheme.success.withValues(
                              alpha: 0.08,
                            ),
                            side: BorderSide(
                              color: AppTheme.success.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Invite notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.info.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.campaign_outlined,
                          color: AppTheme.info,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'TaskMate users get in-app invites, emails are sent to email addresses, and phone numbers can be invited from your SMS app.',
                            style: TextStyle(
                              color: AppTheme.info,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _createGroup,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary500,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Create Workspace & Send Invites',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GROUP CREATED SUCCESS DIALOG
// ═══════════════════════════════════════════════════════════════════════════
class GroupCreatedSuccessDialog extends StatelessWidget {
  final GroupModel group;
  final AppState appState;
  final InviteDispatchSummary inviteSummary;
  const GroupCreatedSuccessDialog({
    super.key,
    required this.group,
    required this.appState,
    required this.inviteSummary,
  });

  String _formatDeadline(DateTime d) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primary500,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Workspace Created!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '"${group.name}" is ready. Invites were prepared for your members.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.gray600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            // Group Code
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.key_rounded,
                    color: AppTheme.primary500,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Workspace Code',
                        style: TextStyle(fontSize: 11, color: AppTheme.gray600),
                      ),
                      Text(
                        group.code,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary500,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: group.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Code copied!'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Text('Copy'),
                  ),
                ],
              ),
            ),
            if (group.deadline != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: AppTheme.warning, size: 18),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deadline',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.gray600,
                          ),
                        ),
                        Text(
                          _formatDeadline(group.deadline!),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.gray50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (inviteSummary.inAppInviteCount > 0)
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          color: AppTheme.success,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'In-app Invitations',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${inviteSummary.inAppInviteCount} TaskMate user${inviteSummary.inAppInviteCount != 1 ? 's' : ''} notified',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  if (inviteSummary.emailInviteCount > 0)
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.email_outlined,
                          color: AppTheme.info,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Email Invitations',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${inviteSummary.emailInviteCount} email invite${inviteSummary.emailInviteCount != 1 ? 's' : ''} sent',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  if (inviteSummary.manualSmsCount > 0)
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.sms_outlined,
                          color: AppTheme.warning,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Manual SMS Needed',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${inviteSummary.manualSmsCount} contact${inviteSummary.manualSmsCount != 1 ? 's' : ''} can be invited from your SMS app',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
            if (inviteSummary.manualSmsCount > 0) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => appState.openManualSmsComposer(
                  group: group,
                  phoneNumber: inviteSummary.manualSmsCount == 1
                      ? inviteSummary.manualSmsRecipients.first
                      : null,
                ),
                icon: const Icon(Icons.sms_outlined),
                label: const Text('Open SMS Composer'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary500,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// JOIN GROUP DIALOG
// ═══════════════════════════════════════════════════════════════════════════
class JoinGroupDialog extends StatefulWidget {
  final AppState appState;
  const JoinGroupDialog({super.key, required this.appState});
  @override
  State<JoinGroupDialog> createState() => _JoinGroupDialogState();
}

class _JoinGroupDialogState extends State<JoinGroupDialog> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  void _joinByCode() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final success = await widget.appState.joinGroupByCode(
      _codeCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully joined workspace!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(
        () => _error = 'Invalid workspace code. Please check and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) =>
                          WelcomeGroupDialog(appState: widget.appState),
                    );
                  },
                ),
                const Text(
                  'Join a Workspace',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.info.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.info.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.link, color: AppTheme.info, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Join via Invite Link',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Open your inbox/messages to find your invite link, or use the workspace code below.',
                    style: TextStyle(color: AppTheme.gray600, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri(scheme: 'sms')),
                    icon: const Icon(
                      Icons.sms_outlined,
                      color: AppTheme.info,
                      size: 20,
                    ),
                    label: const Text(
                      'Open SMS App',
                      style: TextStyle(color: AppTheme.info),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.info),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Divider(color: AppTheme.gray200)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or enter code',
                    style: TextStyle(color: AppTheme.gray400, fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: AppTheme.gray200)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Workspace Code',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.gray600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
              maxLength: 6,
              decoration: InputDecoration(
                counterText: '',
                hintText: 'ABC123',
                hintStyle: TextStyle(color: AppTheme.gray200, letterSpacing: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppTheme.primary500,
                    width: 2,
                  ),
                ),
                errorText: _error,
                filled: true,
                fillColor: AppTheme.gray50,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _joinByCode,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary500,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Join Workspace',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
              child: Text(
                'Skip for now',
                style: TextStyle(color: AppTheme.gray400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GROUP INFO SCREEN  (WhatsApp-style)
// ═══════════════════════════════════════════════════════════════════════════
class GroupInfoScreen extends StatefulWidget {
  final GroupModel group;
  final AppState appState;
  const GroupInfoScreen({
    super.key,
    required this.group,
    required this.appState,
  });
  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  GroupModel get group => widget.group;
  String get _myUid => widget.appState.user.uid.trim();
  bool get _isCurrentUserAdmin =>
      widget.appState.isGroupAdmin(group.id, _myUid);

  Future<void> _pickGroupPhoto() async {
    if (!_isCurrentUserAdmin) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) return;
      final currentUser = fa.FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      final ext = picked.name.contains('.')
          ? picked.name.split('.').last.toLowerCase()
          : 'jpg';
      final contentType =
          lookupMimeType(picked.name, headerBytes: bytes) ?? 'image/jpeg';
      final path =
          'uploads/${currentUser.uid}/group_avatars/${group.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = FirebaseStorage.instance.ref(path);
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      final url = await ref.getDownloadURL();
      setState(() => group.photoUrl = url);
      await widget.appState.syncGroupToFirestore(group);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update workspace photo: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openChatThemePicker() {
    final presets = <Color>[
      AppTheme.primary500,
      AppTheme.info,
      Colors.deepPurple,
      Colors.teal,
      AppTheme.success,
      AppTheme.warning,
      Colors.pink,
    ];
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chat theme',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: presets
                      .map(
                        (c) => _TapSurface(
                          onTap: () {
                            widget.appState.setChatAccentColor(c);
                            Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(999),
                          haptic: true,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDeadline(DateTime d) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _editGroupName() {
    if (!_isCurrentUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only admins can edit workspace details.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final ctrl = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Edit Workspace Name',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Workspace name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary500),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => group.name = ctrl.text.trim());
                widget.appState.updateGroupName(group.id, ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addMembers() async {
    if (!_isCurrentUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only admins can add members.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ContactPickerSheet(initialSelectedContacts: []),
    );
    if (result == null) return;

    if (!mounted) return;
    final newlyAddedMembers = <GroupMember>[];
    setState(() {
      final selectedContacts =
          (result['selectedContacts'] as List<dynamic>? ?? [])
              .map((e) => PhoneContact.fromMap(e as Map<dynamic, dynamic>))
              .toList();
      for (final c in selectedContacts) {
        if (!group.members.any((m) => m.phone == c.phone)) {
          final member = GroupMember(
            name: c.name,
            phone: c.phone,
            isAppUser: false,
          );
          group.members.add(member);
          newlyAddedMembers.add(member);
        }
      }
      if (result['manual'] != null && (result['manual'] as String).isNotEmpty) {
        final manual = result['manual'] as String;
        final manualMember = GroupMember(
          name: manual,
          phone: manual,
          isAppUser: false,
        );
        group.members.add(manualMember);
        newlyAddedMembers.add(manualMember);
      }
    });
    widget.appState.refresh();
    await widget.appState.syncGroupToFirestore(group);
    final summary = await widget.appState.sendWorkspaceInvites(
      group,
      recipients: newlyAddedMembers,
    );
    if (!mounted) return;
    if (summary.manualSmsCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${summary.manualSmsCount} phone invite${summary.manualSmsCount != 1 ? 's' : ''} pending. Use SMS composer to send manually.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _removeMember(GroupMember member) async {
    if (!_isCurrentUserAdmin) return;
    final targetLabel = member.name.trim().isNotEmpty
        ? member.name
        : member.phone;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member'),
        content: Text('Remove $targetLabel from this workspace?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await widget.appState.removeMemberFromGroup(
      groupId: group.id,
      member: member,
      actingUid: _myUid,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Member removed' : 'Could not remove member'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleExitWorkspace() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit workspace'),
        content: const Text(
          'You will lose access to this workspace until someone invites you again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await widget.appState.leaveGroup(
      groupId: group.id,
      userUid: _myUid,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You exited the workspace.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Admins should delete the workspace instead of exiting.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleDeleteWorkspace() async {
    if (!_isCurrentUserAdmin) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete workspace'),
        content: const Text(
          'This permanently deletes the workspace for all members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await widget.appState.deleteGroupIfAdmin(
      groupId: group.id,
      actingUid: _myUid,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workspace deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _sectionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
      leading: Icon(
        icon,
        color: isDark ? Colors.white70 : Colors.black87,
        size: 22,
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: AppTheme.gray600, fontSize: 12),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '',
                      style: TextStyle(color: AppTheme.gray400, fontSize: 13),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.gray600,
                      size: 18,
                    ),
                  ],
                )
              : null),
    );
  }

  Widget _sectionTileWithValue({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap ?? () {},
      leading: Icon(
        icon,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white70
            : Colors.black87,
        size: 22,
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: AppTheme.gray400, fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppTheme.gray600, size: 18),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final allMembers = [
      GroupMember(
        name: widget.appState.user.displayName.isEmpty
            ? 'You'
            : widget.appState.user.displayName,
        phone: 'You',
        isAdmin: _isCurrentUserAdmin,
        isAppUser: true,
        userId: widget.appState.user.uid.isNotEmpty
            ? widget.appState.user.uid
            : null,
      ),
      ...group.members,
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text(
              'Workspace info',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Group header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'group_${group.id}',
                        child: _TapSurface(
                          onTap: _pickGroupPhoto,
                          borderRadius: BorderRadius.circular(999),
                          haptic: true,
                          child: Stack(
                            children: [
                              _GroupAvatar(group: group, radius: 40),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primary500,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _TapSurface(
                        onTap: _editGroupName,
                        borderRadius: BorderRadius.circular(10),
                        haptic: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                group.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.edit,
                                size: 16,
                                color: AppTheme.gray600,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: AppTheme.gray600,
                            fontSize: 14,
                          ),
                          children: [
                            const TextSpan(text: 'Workspace · '),
                            TextSpan(
                              text: '${group.memberCount} members',
                              style: const TextStyle(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (group.deadline != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: AppTheme.warning,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Deadline: ${_formatDeadline(group.deadline!)}',
                                style: const TextStyle(
                                  color: AppTheme.warning,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // ── Quick actions ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _quickAction(
                        Icons.person_add_outlined,
                        'Add',
                        _isCurrentUserAdmin ? _addMembers : () {},
                      ),
                      const SizedBox(width: 12),
                      _quickAction(Icons.search, 'Search', () {}),
                      const SizedBox(width: 12),
                      _quickAction(
                        Icons.photo_library_rounded,
                        'Media',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupFolderScreen(
                              appState: widget.appState,
                              group: group,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _quickAction(Icons.notifications_rounded, 'Mute', () {}),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // ── Description ───────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  color: bgCard,
                  child: ListTile(
                    onTap: () {},
                    title: Text(
                      group.description ?? 'Add workspace description',
                      style: TextStyle(
                        color: group.description != null
                            ? null
                            : AppTheme.success,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // ── Media / Storage / Starred ──────────────────────────────────
                Container(
                  color: bgCard,
                  child: Column(
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('files')
                            .where('groupId', isEqualTo: group.id)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final c = snapshot.data?.docs.length ?? 0;
                          return _sectionTileWithValue(
                            icon: Icons.photo_library_rounded,
                            title: 'Media, links and docs',
                            value: '$c',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GroupFolderScreen(
                                  appState: widget.appState,
                                  group: group,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Divider(indent: 52, height: 1, color: AppTheme.gray200),
                      _sectionTileWithValue(
                        icon: Icons.storage_outlined,
                        title: 'Manage storage',
                        value: '0 KB',
                      ),
                      Divider(indent: 52, height: 1, color: AppTheme.gray200),
                      _sectionTileWithValue(
                        icon: Icons.star,
                        title: 'Starred',
                        value: 'None',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // ── Notifications / Chat ──────────────────────────────────────
                Container(
                  color: bgCard,
                  child: Column(
                    children: [
                      _sectionTileWithValue(
                        icon: Icons.notifications_rounded,
                        title: 'Notifications',
                        value: 'All',
                      ),
                      Divider(indent: 52, height: 1, color: AppTheme.gray200),
                      _sectionTile(
                        icon: Icons.palette_outlined,
                        iconColor: Colors.purple,
                        title: 'Chat theme',
                        onTap: _openChatThemePicker,
                      ),
                      Divider(indent: 52, height: 1, color: AppTheme.gray200),
                      _sectionTileWithValue(
                        icon: Icons.save_alt_outlined,
                        title: 'Save to Photos',
                        value: 'Default',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // ── Privacy / Security ────────────────────────────────────────
                Container(
                  color: bgCard,
                  child: Column(
                    children: [
                      _sectionTileWithValue(
                        icon: Icons.timelapse_outlined,
                        title: 'Disappearing messages',
                        value: group.disappearingMessages ? 'On' : 'Off',
                      ),
                      Divider(indent: 52, height: 1, color: AppTheme.gray200),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                        leading: Icon(
                          Icons.lock_rounded,
                          color: isDark ? Colors.white70 : Colors.black87,
                          size: 22,
                        ),
                        title: const Text(
                          'Lock chat',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Lock and hide this chat on this device.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.gray600,
                          ),
                        ),
                        trailing: Switch(
                          value: group.lockChat,
                          onChanged: (v) {
                            widget.appState.updateGroupLock(group.id, v);
                            setState(() {});
                          },
                          activeThumbColor: AppTheme.success,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      Divider(indent: 52, height: 1, color: AppTheme.gray200),
                      _sectionTileWithValue(
                        icon: Icons.security_outlined,
                        title: 'Advanced chat privacy',
                        value: 'Off',
                      ),
                      Divider(indent: 52, height: 1, color: AppTheme.gray200),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                        leading: Icon(
                          Icons.lock_rounded,
                          color: isDark ? Colors.white70 : Colors.black87,
                          size: 22,
                        ),
                        title: const Text(
                          'Encryption',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Messages are end-to-end encrypted. Tap to learn more.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.gray600,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppTheme.gray600,
                          size: 18,
                        ),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // ── Members header ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${group.memberCount} members',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.search, color: AppTheme.gray600),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                // ── Members list ──────────────────────────────────────────────
                Container(
                  color: bgCard,
                  child: Column(
                    children: [
                      // Add members row
                      ListTile(
                        onTap: _isCurrentUserAdmin ? _addMembers : null,
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.gray200,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(Icons.add, color: AppTheme.gray600),
                        ),
                        title: const Text(
                          'Add members',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Invite via link
                      ListTile(
                        onTap: () {},
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.gray200,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.link,
                            color: AppTheme.gray600,
                          ),
                        ),
                        title: const Text(
                          'Invite via link or QR code',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Divider(height: 1, color: AppTheme.gray200),
                      ...allMembers.asMap().entries.map((e) {
                        final idx = e.key;
                        final member = e.value;
                        final isSelf = member.phone == 'You';
                        final canRemove =
                            _isCurrentUserAdmin &&
                            !isSelf &&
                            (member.userId ?? '').trim() !=
                                (group.creatorUid ?? '').trim();
                        final avatarColor =
                            Colors.primaries[idx % Colors.primaries.length];
                        return Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                radius: 23,
                                backgroundColor: member.isAppUser
                                    ? AppTheme.primary500
                                    : avatarColor,
                                child: Text(
                                  member.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                member.isAppUser && member.phone == 'You'
                                    ? 'You'
                                    : member.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                member.phone == 'You'
                                    ? 'Hey there! I am using TaskMate.'
                                    : member.isAppUser
                                    ? 'Using TaskMate'
                                    : 'Invited · Not yet joined',
                                style: TextStyle(
                                  color: member.isAppUser
                                      ? AppTheme.gray600
                                      : AppTheme.warning,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: member.isAdmin
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Admin',
                                          style: TextStyle(
                                            color: AppTheme.success,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.chevron_right,
                                          color: AppTheme.gray400,
                                          size: 18,
                                        ),
                                      ],
                                    )
                                  : canRemove
                                  ? const Icon(
                                      Icons.person_remove_outlined,
                                      color: AppTheme.error,
                                      size: 20,
                                    )
                                  : Icon(
                                      Icons.chevron_right,
                                      color: AppTheme.gray400,
                                      size: 18,
                                    ),
                              onTap: canRemove
                                  ? () => _removeMember(member)
                                  : null,
                            ),
                            if (idx < allMembers.length - 1)
                              Divider(
                                indent: 68,
                                height: 1,
                                color: AppTheme.gray200,
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // ── Danger zone ───────────────────────────────────────────────
                Container(
                  color: bgCard,
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        leading: const Icon(
                          Icons.favorite_outline,
                          color: AppTheme.success,
                        ),
                        title: const Text(
                          'Add to Favourites',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Divider(height: 1, color: AppTheme.gray200),
                      ListTile(
                        onTap: () {},
                        leading: const Icon(
                          Icons.format_list_bulleted,
                          color: AppTheme.success,
                        ),
                        title: const Text(
                          'Add to list',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Divider(height: 1, color: AppTheme.gray200),
                      ListTile(
                        onTap: () {},
                        leading: const Icon(
                          Icons.ios_share_outlined,
                          color: AppTheme.success,
                        ),
                        title: const Text(
                          'Export chat',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Divider(height: 1, color: AppTheme.gray200),
                      ListTile(
                        onTap: () {},
                        leading: const Icon(
                          Icons.delete_sweep_outlined,
                          color: AppTheme.error,
                        ),
                        title: const Text(
                          'Clear chat',
                          style: TextStyle(color: AppTheme.error, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  color: bgCard,
                  child: Column(
                    children: [
                      if (_isCurrentUserAdmin)
                        ListTile(
                          onTap: _handleDeleteWorkspace,
                          leading: const Icon(
                            Icons.delete_forever_outlined,
                            color: AppTheme.error,
                          ),
                          title: const Text(
                            'Delete workspace',
                            style: TextStyle(
                              color: AppTheme.error,
                              fontSize: 14,
                            ),
                          ),
                        )
                      else
                        ListTile(
                          onTap: _handleExitWorkspace,
                          leading: const Icon(
                            Icons.exit_to_app,
                            color: AppTheme.error,
                          ),
                          title: const Text(
                            'Exit workspace',
                            style: TextStyle(
                              color: AppTheme.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      Divider(height: 1, color: AppTheme.gray200),
                      ListTile(
                        onTap: () {},
                        leading: const Icon(
                          Icons.flag_outlined,
                          color: AppTheme.error,
                        ),
                        title: const Text(
                          'Report workspace',
                          style: TextStyle(color: AppTheme.error, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Created by ${widget.appState.user.displayName.isEmpty ? 'You' : widget.appState.user.displayName}.\nCreated ${_formatCreatedAt(group.createdAt)}.',
                    style: TextStyle(color: AppTheme.gray400, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCreatedAt(DateTime d) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: _TapSurface(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        haptic: true,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primary500, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PERSONAL CHAT INFO (mirrors group info layout for 1:1 chats)
// ═══════════════════════════════════════════════════════════════════════════
class PersonalChatInfoScreen extends StatefulWidget {
  final String peerUserId;
  final String displayName;
  final String? chatId;
  final AppState appState;
  const PersonalChatInfoScreen({
    super.key,
    required this.peerUserId,
    required this.displayName,
    required this.appState,
    this.chatId,
  });

  @override
  State<PersonalChatInfoScreen> createState() => _PersonalChatInfoScreenState();
}

class _PersonalChatInfoScreenState extends State<PersonalChatInfoScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text(
              'Contact info',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'dm_peer_${widget.peerUserId}',
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary500,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              widget.displayName.isNotEmpty
                                  ? widget.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Direct message · TaskMate',
                        style: TextStyle(color: AppTheme.gray600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _dmQuickAction(Icons.search, 'Search', () {}),
                      const SizedBox(width: 12),
                      _dmQuickAction(
                        Icons.notifications_rounded,
                        'Mute',
                        () {},
                      ),
                      const SizedBox(width: 12),
                      _dmQuickAction(
                        Icons.photo_library_rounded,
                        'Media',
                        () {},
                      ),
                      const SizedBox(width: 12),
                      _dmQuickAction(Icons.info_outline, 'Info', () {}),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.peerUserId)
                      .snapshots(),
                  builder: (context, snap) {
                    final data = snap.data?.data() as Map<String, dynamic>?;
                    final email = (data?['email'] as String?) ?? '';
                    final phone = (data?['phoneNumber'] as String?) ?? '';
                    return Container(
                      color: bgCard,
                      child: Column(
                        children: [
                          if (email.isNotEmpty)
                            ListTile(
                              leading: Icon(
                                Icons.email_outlined,
                                color: isDark ? Colors.white70 : Colors.black87,
                                size: 22,
                              ),
                              title: const Text(
                                'Email',
                                style: TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (email.isNotEmpty && phone.isNotEmpty)
                            Divider(
                              indent: 52,
                              height: 1,
                              color: AppTheme.gray200,
                            ),
                          if (phone.isNotEmpty)
                            ListTile(
                              leading: Icon(
                                Icons.phone_outlined,
                                color: isDark ? Colors.white70 : Colors.black87,
                                size: 22,
                              ),
                              title: const Text(
                                'Phone',
                                style: TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                phone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (email.isEmpty && phone.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'Profile details appear when this user updates their account.',
                                style: TextStyle(
                                  color: AppTheme.gray600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  color: bgCard,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.photo_library_rounded,
                          color: isDark ? Colors.white70 : Colors.black87,
                          size: 22,
                        ),
                        title: const Text(
                          'Media, links and docs',
                          style: TextStyle(fontSize: 14),
                        ),
                        trailing: StreamBuilder<QuerySnapshot>(
                          stream: widget.chatId == null
                              ? const Stream.empty()
                              : FirebaseFirestore.instance
                                    .collection('files')
                                    .where('chatId', isEqualTo: widget.chatId)
                                    .snapshots(),
                          builder: (context, snap) {
                            final c = snap.data?.docs.length ?? 0;
                            return Text(
                              '$c',
                              style: TextStyle(
                                color: AppTheme.gray400,
                                fontSize: 13,
                              ),
                            );
                          },
                        ),
                      ),
                      Divider(indent: 52, height: 1, color: AppTheme.gray200),
                      ListTile(
                        leading: Icon(
                          Icons.star,
                          color: isDark ? Colors.white70 : Colors.black87,
                          size: 22,
                        ),
                        title: const Text(
                          'Starred messages',
                          style: TextStyle(fontSize: 14),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppTheme.gray600,
                          size: 18,
                        ),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  color: bgCard,
                  child: ListTile(
                    leading: const Icon(
                      Icons.lock_rounded,
                      color: AppTheme.success,
                      size: 22,
                    ),
                    title: const Text(
                      'Encryption',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Messages are delivered securely. Personal chats stay private to participants.',
                      style: TextStyle(fontSize: 12, color: AppTheme.gray600),
                    ),
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dmQuickAction(IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: _TapSurface(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        haptic: true,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primary500, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── MAIN NAVIGATION ──────────────────────────────────────────────────────────
class MainNav extends StatefulWidget {
  final AppState appState;
  final bool showIntroOnLaunch;
  const MainNav({
    super.key,
    required this.appState,
    this.showIntroOnLaunch = false,
  });
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _idx = 0;
  bool _shownWelcome = false;
  String _boundRealtimeUid = '';

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_handleAppStateChanged);
    _bindRealtimeForCurrentUser();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showInitialFlow());
  }

  @override
  void dispose() {
    widget.appState.removeListener(_handleAppStateChanged);
    widget.appState.stopUserSync();
    super.dispose();
  }

  void _handleAppStateChanged() {
    if (!mounted) return;
    _bindRealtimeForCurrentUser();
  }

  void _bindRealtimeForCurrentUser() {
    final uid = widget.appState.user.uid.trim();
    if (uid == _boundRealtimeUid) return;

    widget.appState.stopUserSync();

    _boundRealtimeUid = uid;
    if (uid.isEmpty) return;

    widget.appState.startGroupsSync(uid);
    widget.appState.startEventsSync(uid);
    widget.appState.startTasksSync(uid);
  }

  void _openSettings() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SettingsScreen(appState: widget.appState),
    ),
  );

  Future<void> _markIntroCompleted() async {
    final uid = fa.FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'introCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _showInitialFlow() async {
    if (widget.showIntroOnLaunch) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IntroCarouselScreen(appState: widget.appState),
        ),
      );
      await _markIntroCompleted();
    }
    if (!mounted) return;
    if (_shownWelcome || widget.appState.groups.isNotEmpty) return;
    _shownWelcome = true;
    await showDialog(
      context: context,
      builder: (_) => WelcomeGroupDialog(appState: widget.appState),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      GroupsScreen(appState: widget.appState, onSettings: _openSettings),
      ChatListScreen(appState: widget.appState, onSettings: _openSettings),
      TodoScreen(appState: widget.appState, onSettings: _openSettings),
      CalendarScreen(appState: widget.appState, onSettings: _openSettings),
      ActivityScreen(appState: widget.appState, onSettings: _openSettings),
      AccountScreen(appState: widget.appState, showBackButton: false),
    ];
    return Scaffold(
      body: screens[_idx],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _idx,
        onTap: (index) => setState(() => _idx = index),
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Colors.white : const Color(0xFF3B82F6);
    final inactiveColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final items = const <({IconData icon, String label})>[
      (icon: LucideIcons.layoutGrid, label: 'Space'),
      (icon: LucideIcons.inbox, label: 'Inbox'),
      (icon: LucideIcons.clipboardList, label: 'Task'),
      (icon: LucideIcons.calendarDays, label: 'Calendar'),
      (icon: LucideIcons.bell, label: 'Activity'),
      (icon: LucideIcons.userRound, label: 'Account'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.surfaceDark.withValues(alpha: 0.97)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.gray200,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.38)
                : const Color.fromRGBO(15, 23, 42, 0.12),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: items[i].icon,
                      label: items[i].label,
                      isActive: currentIndex == i,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: isActive ? activeColor : inactiveColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTIVITY SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class ActivityScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback onSettings;
  const ActivityScreen({
    super.key,
    required this.appState,
    required this.onSettings,
  });

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _filter = 'view_all';
  static const Color _accent = Color(0xFF8B5CF6);
  static const Color _surface = AppTheme.gray50;

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  bool _matchesFilter(ActivityEntry e) {
    final text = '${e.title} ${e.subtitle}'.toLowerCase();
    switch (_filter) {
      case 'unread':
        // lightweight unread approximation: highlight very recent items
        return DateTime.now().difference(e.time).inMinutes <= 30;
      case 'mentions':
        return text.contains('mention') || text.contains('@');
      case 'replies':
        return text.contains('reply') || text.contains('replied');
      case 'view_all':
      default:
        return true;
    }
  }

  String _categoryFor(ActivityEntry e) {
    final text = '${e.title} ${e.subtitle}'.toLowerCase();
    if (text.contains('file') || text.contains('upload')) return 'Files';
    if (text.contains('group') ||
        text.contains('workspace') ||
        text.contains('member')) {
      return 'Workspaces';
    }
    if (text.contains('task')) return 'Tasks';
    if (text.contains('event') || text.contains('calendar')) return 'Events';
    return 'Messages';
  }

  Map<String, List<ActivityEntry>> _groupByCategory(
    List<ActivityEntry> entries,
  ) {
    final out = <String, List<ActivityEntry>>{};
    for (final e in entries) {
      out.putIfAbsent(_categoryFor(e), () => []).add(e);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final log = widget.appState.activityLog.where(_matchesFilter).toList();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          backgroundColor: isDark ? AppTheme.bgDark : _surface,
          appBar: AppBar(
            title: const Text(
              'Activity',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _TapSurface(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccountScreen(appState: widget.appState),
                  ),
                ),
                borderRadius: BorderRadius.circular(999),
                haptic: true,
                child: _UserAvatar(user: widget.appState.user),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => setState(() => _filter = 'view_all'),
                icon: const Icon(Icons.drafts_outlined, size: 16),
                label: const Text(
                  'Read all',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: widget.onSettings,
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [AppTheme.bgDark, AppTheme.surfaceDark]
                    : [AppTheme.gray50, Colors.white],
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 58,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _activityChip('View all', 'view_all'),
                              const SizedBox(width: 8),
                              _activityChip('Unread', 'unread'),
                              const SizedBox(width: 8),
                              _activityChip('Mentions', 'mentions'),
                              const SizedBox(width: 8),
                              _activityChip('Replies', 'replies'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: log.isEmpty
                        ? Center(
                            key: ValueKey('activity_empty_$_filter'),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 74,
                                  color: AppTheme.gray400,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No recent activity',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _filter == 'view_all'
                                      ? 'Your activity will appear here'
                                      : 'No $_filter activity right now',
                                  style: const TextStyle(
                                    color: AppTheme.gray600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            key: ValueKey('activity_list_$_filter'),
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                            children: log
                                .map(
                                  (a) => Container(
                                    margin: const EdgeInsets.fromLTRB(
                                      8,
                                      0,
                                      8,
                                      10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppTheme.surfaceDark
                                          : Colors.white.withValues(
                                              alpha: 0.96,
                                            ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isDark
                                            ? AppTheme.borderDark
                                            : AppTheme.gray200,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 2,
                                          ),
                                      leading: Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: a.color.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          a.icon,
                                          color: a.color,
                                          size: 18,
                                        ),
                                      ),
                                      title: Text(
                                        a.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        a.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppTheme.gray600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: Text(
                                        _timeAgo(a.time),
                                        style: const TextStyle(
                                          color: AppTheme.gray400,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _activityChip(String label, String id) {
    final selected = _filter == id;
    return _TapSurface(
      onTap: () => setState(() => _filter = id),
      borderRadius: BorderRadius.circular(12),
      haptic: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        width: 94,
        height: 34,
        decoration: BoxDecoration(
          color: selected
              ? _accent.withValues(alpha: 0.14)
              : (Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.surfaceDark
                    : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? _accent.withValues(alpha: 0.45)
                : AppTheme.gray200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _accent : AppTheme.gray600,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ActivitySearchScreen extends StatefulWidget {
  final AppState appState;
  const _ActivitySearchScreen({required this.appState});

  @override
  State<_ActivitySearchScreen> createState() => _ActivitySearchScreenState();
}

class _ActivitySearchScreenState extends State<_ActivitySearchScreen> {
  final _ctrl = TextEditingController();
  String _q = '';

  bool _matches(String text) {
    if (_q.isEmpty) return true;
    return text.toLowerCase().contains(_q);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = widget.appState.user.uid;
    final groups = widget.appState.groups
        .where((g) => _matches(g.name))
        .toList();
    final dataHits = widget.appState.activityLog
        .where((a) => _matches('${a.title} ${a.subtitle}'))
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Search',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          TextField(
            controller: _ctrl,
            onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search people, workspaces, files, data...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppTheme.gray100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
          const _SectionHeader(label: 'PEOPLE'),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const SizedBox.shrink();
              final users = (snapshot.data?.docs ?? const [])
                  .map(TaskMateUser.fromDoc)
                  .where((u) => u.uid != myUid)
                  .where(
                    (u) => _matches(
                      '${u.bestLabel} ${u.email} ${u.phoneNumber ?? ''}',
                    ),
                  )
                  .take(6)
                  .toList();
              if (users.isEmpty) {
                return Text(
                  'No people found',
                  style: TextStyle(color: AppTheme.gray600),
                );
              }
              return Column(
                children: users
                    .map(
                      (u) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          child: Icon(Icons.person, size: 16),
                        ),
                        title: Text(u.bestLabel),
                        subtitle: Text(
                          'Tap to view profile',
                          style: TextStyle(
                            color: AppTheme.gray600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const _SectionHeader(label: 'WORKSPACES'),
          if (groups.isEmpty)
            Text(
              'No workspaces found',
              style: TextStyle(color: AppTheme.gray600),
            )
          else
            ...groups
                .take(6)
                .map(
                  (g) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.group, size: 16),
                    ),
                    title: Text(g.name),
                    subtitle: Text('${g.memberCount} members'),
                  ),
                ),
          const _SectionHeader(label: 'FILES'),
          StreamBuilder<QuerySnapshot>(
            stream: myUid.isEmpty
                ? const Stream.empty()
                : FirebaseFirestore.instance
                      .collection('files')
                      .where('ownerUid', isEqualTo: myUid)
                      .limit(60)
                      .snapshots(),
            builder: (context, snapshot) {
              final files = (snapshot.data?.docs ?? const [])
                  .map((d) => (d.data() as Map<String, dynamic>?) ?? {})
                  .where(
                    (m) =>
                        _matches('${m['name'] ?? ''} ${m['category'] ?? ''}'),
                  )
                  .take(6)
                  .toList();
              if (files.isEmpty) {
                return Text(
                  'No files found',
                  style: TextStyle(color: AppTheme.gray600),
                );
              }
              return Column(
                children: files
                    .map(
                      (f) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          child: Icon(
                            Icons.insert_drive_file_rounded,
                            size: 16,
                          ),
                        ),
                        title: Text((f['name'] as String?) ?? 'File'),
                        subtitle: Text(
                          (f['category'] as String?) ?? 'Uncategorized',
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const _SectionHeader(label: 'DATA'),
          if (dataHits.isEmpty)
            Text('No data results', style: TextStyle(color: AppTheme.gray600))
          else
            ...dataHits
                .take(8)
                .map(
                  (a) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: a.color.withValues(alpha: 0.12),
                      child: Icon(a.icon, color: a.color, size: 18),
                    ),
                    title: Text(a.title),
                    subtitle: Text(
                      a.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MORE SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class MoreScreen extends StatelessWidget {
  final AppState appState;
  final VoidCallback onSettings;
  const MoreScreen({
    super.key,
    required this.appState,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'More',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: _TapSurface(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AccountScreen(appState: appState),
              ),
            ),
            borderRadius: BorderRadius.circular(999),
            haptic: true,
            child: _UserAvatar(user: appState.user),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: onSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary500.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.primary500.withValues(alpha: 0.18),
              ),
            ),
            child: const Text(
              'Workspace files are now organized inside each workspace.\nOpen a workspace > profile > Media, links and docs.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: const CircleAvatar(
              child: Icon(Icons.auto_awesome_outlined),
            ),
            title: const Text('Future features'),
            subtitle: const Text(
              'Calendar sync, integrations, advanced automations',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CalendarSyncSettingsScreen(appState: appState),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FOLDERS SCREEN (legacy)
// ═══════════════════════════════════════════════════════════════════════════
class FoldersScreen extends StatelessWidget {
  final AppState appState;
  final VoidCallback onSettings;
  const FoldersScreen({
    super.key,
    required this.appState,
    required this.onSettings,
  });

  Future<void> _openUploadSheet(
    BuildContext context, {
    String? groupId,
    String? chatId,
  }) async {
    final picked = await showModalBottomSheet<List<PlatformFile>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _UploadPickerSheet(),
    );
    if (picked == null || picked.isEmpty) return;
    final result = await appState.uploadFiles(
      files: picked,
      groupId: groupId,
      chatId: chatId,
    );
    if (!context.mounted) return;

    if (result.failedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Uploaded ${result.uploadedCount} file${result.uploadedCount == 1 ? '' : 's'}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final canRetry = result.retryableFiles.isNotEmpty;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          canRetry
              ? 'Uploaded ${result.uploadedCount}. ${result.failedCount} failed.'
              : 'Uploaded ${result.uploadedCount}. ${result.failedCount} failed (reselect to retry).',
        ),
        behavior: SnackBarBehavior.floating,
        action: canRetry
            ? SnackBarAction(
                label: 'Retry',
                onPressed: () async {
                  final retry = await appState.retryFailedUploads(
                    previousResult: result,
                    groupId: groupId,
                    chatId: chatId,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        retry.failedCount == 0
                            ? 'Retry succeeded for all failed uploads.'
                            : 'Retry uploaded ${retry.uploadedCount}, ${retry.failedCount} still failed.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    IconData selectedIcon = Icons.folder_rounded;
    Color selectedColor = AppTheme.primary500;
    final icons = [
      Icons.folder_rounded,
      Icons.star,
      Icons.lock_rounded,
      Icons.favorite_outline,
      Icons.bookmark_outline,
      Icons.cloud_outlined,
      Icons.code_outlined,
      Icons.music_note_outlined,
    ];
    final colors = [
      AppTheme.primary500,
      AppTheme.info,
      AppTheme.error,
      AppTheme.success,
      AppTheme.warning,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text(
            'New Folder Category',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Icon',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: icons
                      .map(
                        (ic) => _TapSurface(
                          onTap: () => setSt(() => selectedIcon = ic),
                          borderRadius: BorderRadius.circular(10),
                          haptic: true,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selectedIcon == ic
                                  ? selectedColor.withValues(alpha: 0.15)
                                  : AppTheme.gray100,
                              borderRadius: BorderRadius.circular(10),
                              border: selectedIcon == ic
                                  ? Border.all(color: selectedColor, width: 2)
                                  : null,
                            ),
                            child: Icon(
                              ic,
                              color: selectedIcon == ic
                                  ? selectedColor
                                  : AppTheme.gray600,
                              size: 22,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Colour',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: colors
                      .map(
                        (c) => _TapSurface(
                          onTap: () => setSt(() => selectedColor = c),
                          borderRadius: BorderRadius.circular(999),
                          haptic: true,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: selectedColor == c ? 30 : 26,
                            height: selectedColor == c ? 30 : 26,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: selectedColor == c
                                  ? Border.all(color: Colors.white, width: 2.5)
                                  : null,
                              boxShadow: selectedColor == c
                                  ? [
                                      BoxShadow(
                                        color: c.withValues(alpha: 0.5),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary500,
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                appState.addFolderCategory(
                  FolderCategory(
                    name: nameCtrl.text.trim(),
                    icon: selectedIcon,
                    color: selectedColor,
                    isCustom: true,
                  ),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final cats = appState.folderCategories;
        final myUid = fa.FirebaseAuth.instance.currentUser?.uid ?? '';
        final cs = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Folders',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _TapSurface(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccountScreen(appState: appState),
                  ),
                ),
                borderRadius: BorderRadius.circular(999),
                haptic: true,
                child: _UserAvatar(user: appState.user),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: onSettings,
              ),
            ],
          ),
          floatingActionButton: myUid.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _openUploadSheet(context),
                  backgroundColor: AppTheme.primary500,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  icon: const Icon(Icons.cloud_upload_rounded),
                  label: const Text('Upload'),
                ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              Text(
                'My files',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your categories and personal uploads',
                style: TextStyle(fontSize: 13, color: AppTheme.gray600),
              ),
              const SizedBox(height: 14),
              _FolderCategoryGrid(
                shrinkWrap: true,
                appState: appState,
                categories: cats,
                scopeTitle: 'My files',
                query: myUid.isEmpty
                    ? null
                    : FirebaseFirestore.instance
                          .collection('files')
                          .where('ownerUid', isEqualTo: myUid)
                          .where('groupId', isNull: true),
                onAddCategory: () => _showAddCategoryDialog(context),
                onOpenCategory: (catName) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FolderCategoryDetailScreen(
                        title: catName,
                        query: FirebaseFirestore.instance
                            .collection('files')
                            .where('ownerUid', isEqualTo: myUid)
                            .where('groupId', isNull: true)
                            .where('category', isEqualTo: catName),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Workspace folders',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Files shared with each workspace',
                style: TextStyle(fontSize: 13, color: AppTheme.gray600),
              ),
              const SizedBox(height: 14),
              if (appState.groups.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No workspaces yet',
                      style: TextStyle(color: AppTheme.gray600, fontSize: 15),
                    ),
                  ),
                )
              else
                ...appState.groups.map(
                  (g) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: cs.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppTheme.gray200),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: _GroupAvatar(group: g, radius: 20),
                        title: Text(
                          g.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${g.memberCount} members',
                          style: TextStyle(
                            color: AppTheme.gray600,
                            fontSize: 13,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.gray400,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                GroupFolderScreen(appState: appState, group: g),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _UploadPickerSheet extends StatefulWidget {
  const _UploadPickerSheet();

  @override
  State<_UploadPickerSheet> createState() => _UploadPickerSheetState();
}

class _UploadPickerSheetState extends State<_UploadPickerSheet> {
  bool _picking = false;

  Future<void> _pick() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
      );
      if (!mounted) return;
      final files = res?.files ?? [];
      Navigator.pop(context, files);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload files',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Files are sorted automatically by type.',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _picking ? null : _pick,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: Icon(
                _picking
                    ? Icons.hourglass_top_rounded
                    : Icons.folder_open_rounded,
                size: 22,
              ),
              label: Text(
                _picking ? 'Opening file picker…' : 'Browse files',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderCategoryGrid extends StatelessWidget {
  final AppState appState;
  final List<FolderCategory> categories;
  final Query? query;
  final String scopeTitle;
  final VoidCallback onAddCategory;
  final void Function(String catName) onOpenCategory;

  /// When true, grid sizes to content (for use inside a parent [ListView]).
  final bool shrinkWrap;

  const _FolderCategoryGrid({
    required this.appState,
    required this.categories,
    required this.query,
    required this.scopeTitle,
    required this.onAddCategory,
    required this.onOpenCategory,
    this.shrinkWrap = false,
  });

  Widget _buildGrid(Stream<QuerySnapshot<Object?>>? stream) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final counts = <String, int>{};
        if (snapshot.hasData) {
          for (final d in snapshot.data!.docs) {
            final m = (d.data() as Map<String, dynamic>?) ?? {};
            final cat = (m['category'] as String?) ?? 'Important';
            counts[cat] = (counts[cat] ?? 0) + 1;
          }
        }
        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemCount: categories.length + 1,
          itemBuilder: (context, i) {
            if (i == categories.length) {
              return _TapSurface(
                onTap: onAddCategory,
                borderRadius: BorderRadius.circular(16),
                haptic: true,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.gray200, width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 36,
                        color: AppTheme.gray400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Category',
                        style: TextStyle(
                          color: AppTheme.gray600,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final cat = categories[i];
            final c = counts[cat.name] ?? 0;
            return _TapSurface(
              onTap: () => onOpenCategory(cat.name),
              borderRadius: BorderRadius.circular(16),
              haptic: true,
              child: Container(
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cat.color.withValues(alpha: 0.2)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 22),
                        ),
                        const Spacer(),
                        if (cat.isCustom)
                          Icon(Icons.star, size: 14, color: cat.color),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      cat.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$c file${c == 1 ? '' : 's'}',
                      style: TextStyle(color: AppTheme.gray600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final header = Text(
      '${categories.length} categories · $scopeTitle',
      style: TextStyle(color: AppTheme.gray600, fontSize: 13),
    );
    final stream = query?.snapshots();
    if (shrinkWrap) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [header, const SizedBox(height: 12), _buildGrid(stream)],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 12),
        Expanded(child: _buildGrid(stream)),
      ],
    );
  }
}

class FolderCategoryDetailScreen extends StatelessWidget {
  final String title;
  final Query query;

  const FolderCategoryDetailScreen({
    super.key,
    required this.title,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final msg = snapshot.error?.toString() ?? '';
            if (msg.contains('failed-precondition') || msg.contains('index')) {
              return const Center(
                child: Text(
                  'File index is building.\nPlease try again in a moment.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return const Center(child: Text('Failed to load files'));
          }
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = [...snapshot.data!.docs]
            ..sort((a, b) {
              final ma = (a.data() as Map<String, dynamic>?) ?? {};
              final mb = (b.data() as Map<String, dynamic>?) ?? {};
              final ta = (ma['createdAt'] as Timestamp?)?.toDate();
              final tb = (mb['createdAt'] as Timestamp?)?.toDate();
              if (ta == null && tb == null) return 0;
              if (ta == null) return 1;
              if (tb == null) return -1;
              return tb.compareTo(ta);
            });
          if (docs.isEmpty)
            return Center(
              child: Text(
                'No files yet',
                style: TextStyle(color: AppTheme.gray600),
              ),
            );
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, i) => const Divider(height: 20),
            itemBuilder: (context, i) {
              final m = (docs[i].data() as Map<String, dynamic>?) ?? {};
              final name = (m['name'] as String?) ?? 'File';
              final size = (m['size'] as int?) ?? 0;
              final ext = (m['ext'] as String?) ?? '';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconForExt(ext), color: AppTheme.primary500),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${_prettyBytes(size)} · ${ext.isEmpty ? 'file' : ext.toUpperCase()}',
                  style: TextStyle(color: AppTheme.gray600, fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static IconData _iconForExt(String ext) {
    final e = ext.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(e))
      return Icons.photo_library_rounded;
    if (e == 'pdf') return Icons.picture_as_pdf_outlined;
    if (['doc', 'docx', 'rtf'].contains(e)) return Icons.description_rounded;
    if (['mp4', 'mov', 'mkv', 'webm'].contains(e)) return Icons.videocam;
    return Icons.description_rounded;
  }

  static String _prettyBytes(int b) {
    if (b <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = b.toDouble();
    var u = 0;
    while (size >= 1024 && u < units.length - 1) {
      size /= 1024;
      u++;
    }
    return '${size.toStringAsFixed(u == 0 ? 0 : 1)} ${units[u]}';
  }
}

class GroupFolderScreen extends StatelessWidget {
  final AppState appState;
  final GroupModel group;

  const GroupFolderScreen({
    super.key,
    required this.appState,
    required this.group,
  });

  Future<void> _openUpload(BuildContext context) async {
    final picked = await showModalBottomSheet<List<PlatformFile>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _UploadPickerSheet(),
    );
    if (picked == null || picked.isEmpty) return;
    final result = await appState.uploadFiles(files: picked, groupId: group.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.failedCount == 0
              ? 'Uploaded to ${group.name}'
              : 'Uploaded ${result.uploadedCount} to ${group.name}, ${result.failedCount} failed',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = appState.folderCategories;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openUpload(context),
        backgroundColor: AppTheme.primary500,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.cloud_upload_rounded),
        label: const Text('Upload'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        child: _FolderCategoryGrid(
          appState: appState,
          categories: cats,
          scopeTitle: 'Workspace files',
          query: FirebaseFirestore.instance
              .collection('files')
              .where('groupId', isEqualTo: group.id),
          onAddCategory: () {},
          onOpenCategory: (catName) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FolderCategoryDetailScreen(
                  title: '$catName · ${group.name}',
                  query: FirebaseFirestore.instance
                      .collection('files')
                      .where('groupId', isEqualTo: group.id)
                      .where('category', isEqualTo: catName),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACCOUNT SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class AccountScreen extends StatefulWidget {
  final AppState appState;
  final bool showBackButton;
  const AccountScreen({
    super.key,
    required this.appState,
    this.showBackButton = true,
  });
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _savingAvatar = false;

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppTheme.error : null,
      ),
    );
  }

  Future<PlatformFile?> _platformFileFromXFile(XFile x) async {
    final bytes = await x.readAsBytes();
    var name = x.name.trim();
    if (name.isEmpty) {
      final parts = x.path.split(RegExp(r'[/\\]'));
      name = parts.isNotEmpty ? parts.last.trim() : '';
    }
    if (name.isEmpty) {
      name = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }
    return PlatformFile(name: name, size: bytes.length, bytes: bytes);
  }

  Future<void> _saveAvatarSelection({
    String? photoUrl,
    String? avatarPresetId,
  }) async {
    final currentUser = fa.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final trimmedPhoto = (photoUrl ?? '').trim();
    final normalizedPhoto = trimmedPhoto.isEmpty ? null : trimmedPhoto;
    final trimmedPreset = (avatarPresetId ?? '').trim();
    final normalizedPreset = trimmedPreset.isEmpty ? null : trimmedPreset;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .set({
          'photoUrl': normalizedPhoto,
          'avatarPresetId': normalizedPreset,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    await currentUser.updatePhotoURL(normalizedPhoto);
    widget.appState.user.updateAvatar(
      photoUrl: normalizedPhoto,
      avatarPresetId: normalizedPreset,
    );
  }

  Future<void> _pickAvatarFromGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null || !mounted) return;
    final file = await _platformFileFromXFile(picked);
    if (file == null || file.bytes == null || file.bytes!.isEmpty) {
      _toast('Could not read selected image.', isError: true);
      return;
    }

    setState(() => _savingAvatar = true);
    try {
      final currentUser = fa.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _toast('Sign in required to update profile photo.', isError: true);
        return;
      }
      final ext = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'jpg';
      final contentType =
          lookupMimeType(file.name, headerBytes: file.bytes!) ?? 'image/jpeg';
      final storagePath =
          'uploads/${currentUser.uid}/avatars/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = FirebaseStorage.instance.ref(storagePath);
      await ref.putData(
        file.bytes!,
        SettableMetadata(contentType: contentType),
      );
      final downloadUrl = await ref.getDownloadURL();
      await _saveAvatarSelection(photoUrl: downloadUrl, avatarPresetId: null);
      _toast('Profile photo updated.');
    } on FirebaseException catch (e) {
      _toast(e.message ?? 'Could not upload profile photo.', isError: true);
    } catch (_) {
      _toast(
        'Could not update profile photo. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _savingAvatar = false);
      }
    }
  }

  Future<void> _setAvatarPreset(String presetId) async {
    setState(() => _savingAvatar = true);
    try {
      await _saveAvatarSelection(photoUrl: null, avatarPresetId: presetId);
      _toast('Avatar updated.');
    } on FirebaseException catch (e) {
      _toast(e.message ?? 'Could not update avatar.', isError: true);
    } catch (_) {
      _toast('Could not update avatar. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _savingAvatar = false);
      }
    }
  }

  void _showAvatarOptionsSheet() {
    final cs = Theme.of(context).colorScheme;
    final selectedPreset = widget.appState.user.avatarPresetId;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Text(
                  'Change profile photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a preset avatar or upload from your gallery.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.18,
                  ),
                  itemCount: _kAvatarPresets.length,
                  itemBuilder: (_, i) {
                    final preset = _kAvatarPresets[i];
                    final isSelected = selectedPreset == preset.id;
                    return _TapSurface(
                      onTap: () async {
                        Navigator.pop(sheetCtx);
                        await _setAvatarPreset(preset.id);
                      },
                      borderRadius: BorderRadius.circular(14),
                      haptic: true,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: preset.backgroundColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? cs.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            preset.icon,
                            color: preset.foregroundColor,
                            size: 30,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetCtx);
                    await _pickAvatarFromGallery();
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: AppTheme.primary500,
                  ),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Upload from gallery'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editField(
    String title,
    String current,
    String hint,
    void Function(String) onSave, {
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Change $title',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          autofocus: true,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary500),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) onSave(ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState.user,
      builder: (context, _) {
        final user = widget.appState.user;
        return Scaffold(
          appBar: AppBar(
            leading: widget.showBackButton
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: const Text(
              'Account',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: ListView(
            children: [
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        _TapSurface(
                          onTap: _savingAvatar ? null : _showAvatarOptionsSheet,
                          borderRadius: BorderRadius.circular(999),
                          haptic: true,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _UserAvatar(
                                user: user,
                                radius: 44,
                                emphasized: true,
                              ),
                              if (_savingAvatar)
                                const SizedBox(
                                  width: 88,
                                  height: 88,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary500,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(color: AppTheme.gray600, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const _SectionHeader(label: 'ACCOUNT INFO'),
              _infoTile(
                icon: Icons.person,
                color: AppTheme.primary500,
                label: 'Display Name',
                value: user.displayName,
                onTap: () => _editField(
                  'Name',
                  user.displayName,
                  'Enter your name',
                  (v) => user.updateName(v),
                ),
              ),
              _infoTile(
                icon: Icons.email_outlined,
                color: AppTheme.info,
                label: 'Email',
                value: user.email,
                onTap: () => _editField(
                  'Email',
                  user.email,
                  'Enter your email',
                  (v) => user.updateEmail(v),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              _infoTile(
                icon: Icons.phone_outlined,
                color: AppTheme.success,
                label: 'Phone Number',
                value: user.phoneNumber ?? 'Not set',
                onTap: () => _editField(
                  'Phone Number',
                  user.phoneNumber ?? '',
                  '+977 98XXX XXXXX',
                  (v) => user.updatePhone(v),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const _SectionHeader(label: 'SECURITY'),
              _infoTile(
                icon: Icons.lock_rounded,
                color: AppTheme.warning,
                label: 'Password',
                value: '••••••••',
                onTap: () => _editField(
                  'Password',
                  '',
                  'New password',
                  (v) {},
                  obscure: true,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await fa.FirebaseAuth.instance.signOut();
                    widget.appState.user.logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(appState: widget.appState),
                      ),
                      (_) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, color: AppTheme.error),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(color: AppTheme.error, fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: const BorderSide(color: AppTheme.error),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppTheme.gray600),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.edit_outlined,
        size: 18,
        color: AppTheme.gray600,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CHAT LIST SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class ChatListScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback onSettings;
  const ChatListScreen({
    super.key,
    required this.appState,
    required this.onSettings,
  });
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

// ═══════════════════════════════════════════════════════════════════════════
// GROUPS / TEAMS TAB (separate from DMs)
// ═══════════════════════════════════════════════════════════════════════════
class GroupsScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback onSettings;
  const GroupsScreen({
    super.key,
    required this.appState,
    required this.onSettings,
  });

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openQuickCreate() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.gray200,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: AppTheme.gray50,
                leading: const Icon(Icons.group_add_rounded),
                title: const Text('Create workspace'),
                subtitle: const Text('Create a new workspace'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) =>
                        CreateGroupDialog(appState: widget.appState),
                    barrierDismissible: false,
                  );
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: AppTheme.gray50,
                leading: const Icon(Icons.draw_rounded),
                title: const Text('Create whiteboard'),
                subtitle: const Text(
                  'Editable board for one selected workspace',
                ),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (_) =>
                        CreateWhiteboardSheet(appState: widget.appState),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myUid = fa.FirebaseAuth.instance.currentUser?.uid ?? '';
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final groups = widget.appState.groups.where((g) {
          if (_query.isEmpty) return true;
          final q = _query.toLowerCase();
          return g.name.toLowerCase().contains(q) ||
              g.code.toLowerCase().contains(q);
        }).toList();
        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0F0F13)
              : const Color(0xFFF4F5F7),
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _TapSurface(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccountScreen(appState: widget.appState),
                  ),
                ),
                borderRadius: BorderRadius.circular(999),
                haptic: true,
                child: _UserAvatar(user: widget.appState.user),
              ),
            ),
            title: const Text(
              'Space',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
            ),
            actions: [
              IconButton(
                tooltip: 'Create workspace',
                icon: const Icon(Icons.group_add_outlined),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) =>
                        CreateGroupDialog(appState: widget.appState),
                    barrierDismissible: false,
                  );
                },
              ),
              IconButton(
                tooltip: 'Create whiteboard',
                icon: const Icon(Icons.add_rounded),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (_) =>
                        CreateWhiteboardSheet(appState: widget.appState),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: widget.onSettings,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
            children: [
              TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search spaces and profiles',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.gray600),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1F25) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (_query.isNotEmpty) ...[
                const Text(
                  'PROFILES',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gray600,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 92,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      final q = _query.toLowerCase();
                      final me = widget.appState.user.uid.trim();
                      final users = snapshot.data!.docs
                          .map(TaskMateUser.fromDoc)
                          .where(
                            (u) =>
                                u.uid.isNotEmpty &&
                                u.uid != me &&
                                (u.bestLabel.toLowerCase().contains(q) ||
                                    u.email.toLowerCase().contains(q) ||
                                    (u.phoneNumber ?? '')
                                        .toLowerCase()
                                        .contains(q)),
                          )
                          .take(10)
                          .toList();
                      if (users.isEmpty) return const SizedBox.shrink();
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final u = users[i];
                          return Container(
                            width: 150,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E1F25)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : AppTheme.gray200,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppTheme.primary500,
                                  child: Text(
                                    u.bestLabel.isNotEmpty
                                        ? u.bestLabel[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    u.bestLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'YOUR WORKSPACES',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray600,
                ),
              ),
              const SizedBox(height: 10),
              if (groups.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1F25) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('No workspaces yet. Tap + to create one.'),
                )
              else
                ...groups.map(
                  (g) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1F25) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      onTap: () {
                        widget.appState.logChatActivity(
                          g.name,
                          'Workspace · ${g.memberCount} members',
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              title: g.name,
                              chatId: g.id,
                              isGroup: true,
                              group: g,
                              appState: widget.appState,
                            ),
                          ),
                        );
                      },
                      leading: Hero(
                        tag: 'group_${g.id}',
                        child: _GroupAvatar(group: g, radius: 22),
                      ),
                      title: Text(
                        g.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${g.memberCount} member${g.memberCount == 1 ? '' : 's'}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'WHITEBOARDS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray600,
                ),
              ),
              const SizedBox(height: 10),
              if (myUid.isEmpty)
                const Text('Sign in to access whiteboards.')
              else
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('whiteboards')
                      .where('memberUids', arrayContains: myUid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        _friendlyFirestoreError(
                          snapshot.error,
                          fallback: 'Failed to load whiteboards.',
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final boards = snapshot.data!.docs.toList();
                    boards.sort((a, b) {
                      final am = (a.data() as Map<String, dynamic>?) ?? {};
                      final bm = (b.data() as Map<String, dynamic>?) ?? {};
                      final at = (am['updatedAt'] as Timestamp?)?.toDate();
                      final bt = (bm['updatedAt'] as Timestamp?)?.toDate();
                      if (at == null && bt == null) return 0;
                      if (at == null) return 1;
                      if (bt == null) return -1;
                      return bt.compareTo(at);
                    });
                    if (boards.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1F25)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'No whiteboards yet. Tap + and choose Create whiteboard.',
                        ),
                      );
                    }
                    return Column(
                      children: boards.map((d) {
                        final m = (d.data() as Map<String, dynamic>?) ?? {};
                        final groupName =
                            (m['groupName'] as String?) ?? 'Workspace';
                        final title =
                            (m['title'] as String?) ?? 'Untitled board';
                        final preview =
                            (m['content'] as String?)?.trim().isNotEmpty ??
                                false
                            ? (m['content'] as String).trim()
                            : 'Blank whiteboard';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1F25)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white10 : AppTheme.gray200,
                            ),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.draw_rounded),
                            title: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '$groupName · $preview',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WhiteboardEditorScreen(
                                  boardId: d.id,
                                  initialTitle: title,
                                  groupName: groupName,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class CreateWhiteboardSheet extends StatefulWidget {
  final AppState appState;
  const CreateWhiteboardSheet({super.key, required this.appState});

  @override
  State<CreateWhiteboardSheet> createState() => _CreateWhiteboardSheetState();
}

class _CreateWhiteboardSheetState extends State<CreateWhiteboardSheet> {
  final _titleCtrl = TextEditingController();
  String? _groupId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.appState.groups.isNotEmpty) {
      _groupId = widget.appState.groups.first.id;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving) return;
    GroupModel? group;
    for (final g in widget.appState.groups) {
      if (g.id == _groupId) {
        group = g;
        break;
      }
    }
    if (group == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a workspace first.')),
      );
      return;
    }
    final title = _titleCtrl.text.trim().isEmpty
        ? 'Untitled whiteboard'
        : _titleCtrl.text.trim();
    final memberUids = <String>{
      for (final m in group.members)
        if ((m.userId ?? '').trim().isNotEmpty) m.userId!.trim(),
      widget.appState.user.uid,
    }.where((u) => u.isNotEmpty).toList();
    if (memberUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected workspace has no TaskMate members yet.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('whiteboards').add({
        'title': title,
        'content': '',
        'groupId': group.id,
        'groupName': group.name,
        'ownerUid': widget.appState.user.uid,
        'memberUids': memberUids,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Whiteboard created.')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create whiteboard.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.gray200,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Create whiteboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Board title',
                hintText: 'Sprint planning ideas',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _groupId,
              items: widget.appState.groups
                  .map(
                    (g) => DropdownMenuItem(value: g.id, child: Text(g.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _groupId = v),
              decoration: InputDecoration(
                labelText: 'Workspace',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _create,
                icon: const Icon(Icons.draw_rounded),
                label: Text(_saving ? 'Creating...' : 'Create'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WhiteboardEditorScreen extends StatefulWidget {
  final String boardId;
  final String initialTitle;
  final String groupName;
  const WhiteboardEditorScreen({
    super.key,
    required this.boardId,
    required this.initialTitle,
    required this.groupName,
  });

  @override
  State<WhiteboardEditorScreen> createState() => _WhiteboardEditorScreenState();
}

class _WhiteboardEditorScreenState extends State<WhiteboardEditorScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  bool _ready = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _saveContent(String value) async {
    await FirebaseFirestore.instance
        .collection('whiteboards')
        .doc(widget.boardId)
        .set({
          'content': value,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _deleteBoard() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete whiteboard?'),
        content: const Text(
          'This board will be removed for all workspace members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await FirebaseFirestore.instance
        .collection('whiteboards')
        .doc(widget.boardId)
        .delete();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('whiteboards')
          .doc(widget.boardId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = (snapshot.data?.data() as Map<String, dynamic>?) ?? {};
        final title = (data['title'] as String?) ?? widget.initialTitle;
        final content = (data['content'] as String?) ?? '';
        if (!_ready) {
          _ctrl.text = content;
          _ready = true;
        } else if (_ctrl.text != content) {
          _ctrl.text = content;
          _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
        }
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18)),
                Text(
                  widget.groupName,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : AppTheme.gray600,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _deleteBoard,
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121217) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : AppTheme.gray200,
                ),
              ),
              child: TextField(
                controller: _ctrl,
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    unawaited(_saveContent(v));
                  });
                },
                expands: true,
                maxLines: null,
                minLines: null,
                decoration: const InputDecoration(
                  hintText: 'Start typing on this whiteboard...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _chatFilter = 'all';

  bool _isUnreadThread(Map<String, dynamic> data) {
    final t = (data['updatedAt'] as Timestamp?)?.toDate();
    if (t == null) return false;
    return DateTime.now().difference(t).inMinutes <= 30;
  }

  String _dmThreadId(String a, String b) {
    final p = [a, b]..sort();
    return 'dm_${p[0]}_${p[1]}';
  }

  Future<void> _startDirectChat() async {
    final picked = await showModalBottomSheet<TaskMateUser>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UserPickerSheet(
        currentUid: fa.FirebaseAuth.instance.currentUser?.uid ?? '',
      ),
    );
    if (picked == null) return;
    final my = fa.FirebaseAuth.instance.currentUser;
    if (my == null) return;
    final otherUid = picked.uid.trim();
    if (otherUid.isEmpty || otherUid == my.uid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start chat with this user.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final canonicalThreadId = _dmThreadId(my.uid, otherUid);
    var threadId = canonicalThreadId;
    final meName = widget.appState.user.displayName.trim().isNotEmpty
        ? widget.appState.user.displayName.trim()
        : (my.email ?? 'Me');
    final otherName = picked.bestLabel;

    Future<void> createOrUpdateThread(String id) async {
      await FirebaseFirestore.instance.collection('dmThreads').doc(id).set({
        'id': id,
        'participants': [my.uid, otherUid],
        'participantNames': {my.uid: meName, otherUid: otherName},
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
      }, SetOptions(merge: true));
    }

    try {
      await createOrUpdateThread(canonicalThreadId);
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _friendlyFirestoreError(
                e,
                fallback: 'Could not start direct chat',
              ),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Recover from legacy/corrupt thread docs that deny update on canonical id.
      threadId =
          '${canonicalThreadId}_${DateTime.now().millisecondsSinceEpoch}';
      try {
        await createOrUpdateThread(threadId);
      } on FirebaseException catch (fallbackError) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _friendlyFirestoreError(
                fallbackError,
                fallback: 'Could not start direct chat',
              ),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          title: otherName,
          chatId: threadId,
          isGroup: false,
          peerUserId: otherUid,
          appState: widget.appState,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final myUid = fa.FirebaseAuth.instance.currentUser?.uid ?? '';
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Inbox',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _TapSurface(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccountScreen(appState: widget.appState),
                  ),
                ),
                borderRadius: BorderRadius.circular(999),
                haptic: true,
                child: _UserAvatar(user: widget.appState.user),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: _startDirectChat,
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: widget.onSettings,
              ),
            ],
          ),
          body: ListView(
            children: [
              if (myUid.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 72,
                          color: AppTheme.gray200,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sign in to chat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your direct messages will appear here',
                          style: TextStyle(color: AppTheme.gray600),
                        ),
                      ],
                    ),
                  ),
                ),
              if (myUid.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      _chatFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _chatFilterChip('Unread', 'unread'),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => setState(() => _chatFilter = 'all'),
                        icon: const Icon(
                          Icons.drafts_outlined,
                          size: 16,
                          color: AppTheme.primary500,
                        ),
                        label: const Text(
                          'Read all',
                          style: TextStyle(
                            color: AppTheme.primary500,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Text(
                    'DIRECT MESSAGES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.gray600,
                    ),
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('dmThreads')
                      .where('participants', arrayContains: myUid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _friendlyFirestoreError(
                            snapshot.error,
                            fallback: 'Failed to load direct messages',
                          ),
                          style: TextStyle(color: AppTheme.gray600),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No direct messages yet',
                              style: TextStyle(color: AppTheme.gray600),
                            ),
                            const SizedBox(height: 10),
                            FilledButton.icon(
                              onPressed: _startDirectChat,
                              icon: const Icon(
                                Icons.chat_bubble_outline_rounded,
                              ),
                              label: const Text('Start Chat'),
                              style: FilledButton.styleFrom(
                                backgroundColor: cs.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    // Sort client-side to avoid composite index requirements.
                    docs.sort((a, b) {
                      final ad = (a.data() as Map<String, dynamic>?) ?? {};
                      final bd = (b.data() as Map<String, dynamic>?) ?? {};
                      final at = (ad['updatedAt'] as Timestamp?)?.toDate();
                      final bt = (bd['updatedAt'] as Timestamp?)?.toDate();
                      if (at == null && bt == null) return 0;
                      if (at == null) return 1;
                      if (bt == null) return -1;
                      return bt.compareTo(at);
                    });
                    final filteredDocs = docs.where((d) {
                      final data = (d.data() as Map<String, dynamic>?) ?? {};
                      if (_chatFilter == 'unread') return _isUnreadThread(data);
                      return true;
                    }).toList();
                    if (filteredDocs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Text(
                          _chatFilter == 'unread'
                              ? 'No unread messages'
                              : 'No direct messages',
                          style: TextStyle(color: AppTheme.gray600),
                        ),
                      );
                    }
                    return Column(
                      children: filteredDocs.map((d) {
                        final data = (d.data() as Map<String, dynamic>?) ?? {};
                        final names =
                            (data['participantNames'] as Map?)
                                ?.cast<String, dynamic>() ??
                            {};
                        final participants =
                            (data['participants'] as List?)?.cast<String>() ??
                            const [];
                        final otherUid = participants.firstWhere(
                          (u) => u != myUid,
                          orElse: () => '',
                        );
                        final otherName =
                            (names[otherUid] as String?) ?? 'User';
                        final lastMessage =
                            (data['lastMessage'] as String?) ?? '';
                        return Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatDetailScreen(
                                      title: otherName,
                                      chatId: d.id,
                                      isGroup: false,
                                      peerUserId: otherUid.isNotEmpty
                                          ? otherUid
                                          : null,
                                      appState: widget.appState,
                                    ),
                                  ),
                                );
                              },
                              leading: Hero(
                                tag: otherUid.isNotEmpty
                                    ? 'dm_peer_$otherUid'
                                    : 'dm_list_${d.id}',
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.primary500,
                                  child: Text(
                                    otherName.isNotEmpty
                                        ? otherName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                otherName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                lastMessage.isEmpty
                                    ? 'Tap to chat'
                                    : lastMessage,
                                style: TextStyle(
                                  color: _isUnreadThread(data)
                                      ? Colors.black87
                                      : AppTheme.gray600,
                                  fontSize: 13,
                                  fontWeight: _isUnreadThread(data)
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _chatFilterChip(String label, String id) {
    final selected = _chatFilter == id;
    return _TapSurface(
      onTap: () => setState(() => _chatFilter = id),
      borderRadius: BorderRadius.circular(999),
      haptic: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary500.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppTheme.primary500.withValues(alpha: 0.55)
                : AppTheme.gray200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.primary500 : AppTheme.gray700,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _UserPickerSheet extends StatefulWidget {
  final String currentUid;
  const _UserPickerSheet({required this.currentUid});

  @override
  State<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<_UserPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _q = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.gray200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Start chat',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.gray600),
                  filled: true,
                  fillColor: AppTheme.gray100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return Center(
                      child: Text(
                        _friendlyFirestoreError(
                          snapshot.error,
                          fallback: 'Failed to load users',
                        ),
                      ),
                    );
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  final users = snapshot.data!.docs
                      .map(TaskMateUser.fromDoc)
                      .where(
                        (u) => u.uid.isNotEmpty && u.uid != widget.currentUid,
                      )
                      .toList();
                  final filtered = _q.isEmpty
                      ? users
                      : users
                            .where(
                              (u) =>
                                  u.bestLabel.toLowerCase().contains(_q) ||
                                  u.email.toLowerCase().contains(_q) ||
                                  (u.phoneNumber ?? '').toLowerCase().contains(
                                    _q,
                                  ),
                            )
                            .toList();
                  if (filtered.isEmpty)
                    return Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(color: AppTheme.gray400),
                      ),
                    );
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final u = filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary500,
                          child: Text(
                            u.bestLabel.isNotEmpty
                                ? u.bestLabel[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          u.bestLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Tap to start chat',
                          style: TextStyle(
                            color: AppTheme.gray600,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, u),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CHAT DETAIL SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class ChatDetailScreen extends StatefulWidget {
  final String title;
  final String chatId;
  final bool isGroup;

  /// Other participant’s Firebase uid (direct messages only).
  final String? peerUserId;
  final GroupModel? group;
  final AppState? appState;
  const ChatDetailScreen({
    super.key,
    required this.title,
    required this.chatId,
    required this.isGroup,
    this.peerUserId,
    this.group,
    this.appState,
  });
  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<String> _recentEmojis = [];

  /// Backward compatibility: older builds used a human-readable name as `chatId`.
  /// - Groups: previously used group name
  /// - DMs: could have used title
  List<String> get _chatIdCandidates {
    final ids = <String>{widget.chatId};
    final legacy = widget.title.trim();
    if (legacy.isNotEmpty) ids.add(legacy);
    return ids.toList();
  }

  Future<void> _handleSend() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final my = fa.FirebaseAuth.instance.currentUser;
    final myUid = my?.uid ?? '';
    final myName =
        (widget.appState?.user.displayName.trim().isNotEmpty ?? false)
        ? widget.appState!.user.displayName.trim()
        : (my?.email ?? 'Me');

    await FirebaseFirestore.instance.collection('messages').add({
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'senderUid': myUid,
      'senderName': myName,
      'chatId': widget.chatId,
      'chatIdLegacy': widget.title,
      'chatType': widget.isGroup ? 'group' : 'dm',
    });

    // Update DM thread list metadata.
    if (!widget.isGroup && widget.chatId.startsWith('dm_')) {
      await FirebaseFirestore.instance
          .collection('dmThreads')
          .doc(widget.chatId)
          .set({
            'updatedAt': FieldValue.serverTimestamp(),
            'lastMessage': text,
          }, SetOptions(merge: true));
    }

    _ctrl.clear();
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<PlatformFile?> _platformFileFromXFile(XFile x) async {
    final bytes = await x.readAsBytes();
    var name = x.name.trim();
    if (name.isEmpty) {
      final p = x.path;
      final parts = p.split(RegExp(r'[/\\]'));
      final seg = parts.isNotEmpty ? parts.last : '';
      if (seg.contains('.')) name = seg;
    }
    if (name.isEmpty)
      name = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return PlatformFile(name: name, size: bytes.length, bytes: bytes);
  }

  Future<void> _sendPickedFiles(List<PlatformFile> files) async {
    if (files.isEmpty) return;
    final appState = widget.appState;
    if (appState == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in to send attachments.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (files.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read the selected file.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final result = await appState.uploadFiles(
      files: files,
      groupId: widget.isGroup ? widget.chatId : null,
      chatId: widget.chatId,
    );
    if (result.uploadedEntries.isEmpty) {
      if (mounted) {
        final firstReason = result.failedEntries.isNotEmpty
            ? result.failedEntries.first.reason
            : 'Upload failed. Check your connection.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(firstReason),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final my = fa.FirebaseAuth.instance.currentUser;
    final myUid = my?.uid ?? '';
    final myName =
        (widget.appState?.user.displayName.trim().isNotEmpty ?? false)
        ? widget.appState!.user.displayName.trim()
        : (my?.email ?? 'Me');

    for (final uploaded in result.uploadedEntries) {
      final f = uploaded.sourceFile;
      final mimeType = lookupMimeType(f.name, headerBytes: f.bytes ?? const []);
      await FirebaseFirestore.instance.collection('messages').add({
        'text': f.name,
        'createdAt': FieldValue.serverTimestamp(),
        'senderUid': myUid,
        'senderName': myName,
        'chatId': widget.chatId,
        'chatIdLegacy': widget.title,
        'chatType': widget.isGroup ? 'group' : 'dm',
        'messageType': 'file',
        'fileName': f.name,
        'fileSize': f.size,
        'mimeType': mimeType,
        'fileDocId': uploaded.fileDocId,
        'fileUrl': uploaded.downloadUrl,
      });
    }

    if (!widget.isGroup && widget.chatId.startsWith('dm_')) {
      final preview = result.uploadedEntries.length == 1
          ? '📎 ${result.uploadedEntries.first.sourceFile.name}'
          : '📎 ${result.uploadedEntries.length} files';
      await FirebaseFirestore.instance
          .collection('dmThreads')
          .doc(widget.chatId)
          .set({
            'updatedAt': FieldValue.serverTimestamp(),
            'lastMessage': preview,
          }, SetOptions(merge: true));
    }

    if (result.failedCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.uploadedCount} uploaded, ${result.failedCount} failed',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    List<XFile> images = [];
    if (kIsWeb) {
      final one = await picker.pickImage(source: ImageSource.gallery);
      if (one != null) images = [one];
    } else {
      images = await picker.pickMultiImage();
      if (images.isEmpty) {
        final one = await picker.pickImage(source: ImageSource.gallery);
        if (one != null) images = [one];
      }
    }
    final files = <PlatformFile>[];
    for (final x in images) {
      final pf = await _platformFileFromXFile(x);
      if (pf != null) files.add(pf);
    }
    await _sendPickedFiles(files);
  }

  Future<void> _pickFromCamera() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera);
    if (x == null || !mounted) return;
    final pf = await _platformFileFromXFile(x);
    if (pf != null) await _sendPickedFiles([pf]);
  }

  Future<void> _pickDocuments() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    await _sendPickedFiles(res?.files ?? []);
  }

  void _showAttachmentOptions() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    'Attach',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.onPrimaryContainer,
                    child: const Icon(Icons.photo_library_rounded),
                  ),
                  title: const Text('Photo library'),
                  subtitle: Text(
                    'Images from gallery',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    await _pickFromGallery();
                  },
                ),
                if (!kIsWeb)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: cs.tertiaryContainer,
                      foregroundColor: cs.onTertiaryContainer,
                      child: const Icon(Icons.photo_camera_rounded),
                    ),
                    title: const Text('Camera'),
                    subtitle: Text(
                      'Take a new photo',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (!mounted) return;
                      await _pickFromCamera();
                    },
                  ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: cs.secondaryContainer,
                    foregroundColor: cs.onSecondaryContainer,
                    child: const Icon(Icons.description_rounded),
                  ),
                  title: const Text('Document'),
                  subtitle: Text(
                    'Files of any type',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    await _pickDocuments();
                  },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myUid = fa.FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: _TapSurface(
          onTap: () {
            if (widget.group != null && widget.appState != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupInfoScreen(
                    group: widget.group!,
                    appState: widget.appState!,
                  ),
                ),
              );
            } else if (!widget.isGroup &&
                widget.peerUserId != null &&
                widget.peerUserId!.isNotEmpty &&
                widget.appState != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PersonalChatInfoScreen(
                    peerUserId: widget.peerUserId!,
                    displayName: widget.title,
                    appState: widget.appState!,
                    chatId: widget.chatId,
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          haptic: true,
          child: Row(
            children: [
              Hero(
                tag: widget.group != null
                    ? 'group_${widget.group!.id}'
                    : (widget.peerUserId != null &&
                          widget.peerUserId!.isNotEmpty)
                    ? 'dm_peer_${widget.peerUserId}'
                    : 'chat_detail_${widget.chatId}',
                child: widget.group != null
                    ? _GroupAvatar(group: widget.group!, radius: 16)
                    : const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primary500,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (widget.group != null)
                      Text(
                        '${widget.group!.memberCount} members · Tap for info',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.gray600,
                        ),
                      )
                    else if (!widget.isGroup && widget.peerUserId != null)
                      const Text(
                        'Tap for contact info',
                        style: TextStyle(fontSize: 10, color: AppTheme.gray600),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('chatId', whereIn: _chatIdCandidates.take(10).toList())
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(
                    child: Text(
                      _friendlyFirestoreError(
                        snapshot.error,
                        fallback: 'Something went wrong',
                        indexHint:
                            'Chat index is building. Please try again in a moment.',
                      ),
                    ),
                  );
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty)
                  return Center(
                    child: Text(
                      'No messages yet. Say hello!',
                      style: TextStyle(color: AppTheme.gray400),
                    ),
                  );
                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final senderUid = (d['senderUid'] as String?) ?? '';
                    final isMe = senderUid.isNotEmpty
                        ? (senderUid == myUid)
                        : (d['senderName'] ==
                              (widget.appState?.user.displayName ?? 'Me'));
                    return _buildMessageBubble(docs[i].id, d, isMe);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTheme.borderDark : AppTheme.gray200,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 2),
                    child: IconButton(
                      onPressed: _showAttachmentOptions,
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.standard,
                        fixedSize: const Size(46, 46),
                        backgroundColor: isDark
                            ? cs.surfaceContainerHigh
                            : cs.primaryContainer,
                        foregroundColor: isDark
                            ? cs.primary
                            : cs.onPrimaryContainer,
                        shape: const CircleBorder(),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 26),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : AppTheme.gray100,
                        border: Border.all(
                          color: isDark
                              ? AppTheme.borderDark
                              : AppTheme.gray200,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Message...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white60 : AppTheme.gray600,
                          ),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _openEmojiPicker,
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    color: isDark ? Colors.white70 : AppTheme.gray600,
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(right: 2, bottom: 2),
                    child: Material(
                      color: cs.primary,
                      shape: const CircleBorder(),
                      elevation: 0,
                      child: InkWell(
                        onTap: _handleSend,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 46,
                          height: 46,
                          child: Icon(
                            Icons.send_rounded,
                            color: cs.onPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reactToMessage(String messageId, String emoji) async {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final ref = FirebaseFirestore.instance
          .collection('messages')
          .doc(messageId);
      final snap = await tx.get(ref);
      final data = (snap.data() as Map<String, dynamic>?) ?? {};
      final existingRaw = data['reactionCounts'];
      final existing = <String, int>{};
      if (existingRaw is Map) {
        for (final entry in existingRaw.entries) {
          final key = entry.key.toString();
          final val = entry.value;
          if (val is num) existing[key] = val.toInt();
        }
      }
      existing[emoji] = (existing[emoji] ?? 0) + 1;
      tx.set(ref, {
        'reactionCounts': existing,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  void _rememberRecentEmoji(String emoji) {
    _recentEmojis.remove(emoji);
    _recentEmojis.insert(0, emoji);
    if (_recentEmojis.length > 8) {
      _recentEmojis.removeRange(8, _recentEmojis.length);
    }
  }

  Future<void> _openReactionPicker(
    String messageId,
    Offset globalPosition,
  ) async {
    const emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    final screen = MediaQuery.of(context).size;
    final left = (globalPosition.dx - 130).clamp(8.0, screen.width - 268.0);
    final top = (globalPosition.dy - 58).clamp(40.0, screen.height - 120.0);
    final selection = await showDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(onTap: () => Navigator.pop(ctx)),
          ),
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.white,
              elevation: 8,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: emojis
                      .map(
                        (e) => InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => Navigator.pop(ctx, e),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (selection == null) return;
    _rememberRecentEmoji(selection);
    await _reactToMessage(messageId, selection);
  }

  Widget _reactionRow(Map<String, dynamic> data) {
    final raw = data['reactionCounts'];
    if (raw is! Map || raw.isEmpty) return const SizedBox.shrink();
    final chips = <Widget>[];
    raw.forEach((k, v) {
      final count = v is num ? v.toInt() : 0;
      if (count <= 0) return;
      chips.add(
        Container(
          margin: const EdgeInsets.only(right: 4, top: 5),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.gray100,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.gray200),
          ),
          child: Text('$k $count', style: const TextStyle(fontSize: 11)),
        ),
      );
    });
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(children: chips);
  }

  void _openEmojiPicker() {
    const emojis = [
      '😀',
      '😂',
      '😍',
      '👍',
      '🙏',
      '🎉',
      '🔥',
      '✅',
      '❤️',
      '😎',
      '😭',
      '👏',
      '🤝',
      '😅',
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_recentEmojis.isNotEmpty) ...[
                const Text(
                  'Recent',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gray600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _recentEmojis
                      .map(
                        (e) => _emojiCircle(
                          e,
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() => _ctrl.text = '${_ctrl.text}$e');
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
              ],
              const Text(
                'Emoji',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: emojis
                    .map(
                      (e) => _emojiCircle(
                        e,
                        onTap: () {
                          _rememberRecentEmoji(e);
                          Navigator.pop(ctx);
                          setState(() => _ctrl.text = '${_ctrl.text}$e');
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emojiCircle(String emoji, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.gray100,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.gray200),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildMessageBubble(
    String messageId,
    Map<String, dynamic> data,
    bool isMe,
  ) {
    final text = ((data['text'] as String?) ?? '').trim();
    final messageType = ((data['messageType'] as String?) ?? '')
        .trim()
        .toLowerCase();
    if (messageType == 'file') {
      final fileName = ((data['fileName'] as String?) ?? text).trim();
      final fileUrl = ((data['fileUrl'] as String?) ?? '').trim();
      final mime = ((data['mimeType'] as String?) ?? '').trim().toLowerCase();
      final size = (data['fileSize'] as int?) ?? 0;
      final isImage = mime.startsWith('image/');
      final cs = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final accent = widget.appState?.chatAccentColor ?? cs.primary;
      final bubbleColor = isMe
          ? accent.withValues(alpha: 0.14)
          : (isDark ? const Color(0xFF2A2A2A) : AppTheme.gray100);

      return GestureDetector(
        onLongPressStart: (d) =>
            _openReactionPicker(messageId, d.globalPosition),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isImage && fileUrl.isNotEmpty)
                  _TapSurface(
                    onTap: () => _openAttachmentOptions(
                      fileName: fileName,
                      fileUrl: fileUrl,
                      isImage: true,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        fileUrl,
                        width: 220,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 220,
                          height: 110,
                          color: Colors.black12,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  )
                else
                  _TapSurface(
                    onTap: fileUrl.isNotEmpty
                        ? () => _openAttachmentOptions(
                            fileName: fileName,
                            fileUrl: fileUrl,
                            isImage: false,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    haptic: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insert_drive_file_rounded,
                          size: 18,
                          color: isMe ? accent : AppTheme.gray700,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            fileName.isNotEmpty ? fileName : 'File',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  size > 0 ? _prettyBytes(size) : 'Attachment',
                  style: TextStyle(color: AppTheme.gray600, fontSize: 12),
                ),
                _reactionRow(data),
              ],
            ),
          ),
        ),
      );
    }
    return _buildTextBubble(messageId, data, text, isMe);
  }

  Widget _buildTextBubble(
    String messageId,
    Map<String, dynamic> data,
    String text,
    bool isMe,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.appState?.chatAccentColor ?? cs.primary;
    return GestureDetector(
      onLongPressStart: (d) => _openReactionPicker(messageId, d.globalPosition),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          decoration: BoxDecoration(
            color: isMe
                ? accent
                : (isDark ? const Color(0xFF2A2A2A) : AppTheme.gray100),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : null,
                  fontSize: 15,
                ),
              ),
              _reactionRow(data),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAttachmentOptions({
    required String fileName,
    required String fileUrl,
    required bool isImage,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.fullscreen_rounded),
                title: Text(isImage ? 'View full screen' : 'Open file'),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (isImage) {
                    _openImagePreview(fileName: fileName, fileUrl: fileUrl);
                  } else {
                    await launchUrl(
                      Uri.parse(fileUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('Download / Open externally'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await launchUrl(
                    Uri.parse(fileUrl),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_rounded),
                title: const Text('Copy link'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: fileUrl));
                  Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  void _openImagePreview({required String fileName, required String fileUrl}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(fileName.isEmpty ? 'Image' : fileName),
            actions: [
              IconButton(
                icon: const Icon(Icons.download_rounded),
                onPressed: () async {
                  await launchUrl(
                    Uri.parse(fileUrl),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ],
          ),
          body: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Center(child: Image.network(fileUrl, fit: BoxFit.contain)),
          ),
        ),
      ),
    );
  }

  String _prettyBytes(int b) {
    if (b <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = b.toDouble();
    var u = 0;
    while (size >= 1024 && u < units.length - 1) {
      size /= 1024;
      u++;
    }
    return '${size.toStringAsFixed(u == 0 ? 0 : 1)} ${units[u]}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TODO SCREEN — 2 tabs: Tasks + Completed (Events removed)
// ═══════════════════════════════════════════════════════════════════════════
class TodoScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback onSettings;
  const TodoScreen({
    super.key,
    required this.appState,
    required this.onSettings,
  });
  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (_) => CreateTaskDialog(appState: widget.appState),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        // Tasks tab: only todo + inProgress (NOT done)
        final activeTasks = widget.appState.tasks
            .where((t) => t.status != TaskStatus.done)
            .toList();
        final todoTasks = activeTasks
            .where((t) => t.status == TaskStatus.todo)
            .toList();
        final inProgressTasks = activeTasks
            .where((t) => t.status == TaskStatus.inProgress)
            .toList();
        // Completed tab: only done tasks
        final completedTasks = widget.appState.tasks
            .where((t) => t.status == TaskStatus.done)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Task',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _TapSurface(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccountScreen(appState: widget.appState),
                  ),
                ),
                borderRadius: BorderRadius.circular(999),
                haptic: true,
                child: _UserAvatar(user: widget.appState.user),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: widget.onSettings,
              ),
            ],
            bottom: TabBar(
              controller: _tab,
              labelColor: isDark ? Colors.white : AppTheme.primary600,
              unselectedLabelColor: isDark ? Colors.white70 : AppTheme.gray600,
              indicatorColor: isDark ? Colors.white : AppTheme.primary500,
              tabs: [
                Tab(text: 'Tasks (${activeTasks.length})'),
                Tab(text: 'Completed (${completedTasks.length})'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showCreateTaskDialog,
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            icon: const Icon(Icons.add_task),
            label: const Text('Create Task'),
          ),
          body: TabBarView(
            controller: _tab,
            children: [
              // ── Active Tasks tab ──────────────────────────────────────────
              activeTasks.isEmpty
                  ? _emptyState(
                      Icons.task_alt_rounded,
                      'No tasks yet',
                      'Tap "Create Task" to add one',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      children: [
                        if (todoTasks.isNotEmpty) ...[
                          const _SectionHeader(label: 'TO DO'),
                          ...todoTasks.map(
                            (t) => _TaskDismissible(
                              task: t,
                              appState: widget.appState,
                            ),
                          ),
                        ],
                        if (inProgressTasks.isNotEmpty) ...[
                          const _SectionHeader(label: 'IN PROGRESS'),
                          ...inProgressTasks.map(
                            (t) => _TaskDismissible(
                              task: t,
                              appState: widget.appState,
                            ),
                          ),
                        ],
                      ],
                    ),
              // ── Completed tab ─────────────────────────────────────────────
              completedTasks.isEmpty
                  ? _emptyState(
                      Icons.check_circle_outline,
                      'No completed tasks',
                      'Completed tasks will appear here',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      children: [
                        const _SectionHeader(label: 'COMPLETED'),
                        ...completedTasks.map(
                          (t) => _TaskDismissible(
                            task: t,
                            appState: widget.appState,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppTheme.gray200),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: AppTheme.gray600)),
        ],
      ),
    );
  }
}

class _TaskDismissible extends StatelessWidget {
  final TaskModel task;
  final AppState appState;
  const _TaskDismissible({required this.task, required this.appState});

  @override
  Widget build(BuildContext context) {
    final myUid = fa.FirebaseAuth.instance.currentUser?.uid ?? '';
    final canDelete =
        myUid.isNotEmpty &&
        (task.createdByUid == myUid || task.assignedToUids.contains(myUid));
    return Dismissible(
      key: ValueKey('task_${task.id}'),
      direction: canDelete
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (_) async => canDelete,
      onDismissed: (_) => appState.removeTask(task),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: _TaskCard(task: task, appState: appState),
    );
  }
}

// ── Task Card ─────────────────────────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final AppState appState;
  const _TaskCard({required this.task, required this.appState});

  Color get _priorityColor => task.priority == TaskPriority.low
      ? AppTheme.success
      : task.priority == TaskPriority.high
      ? AppTheme.error
      : AppTheme.warning;
  String get _priorityLabel => task.priority == TaskPriority.low
      ? 'Low'
      : task.priority == TaskPriority.high
      ? 'High'
      : 'Medium';
  Color get _statusColor => task.status == TaskStatus.done
      ? AppTheme.success
      : task.status == TaskStatus.inProgress
      ? AppTheme.info
      : AppTheme.gray600;
  String get _statusLabel => task.status == TaskStatus.done
      ? 'Done'
      : task.status == TaskStatus.inProgress
      ? 'In Progress'
      : 'To Do';

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.gray200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              task.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Assigned to ${task.assignedToNames.isEmpty ? '—' : task.assignedToNames.join(', ')}',
              style: TextStyle(color: AppTheme.gray600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            const Text(
              'Change Status',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                _statusChip(ctx, 'To Do', TaskStatus.todo, AppTheme.gray600),
                _statusChip(
                  ctx,
                  'In Progress',
                  TaskStatus.inProgress,
                  AppTheme.info,
                ),
                _statusChip(
                  ctx,
                  'Completed',
                  TaskStatus.done,
                  AppTheme.success,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Change Priority',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                _priorityChip(ctx, 'Low', TaskPriority.low, AppTheme.success),
                _priorityChip(
                  ctx,
                  'Medium',
                  TaskPriority.medium,
                  AppTheme.warning,
                ),
                _priorityChip(ctx, 'High', TaskPriority.high, AppTheme.error),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(
    BuildContext ctx,
    String label,
    TaskStatus status,
    Color color,
  ) {
    final isActive = task.status == status;
    return _TapSurface(
      onTap: () {
        appState.updateTaskStatus(task.id, status);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(20),
      haptic: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : AppTheme.gray100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? color : AppTheme.gray600,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _priorityChip(
    BuildContext ctx,
    String label,
    TaskPriority priority,
    Color color,
  ) {
    final isActive = task.priority == priority;
    return _TapSurface(
      onTap: () {
        appState.updateTaskPriority(task.id, priority);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(20),
      haptic: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : AppTheme.gray100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? color : AppTheme.gray600,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.done;
    return _TapSurface(
      onTap: () => _showOptionsMenu(context),
      borderRadius: BorderRadius.circular(14),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Tap checkmark to toggle done
                  _TapSurface(
                    onTap: () {
                      _hapticLight();
                      appState.updateTaskStatus(
                        task.id,
                        isDone ? TaskStatus.todo : TaskStatus.done,
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDone ? AppTheme.success : Colors.transparent,
                        border: Border.all(
                          color: isDone ? AppTheme.success : AppTheme.gray400,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isDone
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? AppTheme.gray600 : null,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 34),
                  child: Text(
                    task.description,
                    style: TextStyle(color: AppTheme.gray600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(width: 34),
                  Icon(Icons.person, size: 14, color: AppTheme.gray600),
                  const SizedBox(width: 4),
                  Text(
                    task.assignedToNames.isEmpty
                        ? 'Unassigned'
                        : task.assignedToNames.first,
                    style: TextStyle(fontSize: 12, color: AppTheme.gray600),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _priorityLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: _priorityColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (task.dueDate != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: AppTheme.gray400,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${task.dueDate!.day}/${task.dueDate!.month}',
                      style: TextStyle(fontSize: 11, color: AppTheme.gray400),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CREATE TASK DIALOG
// ═══════════════════════════════════════════════════════════════════════════
class CreateTaskDialog extends StatefulWidget {
  final AppState appState;
  const CreateTaskDialog({super.key, required this.appState});
  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _groupId;
  final List<String> _assigneeUids = [];
  final List<String> _assigneeNames = [];
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  bool _submitted = false;

  bool get _titleError => _submitted && _titleCtrl.text.trim().isEmpty;
  bool get _descError => _submitted && _descCtrl.text.trim().isEmpty;
  bool get _assignError => _submitted && _assigneeUids.isEmpty;

  void _submit() {
    setState(() => _submitted = true);
    if (_titleCtrl.text.trim().isEmpty ||
        _descCtrl.text.trim().isEmpty ||
        _assigneeUids.isEmpty)
      return;
    final myUid = fa.FirebaseAuth.instance.currentUser?.uid ?? '';
    final myName = widget.appState.user.displayName.trim().isNotEmpty
        ? widget.appState.user.displayName.trim()
        : (widget.appState.user.email.trim().isNotEmpty
              ? widget.appState.user.email.trim()
              : 'Me');
    final task = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      assignedToUids: List<String>.from(_assigneeUids),
      assignedToNames: List<String>.from(_assigneeNames),
      priority: _priority,
      status: TaskStatus.todo,
      dueDate: _dueDate,
      groupId: _groupId,
      createdByUid: myUid.isNotEmpty ? myUid : widget.appState.user.uid,
      createdByName: myName,
      createdAt: DateTime.now(),
    );
    widget.appState.addTask(task);
    Navigator.pop(context);
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task created!', style: TextStyle(color: cs.onPrimary)),
        backgroundColor: cs.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final fieldFill = isDark ? AppTheme.surfaceDark : AppTheme.gray50;
    final fieldBorder = isDark ? AppTheme.borderDark : AppTheme.gray200;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppTheme.primary500.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : AppTheme.primary500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.task_alt,
                    color: isDark ? Colors.white : AppTheme.primary500,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Task',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Add a task for your workspace.',
                      style: TextStyle(color: AppTheme.gray600, fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Task Title'),
                  TextField(
                    controller: _titleCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: _inputDecoration(
                      context,
                      'Enter task title',
                      hasError: _titleError,
                      errorText: 'Task title is required',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _label('Description'),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                    decoration: _inputDecoration(
                      context,
                      'Enter task description',
                      hasError: _descError,
                      errorText: 'Description is required',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _label('Assign Members'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: cs.primary,
                    ),
                    title: Text(
                      _assigneeNames.isEmpty
                          ? 'Add assignees'
                          : _assigneeNames.take(2).join(', ') +
                                (_assigneeNames.length > 2
                                    ? ' +${_assigneeNames.length - 2}'
                                    : ''),
                    ),
                    subtitle: _assignError
                        ? const Text(
                            'Required',
                            style: TextStyle(
                              color: AppTheme.error,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.gray600,
                    ),
                    onTap: () async {
                      final result =
                          await showModalBottomSheet<_EventPeoplePick>(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (_) => _EventParticipantsSheet(
                              appState: widget.appState,
                              initialGroupId: _groupId,
                              initiallySelected: _assigneeUids.toSet(),
                            ),
                          );
                      if (result == null) return;
                      setState(() {
                        _groupId = result.groupId;
                        _assigneeUids
                          ..clear()
                          ..addAll(result.selectedUids);
                        _assigneeNames
                          ..clear()
                          ..addAll(
                            result.selectedUids.map(
                              (u) => result.labelsByUid[u] ?? 'User',
                            ),
                          );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _label('Priority'),
                  DropdownButtonFormField<TaskPriority>(
                    initialValue: _priority,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: fieldBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: fieldBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: cs.primary),
                      ),
                      filled: true,
                      fillColor: fieldFill,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: TaskPriority.low,
                        child: Text('Low'),
                      ),
                      DropdownMenuItem(
                        value: TaskPriority.medium,
                        child: Text('Medium'),
                      ),
                      DropdownMenuItem(
                        value: TaskPriority.high,
                        child: Text('High'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                  const SizedBox(height: 16),
                  _label('Due Date'),
                  _TapSurface(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        _hapticLight();
                        setState(() => _dueDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: fieldFill,
                        border: Border.all(color: fieldBorder),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _dueDate == null
                                ? 'Select due date'
                                : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                            style: TextStyle(
                              color: _dueDate == null
                                  ? AppTheme.gray600
                                  : Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.calendar_today_rounded,
                            color: cs.primary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Create Task',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );

  InputDecoration _inputDecoration(
    BuildContext context,
    String hint, {
    bool hasError = false,
    String? errorText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final border = isDark ? AppTheme.borderDark : AppTheme.gray200;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.gray400, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: hasError ? AppTheme.error : border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: hasError ? AppTheme.error : border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: hasError ? AppTheme.error : cs.primary),
      ),
      filled: true,
      fillColor: isDark ? AppTheme.surfaceDark : AppTheme.gray50,
      errorText: hasError ? errorText : null,
      errorStyle: const TextStyle(color: AppTheme.error, fontSize: 11),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SETTINGS SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class SettingsScreen extends StatelessWidget {
  final AppState appState;
  const SettingsScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final isDark = appState.themeMode == ThemeMode.dark;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: ListView(
            children: [
              _TapSurface(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccountScreen(appState: appState),
                  ),
                ),
                borderRadius: BorderRadius.circular(14),
                haptic: true,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _UserAvatar(
                        user: appState.user,
                        radius: 30,
                        emphasized: true,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appState.user.displayName.isEmpty
                                  ? 'My Account'
                                  : appState.user.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              appState.user.email.isEmpty
                                  ? 'Tap to set up'
                                  : appState.user.email,
                              style: const TextStyle(color: AppTheme.gray600),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.gray600),
                    ],
                  ),
                ),
              ),
              const Divider(),
              _tile(
                context,
                icon: Icons.lock_rounded,
                color: AppTheme.primary500,
                title: 'Privacy',
                subtitle: 'Profile, read receipts, blocked',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PrivacySettingsScreen(appState: appState),
                  ),
                ),
              ),
              _tile(
                context,
                icon: Icons.palette_outlined,
                color: Colors.purple,
                title: 'Theme',
                subtitle: isDark ? 'Dark mode' : 'Light mode',
                trailing: Switch(
                  value: isDark,
                  onChanged: (v) =>
                      appState.setTheme(v ? ThemeMode.dark : ThemeMode.light),
                  activeThumbColor: AppTheme.primary500,
                ),
              ),
              _tile(
                context,
                icon: Icons.notifications_rounded,
                color: AppTheme.warning,
                title: 'Notifications',
                subtitle: 'Messages, mentions, tasks',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        NotificationSettingsScreen(appState: appState),
                  ),
                ),
              ),
              _tile(
                context,
                icon: Icons.sync_rounded,
                color: AppTheme.info,
                title: 'Calendar Sync',
                subtitle: appState.hasConnectedCalendarProvider
                    ? 'Google/Outlook connection ready'
                    : 'Connect Google or Outlook calendar',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CalendarSyncSettingsScreen(appState: appState),
                  ),
                ),
              ),
              _tile(
                context,
                icon: Icons.storage_outlined,
                color: Colors.teal,
                title: 'Storage and Data',
                subtitle: 'Network usage, auto-download',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StorageSettingsScreen(),
                  ),
                ),
              ),
              _tile(
                context,
                icon: Icons.help_outline,
                color: AppTheme.success,
                title: 'Help & Feedback',
                subtitle: 'FAQ, contact, privacy policy',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpScreen()),
                ),
              ),
              _tile(
                context,
                icon: Icons.laptop_outlined,
                color: AppTheme.info,
                title: 'Link Devices',
                subtitle: 'Connect up to 4 devices',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LinkDevicesScreen()),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () async {
                    await fa.FirebaseAuth.instance.signOut();
                    appState.user.logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(appState: appState),
                      ),
                      (_) => false,
                    );
                  },
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: AppTheme.error,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.gray600),
      ),
      trailing:
          trailing ?? const Icon(Icons.chevron_right, color: AppTheme.gray600),
      onTap: onTap,
    );
  }
}

class CalendarSyncSettingsScreen extends StatelessWidget {
  final AppState appState;
  const CalendarSyncSettingsScreen({super.key, required this.appState});

  String _formatSyncTime(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Calendar Sync',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.info.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                appState.calendarLastSyncedAt == null
                    ? 'Connect a provider and tap Sync now to exchange events.'
                    : 'Last synced: ${_formatSyncTime(appState.calendarLastSyncedAt!)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 14),
            _providerRow(
              context,
              icon: Icons.g_mobiledata_rounded,
              iconColor: AppTheme.error,
              title: 'Google Calendar',
              connected: appState.googleCalendarConnected,
              onConnect: () async {
                await appState.connectCalendarProvider('google');
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      appState.googleCalendarConnected
                          ? 'Google Calendar connected'
                          : 'Could not connect Google Calendar',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              onDisconnect: () {
                appState.disconnectCalendarProvider('google');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Google Calendar disconnected'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _providerRow(
              context,
              icon: Icons.calendar_view_day_outlined,
              iconColor: AppTheme.primary500,
              title: 'Outlook Calendar',
              connected: appState.outlookCalendarConnected,
              onConnect: () async {
                await appState.connectCalendarProvider('outlook');
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Outlook Calendar connected (coming next)'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              onDisconnect: () {
                appState.disconnectCalendarProvider('outlook');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Outlook Calendar disconnected'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: appState.isCalendarSyncing
                  ? null
                  : () async {
                      final ok = await appState.syncCalendarsNow();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Calendar sync complete'
                                : 'Connect Google or Outlook first',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
              icon: appState.isCalendarSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(
                appState.isCalendarSyncing ? 'Syncing...' : 'Sync now',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _providerRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool connected,
    required Future<void> Function() onConnect,
    required VoidCallback onDisconnect,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  connected ? 'Connected' : 'Not connected',
                  style: TextStyle(
                    fontSize: 12,
                    color: connected ? AppTheme.success : AppTheme.gray600,
                  ),
                ),
              ],
            ),
          ),
          connected
              ? OutlinedButton(
                  onPressed: onDisconnect,
                  child: const Text('Disconnect'),
                )
              : FilledButton(
                  onPressed: onConnect,
                  child: const Text('Connect'),
                ),
        ],
      ),
    );
  }
}

// ── Privacy Settings ──────────────────────────────────────────────────────────
class PrivacySettingsScreen extends StatelessWidget {
  final AppState appState;
  const PrivacySettingsScreen({super.key, required this.appState});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Privacy',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          children: [
            const _SectionHeader(label: 'VISIBILITY'),
            SwitchListTile(
              title: const Text('Private Profile'),
              subtitle: const Text('Only contacts can see your info'),
              value: appState.privateProfile,
              onChanged: (v) => appState.toggle('private', v),
              activeThumbColor: AppTheme.primary500,
            ),
            SwitchListTile(
              title: const Text('Read Receipts'),
              subtitle: const Text("Show ticks when you've read messages"),
              value: appState.readReceipts,
              onChanged: (v) => appState.toggle('receipts', v),
              activeThumbColor: AppTheme.primary500,
            ),
            const _SectionHeader(label: 'OTHER'),
            ListTile(
              title: const Text('Last Seen'),
              subtitle: const Text('Everyone'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              title: const Text('Blocked Contacts'),
              subtitle: const Text('0 contacts blocked'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notification Settings ─────────────────────────────────────────────────────
class NotificationSettingsScreen extends StatelessWidget {
  final AppState appState;
  const NotificationSettingsScreen({super.key, required this.appState});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Notifications',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          children: [
            SwitchListTile(
              title: const Text('Enable All Notifications'),
              value: appState.notificationsEnabled,
              onChanged: (v) => appState.toggle('notifications', v),
              activeThumbColor: AppTheme.primary500,
            ),
            const Divider(),
            const _SectionHeader(label: 'ALERT TYPES'),
            SwitchListTile(
              title: const Text('Task Reminders'),
              value: appState.taskReminders,
              onChanged: appState.notificationsEnabled
                  ? (v) => appState.toggle('taskReminders', v)
                  : null,
              activeThumbColor: AppTheme.primary500,
            ),
            SwitchListTile(
              title: const Text('Workspace Messages'),
              value: appState.groupMessages,
              onChanged: appState.notificationsEnabled
                  ? (v) => appState.toggle('groupMessages', v)
                  : null,
              activeThumbColor: AppTheme.primary500,
            ),
            SwitchListTile(
              title: const Text('@Mentions'),
              value: appState.mentionAlerts,
              onChanged: appState.notificationsEnabled
                  ? (v) => appState.toggle('mentions', v)
                  : null,
              activeThumbColor: AppTheme.primary500,
            ),
            const Divider(),
            const _SectionHeader(label: 'SOUND & VIBRATION'),
            SwitchListTile(
              title: const Text('Sound'),
              value: appState.soundEnabled,
              onChanged: appState.notificationsEnabled
                  ? (v) => appState.toggle('sound', v)
                  : null,
              activeThumbColor: AppTheme.primary500,
            ),
            SwitchListTile(
              title: const Text('Vibrate'),
              value: appState.vibrateEnabled,
              onChanged: appState.notificationsEnabled
                  ? (v) => appState.toggle('vibrate', v)
                  : null,
              activeThumbColor: AppTheme.primary500,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Storage Settings ──────────────────────────────────────────────────────────
class StorageSettingsScreen extends StatelessWidget {
  const StorageSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Storage and Data',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Storage Used',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.35,
                      minHeight: 8,
                      backgroundColor: AppTheme.gray200,
                      color: AppTheme.primary500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '350 MB used',
                        style: TextStyle(color: AppTheme.gray600, fontSize: 13),
                      ),
                      Text(
                        '1 GB total',
                        style: TextStyle(color: AppTheme.gray600, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Auto-Download Media'),
            subtitle: const Text('Wi-Fi only'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Media Visibility'),
            subtitle: const Text('Visible in gallery'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Clear Cache'),
            subtitle: const Text('Free up 42 MB'),
            trailing: const Icon(Icons.delete_outline, color: AppTheme.error),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cache cleared'),
                behavior: SnackBarBehavior.floating,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Help Screen ───────────────────────────────────────────────────────────────
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.help_outline,
        AppTheme.primary500,
        'FAQ',
        'Common questions answered',
      ),
      (
        Icons.contact_support_outlined,
        AppTheme.info,
        'Contact Us',
        'Reach our support team',
      ),
      (
        Icons.privacy_tip_outlined,
        AppTheme.success,
        'Privacy Policy',
        'How we handle your data',
      ),
      (
        Icons.feedback_outlined,
        AppTheme.warning,
        'Send Feedback',
        'Help us improve TaskMate',
      ),
      (Icons.info_outline, AppTheme.gray600, 'App Version', 'TaskMate v1.0.0'),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Feedback',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 64),
        itemBuilder: (_, i) => ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: items[i].$2.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(items[i].$1, color: items[i].$2, size: 20),
          ),
          title: Text(items[i].$3),
          subtitle: Text(items[i].$4, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, color: AppTheme.gray600),
          onTap: () {},
        ),
      ),
    );
  }
}

// ── Link Devices Screen ───────────────────────────────────────────────────────
class LinkDevicesScreen extends StatelessWidget {
  const LinkDevicesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Link Devices',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.laptop_mac_outlined,
                size: 72,
                color: AppTheme.gray400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Link your laptop',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Open TaskMate on your laptop and scan the QR code to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.gray600),
              ),
              const SizedBox(height: 36),
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.gray200, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.qr_code_2,
                  size: 140,
                  color: AppTheme.gray400,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Link a Device'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary500,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '0 of 4 devices linked',
                style: TextStyle(color: AppTheme.gray600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CALENDAR SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class CalendarScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback onSettings;
  const CalendarScreen({
    super.key,
    required this.appState,
    required this.onSettings,
  });
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focus = DateTime.now();
  DateTime? _selected;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  int get _startWeekday => DateTime(_focus.year, _focus.month, 1).weekday % 7;
  int get _daysInMonth => DateTime(_focus.year, _focus.month + 1, 0).day;

  List<AppEvent> _eventsOn(DateTime d) => widget.appState.events
      .where(
        (e) =>
            e.date.year == d.year &&
            e.date.month == d.month &&
            e.date.day == d.day,
      )
      .toList();

  void _showAddDialog([DateTime? day]) {
    final target = day ?? _selected ?? DateTime.now();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          CreateEventDialog(appState: widget.appState, initialDay: target),
    );
  }

  Future<void> _openQuickReminder(DateTime day) async {
    final titleCtrl = TextEditingController();
    String? selectedGroupId = widget.appState.groups.isNotEmpty
        ? widget.appState.groups.first.id
        : null;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick reminder',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Reminder title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (widget.appState.groups.isNotEmpty)
                      DropdownButtonFormField<String?>(
                        initialValue: selectedGroupId,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Only me'),
                          ),
                          ...widget.appState.groups.map(
                            (g) => DropdownMenuItem<String?>(
                              value: g.id,
                              child: Text(g.name),
                            ),
                          ),
                        ],
                        onChanged: (val) => setSheetState(() {
                          selectedGroupId = val;
                        }),
                        decoration: InputDecoration(
                          labelText: 'Notify',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) return;
                              final myUid =
                                  fa.FirebaseAuth.instance.currentUser?.uid ??
                                  widget.appState.user.uid;
                              final selectedGroup = selectedGroupId == null
                                  ? null
                                  : widget.appState.groups.firstWhere(
                                      (g) => g.id == selectedGroupId,
                                      orElse: () =>
                                          widget.appState.groups.first,
                                    );
                              final participants = <String>{
                                if (myUid.isNotEmpty) myUid,
                                if (selectedGroup != null)
                                  ...selectedGroup.members
                                      .map((m) => m.userId)
                                      .whereType<String>()
                                      .where((uid) => uid.trim().isNotEmpty),
                              };
                              final eventId =
                                  'evt_${DateTime.now().millisecondsSinceEpoch}_${myUid.isEmpty ? 'anon' : myUid.substring(0, 6)}';
                              final reminderStart = DateTime(
                                day.year,
                                day.month,
                                day.day,
                                9,
                              );
                              widget.appState.addEvent(
                                AppEvent(
                                  id: eventId,
                                  title: title,
                                  description: selectedGroup == null
                                      ? 'Personal reminder'
                                      : 'Reminder for ${selectedGroup.name}',
                                  start: reminderStart,
                                  end: reminderStart.add(
                                    const Duration(minutes: 15),
                                  ),
                                  allDay: false,
                                  groupId: selectedGroup?.id,
                                  participantUids: participants.toList(),
                                  createdByUid: myUid,
                                  isReminder: true,
                                  color: AppTheme.warning,
                                ),
                              );
                              Navigator.pop(ctx, true);
                            },
                            child: const Text('Create'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (!mounted || created != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder created'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final today = DateTime.now();
        final cs = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Calendar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _TapSurface(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccountScreen(appState: widget.appState),
                  ),
                ),
                borderRadius: BorderRadius.circular(999),
                haptic: true,
                child: _UserAvatar(user: widget.appState.user),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => setState(() {
                  _focus = DateTime.now();
                  _selected = today;
                }),
                child: const Text(
                  'Today',
                  style: TextStyle(color: AppTheme.primary500),
                ),
              ),
              TextButton.icon(
                onPressed: widget.appState.isCalendarSyncing
                    ? null
                    : () async {
                        final ok = await widget.appState.syncCalendarsNow();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Calendar sync complete'
                                  : 'Connect Google or Outlook first',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                icon: widget.appState.isCalendarSyncing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded, size: 16),
                label: Text(
                  widget.appState.isCalendarSyncing ? 'Syncing...' : 'Sync',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary500,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: widget.onSettings,
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(
                        () => _focus = DateTime(_focus.year, _focus.month - 1),
                      ),
                    ),
                    Text(
                      '${_months[_focus.month - 1]} ${_focus.year}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setState(
                        () => _focus = DateTime(_focus.year, _focus.month + 1),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: _days
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: d == 'Sun'
                                    ? AppTheme.error
                                    : AppTheme.gray600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                    childAspectRatio: 0.80,
                  ),
                  itemCount: _startWeekday + _daysInMonth,
                  itemBuilder: (_, index) {
                    if (index < _startWeekday) return const SizedBox();
                    final day = index - _startWeekday + 1;
                    final date = DateTime(_focus.year, _focus.month, day);
                    final isToday =
                        date.day == today.day &&
                        date.month == today.month &&
                        date.year == today.year;
                    final isSelected =
                        _selected != null &&
                        date.day == _selected!.day &&
                        date.month == _selected!.month &&
                        date.year == _selected!.year;
                    final evts = _eventsOn(date);
                    // Also show group deadlines
                    final deadlines = widget.appState.groups
                        .where(
                          (g) =>
                              g.deadline != null &&
                              g.deadline!.year == date.year &&
                              g.deadline!.month == date.month &&
                              g.deadline!.day == date.day,
                        )
                        .toList();
                    return InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        _hapticLight();
                        setState(() => _selected = date);
                      },
                      onLongPress: () {
                        _hapticLight();
                        setState(() => _selected = date);
                        _showAddDialog(date);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cs.primary
                                  : isToday
                                  ? cs.primary.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isToday || isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : isToday
                                      ? cs.primary
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ...evts
                                  .take(2)
                                  .map(
                                    (e) => Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: e.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              if (deadlines.isNotEmpty)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.warning,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          if (evts.isEmpty && deadlines.isEmpty)
                            const SizedBox(height: 5),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Divider(height: 1, color: AppTheme.gray200),
              Expanded(
                child: _selected == null
                    ? Center(
                        child: Text(
                          'Tap a day to see events',
                          style: TextStyle(color: AppTheme.gray400),
                        ),
                      )
                    : _DayEventsList(
                        day: _selected!,
                        monthName: _months[_selected!.month - 1],
                        appState: widget.appState,
                        onAdd: () => _showAddDialog(_selected),
                        onReminder: () => _openQuickReminder(_selected!),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayEventsList extends StatelessWidget {
  final DateTime day;
  final String monthName;
  final AppState appState;
  final VoidCallback onAdd;
  final VoidCallback onReminder;
  const _DayEventsList({
    required this.day,
    required this.monthName,
    required this.appState,
    required this.onAdd,
    required this.onReminder,
  });

  @override
  Widget build(BuildContext context) {
    final myUid = fa.FirebaseAuth.instance.currentUser?.uid ?? '';
    final evts = appState.events
        .where(
          (e) =>
              e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day,
        )
        .toList();
    final deadlineGroups = appState.groups
        .where(
          (g) =>
              g.deadline != null &&
              g.deadline!.year == day.year &&
              g.deadline!.month == day.month &&
              g.deadline!.day == day.day,
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Text(
                '$monthName ${day.day}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary500,
                ),
              ),
              TextButton.icon(
                onPressed: onReminder,
                icon: const Icon(Icons.alarm_add_rounded, size: 18),
                label: const Text('Reminder'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.warning),
              ),
            ],
          ),
        ),
        Expanded(
          child: evts.isEmpty && deadlineGroups.isEmpty
              ? Center(
                  child: Text(
                    'No events — long-press a day or tap Add',
                    style: TextStyle(color: AppTheme.gray400, fontSize: 13),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    ...deadlineGroups.map(
                      (g) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                decoration: const BoxDecoration(
                                  color: AppTheme.warning,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.timer,
                                        color: AppTheme.warning,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Deadline: ${g.name}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const Text(
                                              'Workspace deadline',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.gray600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ...evts.map((e) {
                      final canDelete =
                          myUid.isNotEmpty &&
                          (e.createdByUid == myUid ||
                              e.participantUids.contains(myUid));
                      return Dismissible(
                        key: ValueKey(e.id),
                        direction: canDelete
                            ? DismissDirection.endToStart
                            : DismissDirection.none,
                        confirmDismiss: (_) async => canDelete,
                        onDismissed: (_) => appState.removeEvent(e),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  decoration: BoxDecoration(
                                    color: e.color,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                e.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            if (e.isReminder)
                                              const Icon(
                                                Icons.alarm,
                                                size: 16,
                                                color: AppTheme.warning,
                                              ),
                                          ],
                                        ),
                                        if (e.description != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            e.description!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.gray600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ],
    );
  }
}

class CreateEventDialog extends StatefulWidget {
  final AppState appState;
  final DateTime initialDay;
  const CreateEventDialog({
    super.key,
    required this.appState,
    required this.initialDay,
  });

  @override
  State<CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<CreateEventDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _allDay = false;
  DateTime? _start;
  DateTime? _end;
  String? _groupId;
  final List<String> _participantUids = [];
  final Map<String, String> _participantLabels = {};
  bool _submitted = false;

  bool get _titleError => _submitted && _titleCtrl.text.trim().isEmpty;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDay;
    _start = DateTime(d.year, d.month, d.day, 10, 0);
    _end = _start!.add(const Duration(minutes: 30));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) {
    final months = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day} ${months[d.month - 1]} ${d.year}, $h:${d.minute.toString().padLeft(2, '0')} $ampm';
  }

  Future<void> _pickStart() async {
    final current = _start ?? widget.initialDay;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    if (_allDay) {
      setState(() {
        _start = DateTime(date.year, date.month, date.day);
        _end = _start!.add(const Duration(days: 1));
      });
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    setState(() {
      _start = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if ((_end ?? _start!).isBefore(_start!)) {
        _end = _start!.add(const Duration(minutes: 30));
      }
    });
  }

  Future<void> _pickEnd() async {
    final current = _end ?? (_start ?? widget.initialDay);
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    if (_allDay) {
      setState(
        () => _end = DateTime(
          date.year,
          date.month,
          date.day,
        ).add(const Duration(days: 1)),
      );
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    setState(
      () => _end = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  void _save() {
    setState(() => _submitted = true);
    if (_titleCtrl.text.trim().isEmpty) return;
    final start = _start ?? widget.initialDay;
    final end = _end ?? start.add(const Duration(minutes: 30));
    final myUid = fa.FirebaseAuth.instance.currentUser?.uid ?? '';
    final createdBy = myUid.isNotEmpty ? myUid : widget.appState.user.uid;
    final eventId =
        'evt_${DateTime.now().millisecondsSinceEpoch}_${createdBy.isEmpty ? 'anon' : createdBy.substring(0, 6)}';
    widget.appState.addEvent(
      AppEvent(
        id: eventId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        start: start,
        end: end,
        allDay: _allDay,
        groupId: _groupId,
        participantUids: _participantUids,
        createdByUid: createdBy,
        color: AppTheme.primary500,
      ),
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event created'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primary500.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event_rounded,
                    color: AppTheme.primary500,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Event',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Create an event for your calendar.',
                        style: TextStyle(color: AppTheme.gray600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Event Title'),
                  TextField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      hintText: 'Enter event title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: _titleError ? 'Title is required' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _FieldLabel('Description'),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter event description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _allDay,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() {
                      _allDay = v;
                      final s = _start ?? widget.initialDay;
                      if (v) {
                        _start = DateTime(s.year, s.month, s.day);
                        _end = _start!.add(const Duration(days: 1));
                      } else {
                        _start = DateTime(s.year, s.month, s.day, 10, 0);
                        _end = _start!.add(const Duration(minutes: 30));
                      }
                    }),
                    title: const Text('All day'),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Starts'),
                    subtitle: Text(_fmtDate(_start ?? widget.initialDay)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickStart,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('Ends'),
                    subtitle: Text(_fmtDate(_end ?? widget.initialDay)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickEnd,
                  ),
                  const SizedBox(height: 8),
                  if (widget.appState.groups.isNotEmpty) ...[
                    DropdownButtonFormField<String?>(
                      initialValue: _groupId,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Personal event'),
                        ),
                        ...widget.appState.groups.map(
                          (g) => DropdownMenuItem<String?>(
                            value: g.id,
                            child: Text(g.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _groupId = v),
                      decoration: InputDecoration(
                        labelText: 'Workspace',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.group_add_outlined),
                    title: const Text('Add participants'),
                    subtitle: _participantUids.isEmpty
                        ? const Text('Optional')
                        : Text(
                            _participantUids
                                    .map((u) => _participantLabels[u] ?? 'User')
                                    .take(2)
                                    .join(', ') +
                                (_participantUids.length > 2
                                    ? ' +${_participantUids.length - 2}'
                                    : ''),
                          ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final result =
                          await showModalBottomSheet<_EventPeoplePick>(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (_) => _EventParticipantsSheet(
                              appState: widget.appState,
                              initialGroupId: _groupId,
                              initiallySelected: _participantUids.toSet(),
                            ),
                          );
                      if (result == null) return;
                      setState(() {
                        _groupId = result.groupId;
                        _participantUids
                          ..clear()
                          ..addAll(result.selectedUids);
                        _participantLabels
                          ..clear()
                          ..addAll(result.labelsByUid);
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Create Event'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CREATE EVENT (Teams-like)
// ═══════════════════════════════════════════════════════════════════════════
class CreateEventScreen extends StatefulWidget {
  final AppState appState;
  final DateTime initialDay;
  const CreateEventScreen({
    super.key,
    required this.appState,
    required this.initialDay,
  });

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  static const Duration _defaultEventDuration = Duration(minutes: 30);
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _allDay = false;
  DateTime? _start;
  DateTime? _end;
  String? _location;
  bool _busy = true;
  String? _groupId;
  final List<String> _participantUids = [];
  final Map<String, String> _participantLabels = {};

  DateTime get _effectiveStart => _start ?? widget.initialDay;
  DateTime get _effectiveEnd =>
      _end ?? _effectiveStart.add(_defaultEventDuration);

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _participantPreviewText() {
    final labels = _participantUids
        .map((uid) => _participantLabels[uid] ?? 'User')
        .take(2)
        .join(', ');
    final extraCount = _participantUids.length - 2;
    if (extraCount > 0) return '$labels +$extraCount';
    return labels;
  }

  String _fmtDateOnly(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  void initState() {
    super.initState();
    final d = widget.initialDay;
    final base = DateTime(d.year, d.month, d.day, d.hour, d.minute);
    _start = base;
    _end = base.add(_defaultEventDuration);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final current = _effectiveStart;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!mounted) return;
    if (_allDay) {
      setState(() {
        _start = _dateOnly(date);
        _end = _dateOnly(date).add(const Duration(days: 1));
      });
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    setState(() {
      final pickedStart = _combineDateAndTime(date, time);
      _start = pickedStart;
      final candidateEnd = _end ?? pickedStart.add(_defaultEventDuration);
      if (candidateEnd.isBefore(pickedStart)) {
        _end = pickedStart.add(_defaultEventDuration);
      }
    });
  }

  Future<void> _pickEnd() async {
    final current = _effectiveEnd;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!mounted) return;
    if (_allDay) {
      setState(() {
        _end = _dateOnly(date).add(const Duration(days: 1));
      });
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    setState(() => _end = _combineDateAndTime(date, time));
  }

  String _fmtDateTime(DateTime d) {
    final months = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'pm' : 'am';
    return '${d.day} ${months[d.month - 1]} at $h:${d.minute.toString().padLeft(2, '0')} $ampm';
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final start = _effectiveStart;
    final end = _effectiveEnd;
    final description = _descCtrl.text.trim();
    final location = _location?.trim() ?? '';
    final myUid = fa.FirebaseAuth.instance.currentUser?.uid ?? '';
    final createdBy = myUid.isNotEmpty ? myUid : (widget.appState.user.uid);
    final eventId =
        'evt_${DateTime.now().millisecondsSinceEpoch}_${createdBy.isEmpty ? 'anon' : createdBy.substring(0, 6)}';
    widget.appState.addEvent(
      AppEvent(
        id: eventId,
        title: title,
        description: description.isEmpty ? null : description,
        start: start,
        end: end,
        allDay: _allDay,
        location: location.isEmpty ? null : location,
        groupId: _groupId,
        participantUids: _participantUids,
        createdByUid: createdBy,
        isReminder: false,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final start = _effectiveStart;
    final end = _effectiveEnd;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New event',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: cs.onSurface),
          child: const Text('Cancel'),
        ),
        leadingWidth: 86,
        actions: [
          TextButton(
            onPressed: _save,
            style: TextButton.styleFrom(foregroundColor: cs.onSurface),
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.edit_rounded, color: cs.onSurfaceVariant),
            title: TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: 'Add title',
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.person_add_alt_1_rounded,
              color: cs.onSurfaceVariant,
            ),
            title: const Text('Add participants'),
            subtitle: _participantUids.isEmpty
                ? null
                : Text(
                    _participantPreviewText(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.gray600),
            onTap: () async {
              final result = await showModalBottomSheet<_EventPeoplePick>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => _EventParticipantsSheet(
                  appState: widget.appState,
                  initialGroupId: _groupId,
                  initiallySelected: _participantUids.toSet(),
                ),
              );
              if (result == null) return;
              setState(() {
                _groupId = result.groupId;
                _participantUids
                  ..clear()
                  ..addAll(result.selectedUids);
                _participantLabels
                  ..clear()
                  ..addAll(result.labelsByUid);
              });
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.share_rounded, color: cs.onSurfaceVariant),
            title: const Text('Share to a channel'),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.gray600),
            onTap: () {},
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: _allDay,
            onChanged: (v) => setState(() {
              _allDay = v;
              if (_allDay) {
                final d = _dateOnly(start);
                _start = d;
                _end = d.add(const Duration(days: 1));
              } else {
                final d = DateTime(start.year, start.month, start.day, 10, 0);
                _start = d;
                _end = d.add(const Duration(minutes: 30));
              }
            }),
            title: const Text('All day'),
            secondary: Icon(Icons.schedule_rounded, color: cs.onSurfaceVariant),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.play_arrow_rounded, color: cs.onSurfaceVariant),
            title: const Text('Start'),
            trailing: Text(
              _allDay ? _fmtDateOnly(start) : _fmtDateTime(start),
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            onTap: _pickStart,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.stop_rounded, color: cs.onSurfaceVariant),
            title: const Text('End'),
            trailing: Text(
              _allDay ? _fmtDateOnly(end) : _fmtDateTime(end),
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            onTap: _pickEnd,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.repeat_rounded, color: cs.onSurfaceVariant),
            title: const Text('Repeat'),
            trailing: Text(
              'Never',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.location_on_rounded,
              color: cs.onSurfaceVariant,
            ),
            title: const Text('Location'),
            subtitle: _location == null
                ? null
                : Text(
                    _location!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.gray600),
            onTap: () async {
              final ctrl = TextEditingController(text: _location ?? '');
              final result = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Location'),
                  content: TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(hintText: 'Add location'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, ctrl.text),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
              if (result == null) return;
              setState(() => _location = result.trim());
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.visibility_rounded, color: cs.onSurfaceVariant),
            title: const Text('Show as'),
            trailing: Text(
              _busy ? 'Busy' : 'Free',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            onTap: () => setState(() => _busy = !_busy),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.notes_rounded, color: cs.onSurfaceVariant),
            title: TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                hintText: 'Description',
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventPeoplePick {
  final String? groupId;
  final List<String> selectedUids;
  final Map<String, String> labelsByUid;
  const _EventPeoplePick({
    required this.groupId,
    required this.selectedUids,
    required this.labelsByUid,
  });
}

class _EventParticipantsSheet extends StatefulWidget {
  final AppState appState;
  final String? initialGroupId;
  final Set<String> initiallySelected;
  const _EventParticipantsSheet({
    required this.appState,
    required this.initialGroupId,
    required this.initiallySelected,
  });

  @override
  State<_EventParticipantsSheet> createState() =>
      _EventParticipantsSheetState();
}

class _EventParticipantsSheetState extends State<_EventParticipantsSheet> {
  String? _groupId;
  late Set<String> _selected;

  GroupModel? _selectedGroup(List<GroupModel> groups) {
    if (_groupId == null || groups.isEmpty) return null;
    for (final group in groups) {
      if (group.id == _groupId) return group;
    }
    return groups.first;
  }

  List<GroupMember> _taskMateMembers(GroupModel? group) {
    return (group?.members ?? const <GroupMember>[])
        .where((member) => (member.userId ?? '').isNotEmpty)
        .toList();
  }

  Map<String, String> _buildUserLabels(List<GroupModel> groups) {
    final labels = <String, String>{};
    for (final group in groups) {
      for (final member in group.members) {
        final uid = (member.userId ?? '').trim();
        if (uid.isEmpty) continue;
        labels[uid] = member.name.trim().isNotEmpty ? member.name.trim() : uid;
      }
    }
    return labels;
  }

  @override
  void initState() {
    super.initState();
    _groupId =
        widget.initialGroupId ??
        (widget.appState.groups.isNotEmpty
            ? widget.appState.groups.first.id
            : null);
    _selected = {...widget.initiallySelected};
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final groups = widget.appState.groups;
    final group = _selectedGroup(groups);
    // Only real TaskMate users have a uid (member.userId).
    final members = _taskMateMembers(group);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.gray200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      'Participants',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        final labels = _buildUserLabels(groups);
                        Navigator.pop(
                          context,
                          _EventPeoplePick(
                            groupId: _groupId,
                            selectedUids: _selected.toList(),
                            labelsByUid: labels,
                          ),
                        );
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              if (groups.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    initialValue: _groupId,
                    decoration: InputDecoration(
                      labelText: 'From workspace',
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                    items: groups
                        .map(
                          (g) => DropdownMenuItem(
                            value: g.id,
                            child: Text(g.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _groupId = v),
                  ),
                ),
              const SizedBox(height: 10),
              Expanded(
                child: groups.isEmpty
                    ? Center(
                        child: Text(
                          'Create a workspace first',
                          style: TextStyle(color: AppTheme.gray600),
                        ),
                      )
                    : members.isEmpty
                    ? Center(
                        child: Text(
                          'No TaskMate users in this workspace yet',
                          style: TextStyle(color: AppTheme.gray600),
                        ),
                      )
                    : ListView.separated(
                        itemCount: members.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final m = members[i];
                          final uid = (m.userId ?? '').trim();
                          final checked = _selected.contains(uid);
                          return CheckboxListTile(
                            value: checked,
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _selected.add(uid);
                              } else {
                                _selected.remove(uid);
                              }
                            }),
                            title: Text(m.name.isNotEmpty ? m.name : 'User'),
                            subtitle: Text(
                              m.phone,
                              style: TextStyle(
                                color: AppTheme.gray600,
                                fontSize: 12,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: cs.primary,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 0, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.gray600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppTheme.gray600,
      ),
    ),
  );
}

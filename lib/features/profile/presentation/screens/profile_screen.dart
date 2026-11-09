import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amarnath_enterprise_client_app/core/notifications/notification_service.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/models/client_model.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:amarnath_enterprise_client_app/features/home/presentation/widgets/client_bottom_navigation_bar.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/screens/change_password_screen.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/screens/my_details_screen.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/widgets/green_wave_header.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/widgets/logout_progress_dialog.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/widgets/profile_illustrations.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/widgets/profile_info_card.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/widgets/profile_option_card.dart';

/// Amarnath Enterprise Client App Profile Screen matching the exact reference design.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.authRepository,
    this.initialProfile,
    this.embedded = false,
    this.onNavigateToTab,
    this.onSignOut,
  });

  final AuthRepository? authRepository;
  final ClientModel? initialProfile;
  final bool embedded;
  final ValueChanged<int>? onNavigateToTab;
  final VoidCallback? onSignOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthRepository _authRepository;
  ClientModel? _clientProfile;

  bool _isLoggingOut = false;
  bool _isProgressDialogShowing = false;
  DialogRoute<void>? _progressDialogRoute;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepositoryImpl();
    _clientProfile = widget.initialProfile;

    if (_clientProfile == null) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _authRepository.getCurrentClientProfile();
      if (mounted) {
        setState(() {
          _clientProfile = profile;
        });
      }
    } catch (_) {}
  }

  void _showProgressDialog() {
    if (_isProgressDialogShowing) return;
    _isProgressDialogShowing = true;
    final nav = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      barrierColor: Colors.transparent,
      builder: (dialogCtx) => const LogoutProgressDialog(),
    );
    _progressDialogRoute = route;
    nav.push(route).then((_) {
      if (_progressDialogRoute == route) {
        _progressDialogRoute = null;
        _isProgressDialogShowing = false;
      }
    });
  }

  void _dismissProgressDialog() {
    if (_isProgressDialogShowing) {
      _isProgressDialogShowing = false;
      final route = _progressDialogRoute;
      _progressDialogRoute = null;
      if (route != null && route.isActive) {
        route.navigator?.removeRoute(route);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFFD91F1F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16.dp),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.dp),
        ),
        title: Text(
          'Logout',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111111),
          ),
        ),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(
            fontSize: 13.sp,
            color: const Color(0xFF454545),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF737D86),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD91F1F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.dp),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.dp, vertical: 8.dp),
              elevation: 0,
            ),
            child: Text(
              'Logout',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    _showProgressDialog();

    try {
      // 1. Unregister/remove current Client FCM token while user is still authenticated
      try {
        await NotificationService.instance.unregisterCurrentClientToken();
      } catch (fcmError) {
        debugPrint('Failed to unregister FCM token during logout: $fcmError');
        // Policy: continue attempting Firebase sign-out even if FCM token removal fails
      }

      // 2. Sign out from Firebase Authentication & repository
      await _authRepository.signOut();

      // 3. Invoke custom onSignOut callback if provided (e.g. for testing / custom handlers)
      if (widget.onSignOut != null) {
        widget.onSignOut!();
      }

      // 4. Dismiss progress dialog
      _dismissProgressDialog();

      // 5. Navigate to Login screen and clear the authenticated navigation stack
      if (!mounted) return;
      if (widget.onSignOut == null) {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (error) {
      _dismissProgressDialog();
      debugPrint('Logout error: $error');
      _showErrorSnackBar('Failed to log out: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _navigateToMyDetails() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MyDetailsScreen(
          initialProfile: _clientProfile,
          authRepository: _authRepository,
        ),
      ),
    );

    if (updated == true && mounted) {
      _loadProfile();
    }
  }

  void _navigateToChangePassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangePasswordScreen(
          authRepository: _authRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _clientProfile?.name.trim().isNotEmpty == true
        ? _clientProfile!.name.trim()
        : 'Ramesh Patel';
    final shop = _clientProfile?.companyName.trim().isNotEmpty == true
        ? _clientProfile!.companyName.trim()
        : 'Patel Hardware';
    final mobile = _clientProfile?.mobile.trim().isNotEmpty == true
        ? _clientProfile!.mobile.trim()
        : '9876543210';

    final content = Scaffold(
      backgroundColor: const Color(0xFFF5FAF7),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ==========================================
            // 1. & 2. Green Wave Header & Overlapping Profile Card
            // ==========================================
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Top Green Wave Header
                const GreenWaveHeader(title: 'Profile'),

                // Overlapping Profile Card (pushed down by 105dp to overlap wave)
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 72.dp,
                  ),
                  child: ProfileInfoCard(
                    name: name,
                    shopName: shop,
                    mobile: mobile,
                    onEditProfile: _navigateToMyDetails,
                  ),
                ),
              ],
            ),

            SizedBox(height: 18.dp),

            // ==========================================
            // 3. My Details Card
            // ==========================================
            ProfileOptionCard(
              icon: Icons.person_outline_rounded,
              title: 'My Details',
              subtitle:
                  'View and update your profile,\nbusiness address and other information',
              illustration: const StorefrontIllustration(),
              onTap: _navigateToMyDetails,
            ),

            SizedBox(height: 4.dp),

            // ==========================================
            // 4. Change Password Card
            // ==========================================
            ProfileOptionCard(
              icon: Icons.lock_outline_rounded,
              title: 'Change Password',
              subtitle: 'Update your account password',
              illustration: const ShieldLockIllustration(),
              onTap: _navigateToChangePassword,
            ),

            SizedBox(height: 18.dp),

            // ==========================================
            // 5. Logout Button
            // ==========================================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.dp),
              child: InkWell(
                onTap: _isLoggingOut ? null : _handleLogout,
                borderRadius: BorderRadius.circular(16.dp),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 13.dp),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(16.dp),
                    border: Border.all(
                      color: const Color(0xFFFFC5C8),
                      width: 1.dp,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 22.dp,
                        color: const Color(0xFFD91F1F),
                      ),
                      SizedBox(width: 8.dp),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD91F1F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 32.dp),
          ],
        ),
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : ClientBottomNavigationBar(
              currentIndex: 3,
              onTap: (index) {
                if (widget.onNavigateToTab != null) {
                  widget.onNavigateToTab!(index);
                } else if (index != 3) {
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              },
            ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: content,
    );
  }
}

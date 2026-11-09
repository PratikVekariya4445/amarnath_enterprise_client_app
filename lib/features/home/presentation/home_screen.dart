import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amarnath_enterprise_client_app/core/theme/app_colors.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/models/client_model.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:amarnath_enterprise_client_app/features/home/presentation/widgets/client_bottom_navigation_bar.dart';
import 'package:amarnath_enterprise_client_app/features/home/presentation/widgets/home_header.dart';
import 'package:amarnath_enterprise_client_app/features/home/presentation/widgets/product_grid_card.dart';
import 'package:amarnath_enterprise_client_app/features/home/presentation/widgets/product_range_banner.dart';
import 'package:amarnath_enterprise_client_app/features/home/presentation/widgets/product_search_bar.dart';
import 'package:amarnath_enterprise_client_app/features/home/presentation/widgets/quick_action_cards.dart';
import 'package:amarnath_enterprise_client_app/features/home/presentation/widgets/recently_added_section.dart';
import 'package:amarnath_enterprise_client_app/features/home/presentation/widgets/welcome_section.dart';
import 'package:amarnath_enterprise_client_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:amarnath_enterprise_client_app/features/products/domain/entities/product.dart';
import 'package:amarnath_enterprise_client_app/features/products/domain/repositories/product_repository.dart';
import 'package:amarnath_enterprise_client_app/features/products/presentation/screens/product_detail_screen.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/screens/my_orders_screen.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/screens/profile_screen.dart';

/// Amarnath Enterprise Client App Home Screen.
///
/// Features:
/// - Full-screen botanical mint background (`img_splash_bg.png`)
/// - Persistent four-item Bottom Navigation Bar (Home, Browse, My Orders, Profile)
/// - Top App Header with menu, brand logo, and notification bell
/// - Personalized Welcome greeting with the authenticated Client's actual name
/// - Rounded Product Search Bar
/// - Side-by-side Quick Action cards ("Browse Products" and "My Orders")
/// - Styled "Explore Our Product Range" promotional banner
/// - "Recently Added" products grid backed by Firebase Realtime Database
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.productRepository,
    this.authRepository,
    this.initialClientName,
    this.initialTabIndex = 0,
    this.onMenuPressed,
    this.onNotificationPressed,
    this.onSignOut,
  });

  /// Optional injected product repository (defaults to [ProductRepositoryImpl]).
  final ProductRepository? productRepository;

  /// Optional injected auth repository (defaults to [AuthRepositoryImpl]).
  final AuthRepository? authRepository;

  /// Optional initial client name override (e.g. for testing).
  final String? initialClientName;

  /// Initial bottom nav tab index.
  final int initialTabIndex;

  /// Optional menu tap callback.
  final VoidCallback? onMenuPressed;

  /// Optional notification tap callback.
  final VoidCallback? onNotificationPressed;

  /// Optional sign out callback.
  final VoidCallback? onSignOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ProductRepository _productRepository;
  late final AuthRepository _authRepository;

  late int _currentTabIndex;
  String _clientName = '';
  ClientModel? _clientProfile;

  List<Product> _recentlyAddedProducts = [];
  bool _isLoadingProducts = true;
  String? _productsError;

  // Browse search controller
  final TextEditingController _browseSearchController =
      TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _filteredBrowseProducts = [];
  bool _isLoadingBrowse = false;

  static const String _backgroundImage = 'assets/images/img_splash_bg.png';

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    _productRepository = widget.productRepository ?? ProductRepositoryImpl();
    _authRepository = widget.authRepository ?? AuthRepositoryImpl();

    if (widget.initialClientName != null &&
        widget.initialClientName!.isNotEmpty) {
      _clientName = widget.initialClientName!;
    }

    _loadClientProfile();
    _loadRecentlyAddedProducts();
  }

  @override
  void dispose() {
    _browseSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadClientProfile() async {
    try {
      final profile = await _authRepository.getCurrentClientProfile();
      if (!mounted) return;
      if (profile != null && profile.name.trim().isNotEmpty) {
        setState(() {
          _clientProfile = profile;
          _clientName = profile.name.trim();
        });
      }
    } catch (_) {
      // Fallback gracefully to default or previously set name
    }
  }

  Future<void> _loadRecentlyAddedProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });

    try {
      final items =
          await _productRepository.getRecentlyAddedProducts(limit: 6);
      if (!mounted) return;
      setState(() {
        _recentlyAddedProducts = items;
        _isLoadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _productsError = e.toString();
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _loadAllProductsForBrowse() async {
    setState(() => _isLoadingBrowse = true);
    try {
      final items = await _productRepository.getProducts();
      if (!mounted) return;
      setState(() {
        _allProducts = items;
        _filteredBrowseProducts = items;
        _isLoadingBrowse = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingBrowse = false);
    }
  }

  void _onBrowseSearchChanged(String query) {
    final clean = query.trim().toLowerCase();
    setState(() {
      if (clean.isEmpty) {
        _filteredBrowseProducts = _allProducts;
      } else {
        _filteredBrowseProducts = _allProducts.where((p) {
          final nameMatches = p.name.toLowerCase().contains(clean);
          final codeMatches = p.code.toLowerCase().contains(clean);
          return nameMatches || codeMatches;
        }).toList();
      }
    });
  }

  void _navigateToTab(int index) {
    if (_currentTabIndex == index) return;
    setState(() {
      _currentTabIndex = index;
    });
    if (index == 1 && _allProducts.isEmpty) {
      _loadAllProductsForBrowse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOrdersTab = _currentTabIndex == 2;
    final isProfileTab = _currentTabIndex == 3;
    final isGreenHeader = isOrdersTab || isProfileTab;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor:
            isOrdersTab ? const Color(0xFF00864D) : Colors.transparent,
        statusBarIconBrightness:
            isGreenHeader ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            isGreenHeader ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full-screen botanical mint background
            Image.asset(
              _backgroundImage,
              width: 100.w,
              height: 100.h,
              fit: BoxFit.cover,
            ),

            // 2. Active Tab Screen Body
            IndexedStack(
              index: _currentTabIndex,
              children: [
                SafeArea(bottom: false, child: _buildHomeTab()),
                SafeArea(bottom: false, child: _buildBrowseTab()),
                _buildMyOrdersTab(),
                _buildProfileTab(),
              ],
            ),
          ],
        ),
        bottomNavigationBar: ClientBottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: _navigateToTab,
        ),
      ),
    );
  }

  // ==========================================
  // TAB 0: HOME VIEW
  // ==========================================
  Widget _buildHomeTab() {
    return RefreshIndicator(
      color: AppColors.primaryDarkGreen,
      onRefresh: () async {
        await Future.wait([
          _loadClientProfile(),
          _loadRecentlyAddedProducts(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.dp),

            // A. Top Header
            HomeHeader(
              onMenuPressed: () {
                if (widget.onMenuPressed != null) {
                  widget.onMenuPressed!();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Menu feature coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              onNotificationPressed: () {
                if (widget.onNotificationPressed != null) {
                  widget.onNotificationPressed!();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No new notifications'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              hasUnreadNotifications: true,
            ),

            SizedBox(height: 14.dp),

            // B. Welcome Section
            WelcomeSection(
              clientName: _clientName,
            ),

            SizedBox(height: 16.dp),

            // C. Product Search Bar
            ProductSearchBar(
              onTap: () {
                _navigateToTab(1);
              },
            ),

            SizedBox(height: 16.dp),

            // D. Quick Action Cards ("Browse Products" & "My Orders")
            QuickActionCards(
              onBrowseTap: () => _navigateToTab(1),
              onOrdersTap: () => _navigateToTab(2),
            ),

            SizedBox(height: 16.dp),

            // E. Product Range Banner
            ProductRangeBanner(
              onTap: () => _navigateToTab(1),
            ),

            SizedBox(height: 22.dp),

            // F. Recently Added Section
            RecentlyAddedSection(
              products: _recentlyAddedProducts,
              isLoading: _isLoadingProducts,
              errorMessage: _productsError,
              onRetry: _loadRecentlyAddedProducts,
              onViewAll: () => _navigateToTab(1),
              onProductTap: (product) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: product),
                  ),
                );
              },
            ),

            SizedBox(height: 28.dp),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: BROWSE VIEW
  // ==========================================
  Widget _buildBrowseTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.dp),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.dp),
          child: Row(
            children: [
              Text(
                'Browse Catalog',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.dp),
        ProductSearchBar(
          readOnly: false,
          controller: _browseSearchController,
          onChanged: _onBrowseSearchChanged,
        ),
        SizedBox(height: 12.dp),
        Expanded(
          child: _isLoadingBrowse
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryDarkGreen,
                    ),
                  ),
                )
              : _filteredBrowseProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48.dp,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                          SizedBox(height: 8.dp),
                          Text(
                            'No matching products found',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18.dp),
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filteredBrowseProducts.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14.dp,
                          mainAxisSpacing: 14.dp,
                          childAspectRatio: 0.74,
                        ),
                        itemBuilder: (context, index) {
                          final product = _filteredBrowseProducts[index];
                          return ProductGridCard(
                            product: product,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailScreen(product: product),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: MY ORDERS VIEW
  // ==========================================
  Widget _buildMyOrdersTab() {
    return MyOrdersScreen(
      embedded: true,
      onNavigateToTab: _navigateToTab,
    );
  }

  // ==========================================
  // TAB 3: PROFILE VIEW
  // ==========================================
  Widget _buildProfileTab() {
    return ProfileScreen(
      embedded: true,
      initialProfile: _clientProfile,
      authRepository: _authRepository,
      onNavigateToTab: _navigateToTab,
      onSignOut: widget.onSignOut,
    );
  }
}

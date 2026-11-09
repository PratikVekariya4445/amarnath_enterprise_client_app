import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/home/presentation/widgets/client_bottom_navigation_bar.dart';
import 'package:amarnath_enterprise_client_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:amarnath_enterprise_client_app/features/orders/domain/entities/order_entity.dart';
import 'package:amarnath_enterprise_client_app/features/orders/domain/repositories/order_repository.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/models/client_order_status.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/screens/order_details_screen.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/widgets/order_card.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/widgets/order_status_filter_bar.dart';

/// My Orders Screen for the Amarnath Enterprise Client App.
///
/// Reproduces the exact visual structure, colors, proportions, and typography
/// of the reference design.
///
/// Sections:
/// 1. Top Green Header (`#00864D`) with white "My Orders" title.
/// 2. Horizontal status filter tabs (`All`, `Pending`, `Confirmed`, `In Process`, `Completed`).
/// 3. Vertically scrollable list of compact order cards backed by Firebase Realtime Database.
/// 4. Fixed Bottom Navigation Bar (when not embedded).
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({
    super.key,
    this.orderRepository,
    this.embedded = false,
    this.onNavigateToTab,
  });

  /// Injected order repository (defaults to [OrderRepositoryImpl]).
  final OrderRepository? orderRepository;

  /// If true, hosted inside [HomeScreen] tab stack without duplicate bottom navigation.
  final bool embedded;

  /// Optional callback to switch tabs (e.g. to Products/Browse catalog).
  final ValueChanged<int>? onNavigateToTab;

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late final OrderRepository _repository;
  ClientOrderStatus _selectedFilter = ClientOrderStatus.all;

  List<OrderEntity> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.orderRepository ?? OrderRepositoryImpl();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetched = await _repository.getMyOrders();
      if (mounted) {
        setState(() {
          _orders = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load orders: $e';
        });
      }
    }
  }

  void _onStatusSelected(ClientOrderStatus status) {
    if (_selectedFilter != status) {
      setState(() {
        _selectedFilter = status;
      });
    }
  }

  List<OrderEntity> get _filteredOrders {
    if (_selectedFilter == ClientOrderStatus.all) {
      return _orders;
    }
    return _orders
        .where((order) => _selectedFilter.matches(order.status))
        .toList();
  }

  void _openOrderDetails(OrderEntity order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(
          orderId: order.orderId,
          initialOrder: order,
          orderRepository: _repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ==========================================
          // 1. TOP GREEN HEADER (#00864D)
          // ==========================================
          _buildTopHeader(),

          // ==========================================
          // 2. HORIZONTAL STATUS FILTER TABS
          // ==========================================
          OrderStatusFilterBar(
            selectedStatus: _selectedFilter,
            onStatusSelected: _onStatusSelected,
          ),

          // ==========================================
          // 3. SCROLLABLE ORDER CARDS LIST
          // ==========================================
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : ClientBottomNavigationBar(
              currentIndex: 2,
              onTap: (index) {
                if (widget.onNavigateToTab != null) {
                  widget.onNavigateToTab!(index);
                } else if (index != 2) {
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              },
            ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF00864D),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: content,
    );
  }

  /// Exact reproduction of the dark green top header.
  ///
  /// Height: ~60.dp + status bar height.
  /// Title: `My Orders` in bold white, 22.sp, left margin 22.dp.
  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF00864D),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60.dp,
          padding: EdgeInsets.symmetric(horizontal: 22.dp),
          alignment: Alignment.centerLeft,
          child: Text(
            'My Orders',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    return StreamBuilder<List<OrderEntity>>(
      stream: _repository.watchMyOrders(),
      builder: (context, snapshot) {
        // If stream has live data, keep state updated
        if (snapshot.hasData && snapshot.data != null) {
          _orders = snapshot.data!;
          _isLoading = false;
        }

        if (_isLoading && _orders.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00864D)),
            ),
          );
        }

        if (_errorMessage != null && _orders.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.dp),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48.dp,
                    color: const Color(0xFFDC2626),
                  ),
                  SizedBox(height: 12.dp),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  SizedBox(height: 16.dp),
                  ElevatedButton(
                    onPressed: _loadOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00864D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.dp),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final filtered = _filteredOrders;

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.dp),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72.dp,
                    height: 72.dp,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5EE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: const Color(0xFF00864D),
                      size: 36.dp,
                    ),
                  ),
                  SizedBox(height: 16.dp),
                  Text(
                    _selectedFilter == ClientOrderStatus.all
                        ? 'No orders placed yet'
                        : 'No ${_selectedFilter.label.toLowerCase()} orders',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  SizedBox(height: 6.dp),
                  Text(
                    _selectedFilter == ClientOrderStatus.all
                        ? 'Explore our product range and place your first order.'
                        : 'You do not have any orders with status "${_selectedFilter.label}".',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      color: const Color(0xFF454545),
                    ),
                  ),
                  SizedBox(height: 18.dp),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (widget.onNavigateToTab != null) {
                        widget.onNavigateToTab!(1);
                      } else {
                        Navigator.of(context).pushReplacementNamed('/home');
                      }
                    },
                    icon: const Icon(Icons.grid_view_outlined, size: 18),
                    label: const Text('Browse Products'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00864D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.dp),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.dp,
                        vertical: 10.dp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF00864D),
          onRefresh: _loadOrders,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.only(
              top: 4.dp,
              bottom: 24.dp,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final order = filtered[index];
              return OrderCard(
                order: order,
                onTap: () => _openOrderDetails(order),
              );
            },
          ),
        );
      },
    );
  }
}

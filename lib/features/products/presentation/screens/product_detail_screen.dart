import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/home/presentation/home_screen.dart';
import 'package:amarnath_enterprise_client_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:amarnath_enterprise_client_app/features/orders/domain/repositories/order_repository.dart';
import 'package:amarnath_enterprise_client_app/features/products/domain/entities/product.dart';

/// Product Specification item for the specifications card.
class ProductSpecificationItem {
  const ProductSpecificationItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

/// Amarnath Enterprise Client App Product Detail Screen.
///
/// Faithfully reproduces the layout, spacing, dimensions, typography, colors,
/// and styling of the reference design:
/// - Solid green Top App Bar (`#088053`) with white icon, title, and cart badge
/// - Rounded light-grey Product Image container with PageView carousel and dot indicators
/// - Product Information: prominent title, subtitle, green price / unit, and "In Stock" badge
/// - White Product Specifications card with row icon, labels, values, and dividers
/// - Dynamic Order Quantity stepper with automatic total computation in Indian Rupee format
/// - Persistent bottom full-width green "Place Order" button with shopping cart icon
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    this.initialQuantity = 1,
    this.cartItemCount = 3,
    this.onPlaceOrder,
    this.onCartPressed,
    this.orderRepository,
  });

  /// The domain entity for the product to display.
  final Product product;

  /// Initial quantity (defaults to 1).
  final int initialQuantity;

  /// Cart item count to display on the app bar badge (defaults to 3).
  final int cartItemCount;

  /// Optional callback invoked when the user taps "Place Order".
  final void Function(Product product, int quantity)? onPlaceOrder;

  /// Optional callback invoked when tapping the cart icon.
  final VoidCallback? onCartPressed;

  /// Optional injected order repository (defaults to [OrderRepositoryImpl]).
  final OrderRepository? orderRepository;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late int _quantity;
  late final PageController _pageController;
  late final OrderRepository _orderRepository;
  int _currentImageIndex = 0;
  bool _isPlacingOrder = false;

  static const Color _primaryGreen = Color(0xFF057D50);
  static const Color _imageContainerBg = Color(0xFFE8EAEF);
  static const Color _specsBorderColor = Color(0xFFE5E7EB);
  static const Color _specsRowDividerColor = Color(0xFFF1F5F9);
  static const Color _inStockBadgeBg = Color(0xFFC7F4D2);
  static const Color _inStockBadgeText = Color(0xFF034216);

  @override
  void initState() {
    super.initState();
    _quantity = math.max(1, widget.initialQuantity);
    _pageController = PageController();
    _orderRepository = widget.orderRepository ?? OrderRepositoryImpl();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  double get _estimatedTotal => widget.product.price * _quantity;

  /// Formats currency with Indian numbering convention (e.g. 420 -> "420", 4200 -> "4,200").
  static String formatIndianCurrency(num amount) {
    final isInteger = amount % 1 == 0;
    if (isInteger) {
      return _formatIndianInteger(amount.toInt());
    } else {
      final parts = amount.toStringAsFixed(2).split('.');
      return '${_formatIndianInteger(int.parse(parts[0]))}.${parts[1]}';
    }
  }

  static String _formatIndianInteger(int n) {
    final s = n.abs().toString();
    if (s.length <= 3) return (n < 0 ? '-' : '') + s;
    final last3 = s.substring(s.length - 3);
    final remaining = s.substring(0, s.length - 3);
    final buffer = StringBuffer();
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(remaining[i]);
    }
    return '${n < 0 ? '-' : ''}${buffer.toString()},$last3';
  }

  /// Builds specifications list dynamically based only on available product properties.
  List<ProductSpecificationItem> _buildAvailableSpecifications() {
    final product = widget.product;
    final List<ProductSpecificationItem> items = [];

    // 1. Brand (e.g. UltraTech, Tata)
    if (product.brand != null && product.brand!.trim().isNotEmpty) {
      items.add(ProductSpecificationItem(
        icon: Icons.apartment_outlined,
        label: 'Brand',
        value: product.brand!.trim(),
      ));
    }

    // 2. Type (e.g. OPC (Ordinary Portland Cement))
    if (product.type != null && product.type!.trim().isNotEmpty) {
      items.add(ProductSpecificationItem(
        icon: Icons.layers_outlined,
        label: 'Type',
        value: product.type!.trim(),
      ));
    }

    // 3. Weight (e.g. 50 kg)
    if (product.weight != null && product.weight!.trim().isNotEmpty) {
      items.add(ProductSpecificationItem(
        icon: Icons.shopping_bag_outlined,
        label: 'Weight',
        value: product.weight!.trim(),
      ));
    }

    // 4. Grade (e.g. 53 Grade)
    if (product.grade != null && product.grade!.trim().isNotEmpty) {
      items.add(ProductSpecificationItem(
        icon: Icons.verified_user_outlined,
        label: 'Grade',
        value: product.grade!.trim(),
      ));
    }

    // 5. Sizes (if sizes list is present)
    if (product.sizes.isNotEmpty) {
      items.add(ProductSpecificationItem(
        icon: Icons.straighten_outlined,
        label: 'Sizes',
        value: product.displaySizes,
      ));
    }

    // 6. Item No / Code
    if (product.code.trim().isNotEmpty) {
      items.add(ProductSpecificationItem(
        icon: Icons.tag_rounded,
        label: 'Item No',
        value: product.code.trim(),
      ));
    }

    // 7. Pack Size count
    if (product.packSize != null && product.packSize! > 0) {
      items.add(ProductSpecificationItem(
        icon: Icons.inventory_2_outlined,
        label: 'Pack Size',
        value: '${product.packSize} ${product.unit}',
      ));
    }

    // 8. Custom specifications map
    product.specifications.forEach((k, v) {
      if (k.trim().isNotEmpty && v.trim().isNotEmpty) {
        items.add(ProductSpecificationItem(
          icon: Icons.info_outline_rounded,
          label: k.trim(),
          value: v.trim(),
        ));
      }
    });

    return items;
  }

  String _buildProductSubtitle() {
    final product = widget.product;
    if (product.description != null && product.description!.trim().isNotEmpty) {
      return product.description!.trim();
    }
    if (product.weight != null && product.weight!.trim().isNotEmpty) {
      return '${product.weight!.trim()} ${product.unit}';
    }
    if (product.sizes.isNotEmpty) {
      return '${product.sizes.first} ${product.unit}';
    }
    if (product.packSize != null && product.packSize! > 0) {
      return '${product.packSize} ${product.unit}';
    }
    return product.unit.isNotEmpty ? product.unit : 'Standard';
  }

  String _formatUnitForQuantity() {
    final unit = widget.product.unit.trim();
    if (unit.isEmpty) return 'Item(s)';
    if (unit.toLowerCase().endsWith('(s)')) return unit;
    if (unit.toLowerCase() == 'pcs') return 'Piece(s)';
    return '$unit(s)';
  }

  Future<void> _handlePlaceOrder() async {
    if (_isPlacingOrder) return;
    if (_quantity < 1) return;

    if (widget.onPlaceOrder != null) {
      widget.onPlaceOrder!(widget.product, _quantity);
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      await _orderRepository.placeOrder(
        product: widget.product,
        quantity: _quantity,
      );

      if (!mounted) return;
      _showOrderSuccessDialog();
    } catch (e) {
      debugPrint('[ProductDetailScreen] Place order error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  void _showOrderSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.dp),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: _primaryGreen, size: 26.dp),
            SizedBox(width: 8.dp),
            Text(
              'Order Placed',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          'Your order for $_quantity ${_formatUnitForQuantity()} of ${widget.product.name} (Total: ₹ ${formatIndianCurrency(_estimatedTotal)}) has been submitted for approval.',
          style: TextStyle(
            fontSize: 13.5.sp,
            color: const Color(0xFF334155),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Done',
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.dp),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const HomeScreen(initialTabIndex: 2),
                ),
                (route) => route.isFirst,
              );
            },
            child: Text(
              'View My Orders',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product.allImages;
    final specifications = _buildAvailableSpecifications();
    final priceString = formatIndianCurrency(widget.product.price);
    final totalString = formatIndianCurrency(_estimatedTotal);
    final subtitle = _buildProductSubtitle();
    final unitForQty = _formatUnitForQuantity();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Product Image Carousel Section
                    _buildImageSection(images),

                    // B. Product Information Section
                    _buildProductInfoSection(priceString, subtitle),

                    // C. Product Specifications Card
                    if (specifications.isNotEmpty)
                      _buildSpecificationsCard(specifications),

                    SizedBox(height: 18.dp),

                    // D. Order Quantity Section
                    _buildOrderQuantitySection(totalString, unitForQty),

                    SizedBox(height: 20.dp),
                  ],
                ),
              ),
            ),

            // E. Fixed Bottom Place Order Button
            _buildBottomPlaceOrderBar(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP APP BAR
  // ===========================================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: _primaryGreen,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      backgroundColor: _primaryGreen,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.dp),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Text(
        'Product Detail',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18.5.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  // ===========================================================================
  // PRODUCT IMAGE SECTION
  // ===========================================================================
  Widget _buildImageSection(List<String> images) {
    // Total dots displayed: if multiple images exist, match length;
    // if 0 or 1 image, display 3 dots with first active to faithfully match the reference design.
    final int dotsCount = images.length > 1 ? images.length : 3;

    return Padding(
      padding: EdgeInsets.only(
        left: 16.dp,
        right: 16.dp,
        top: 16.dp,
        bottom: 8.dp,
      ),
      child: Column(
        children: [
          // Image Container
          Container(
            height: 270.dp,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _imageContainerBg,
              borderRadius: BorderRadius.circular(18.dp),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18.dp),
              child: images.isEmpty
                  ? _buildImagePlaceholder()
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final imageUrl = images[index];
                        return _buildSingleProductImage(imageUrl);
                      },
                    ),
            ),
          ),

          SizedBox(height: 10.dp),

          // Page Indicator Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(dotsCount, (index) {
              final bool isActive = index == _currentImageIndex;
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 3.5.dp),
                width: isActive ? 6.dp : 5.dp,
                height: isActive ? 6.dp : 5.dp,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? const Color(0xFF2D3748)
                      : Colors.transparent,
                  border: isActive
                      ? null
                      : Border.all(
                          color: const Color(0xFF94A3B8),
                          width: 1.1,
                        ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleProductImage(String imageUrl) {
    final cleanUrl = imageUrl.trim();
    if (cleanUrl.isEmpty) {
      return _buildImagePlaceholder();
    }

    if (cleanUrl.startsWith('assets/')) {
      return Padding(
        padding: EdgeInsets.all(22.dp),
        child: Image.asset(
          cleanUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _buildImagePlaceholder(),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(22.dp),
      child: CachedNetworkImage(
        imageUrl: cleanUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(_primaryGreen),
          ),
        ),
        errorWidget: (context, url, error) => _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(22.dp),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.inventory_2_outlined,
          size: 56.dp,
          color: _primaryGreen.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  // ===========================================================================
  // PRODUCT INFORMATION SECTION
  // ===========================================================================
  Widget _buildProductInfoSection(String priceString, String subtitle) {
    final bool isInStock = widget.product.isActive;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.dp, vertical: 10.dp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name
          Text(
            widget.product.name,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
              letterSpacing: -0.3,
              height: 1.25,
            ),
          ),

          SizedBox(height: 4.dp),

          // Subtitle / Size / Pack description
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14.5.sp,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ),
          ),

          SizedBox(height: 10.dp),

          // Price & Availability Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Price / Unit
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '₹ $priceString',
                        style: TextStyle(
                          fontSize: 21.sp,
                          fontWeight: FontWeight.w800,
                          color: _primaryGreen,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (widget.product.unit.isNotEmpty)
                        TextSpan(
                          text: ' / ${widget.product.unit}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: _primaryGreen,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: 8.dp),

              // Availability Badge ("In Stock" / "Out of Stock")
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.dp,
                  vertical: 4.5.dp,
                ),
                decoration: BoxDecoration(
                  color: isInStock ? _inStockBadgeBg : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20.dp),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isInStock ? Icons.check_circle : Icons.cancel,
                      size: 14.5.dp,
                      color: isInStock
                          ? _inStockBadgeText
                          : const Color(0xFFDC2626),
                    ),
                    SizedBox(width: 4.5.dp),
                    Text(
                      isInStock ? 'In Stock' : 'Out of Stock',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: isInStock
                            ? _inStockBadgeText
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PRODUCT SPECIFICATIONS CARD
  // ===========================================================================
  Widget _buildSpecificationsCard(List<ProductSpecificationItem> items) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.dp, vertical: 6.dp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.dp),
        border: Border.all(
          color: _specsBorderColor,
          width: 1.0,
        ),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final bool isLast = index == items.length - 1;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.dp,
                  vertical: 12.5.dp,
                ),
                child: Row(
                  children: [
                    // Icon
                    Icon(
                      item.icon,
                      size: 18.dp,
                      color: const Color(0xFF64748B),
                    ),
                    SizedBox(width: 14.dp),

                    // Label (e.g. Brand, Type, Weight, Grade)
                    SizedBox(
                      width: 72.dp,
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          color: const Color(0xFF475569),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    SizedBox(width: 8.dp),

                    // Value
                    Expanded(
                      child: Text(
                        item.value,
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: _specsRowDividerColor,
                ),
            ],
          );
        }),
      ),
    );
  }

  // ===========================================================================
  // ORDER QUANTITY SECTION
  // ===========================================================================
  Widget _buildOrderQuantitySection(String totalString, String unitForQty) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.dp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Quantity',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 12.dp),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Stepper & Unit
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 38.dp,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.dp),
                      border: Border.all(
                        color: _specsBorderColor,
                        width: 1.0,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9.dp),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Minus button
                          Material(
                            color: const Color(0xFFF1F5F9),
                            child: InkWell(
                              onTap: _decrementQuantity,
                              child: SizedBox(
                                width: 36.dp,
                                height: 38.dp,
                                child: Center(
                                  child: Icon(
                                    Icons.remove,
                                    size: 16.dp,
                                    color: _quantity > 1
                                        ? const Color(0xFF475569)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Quantity value
                          Container(
                            width: 44.dp,
                            height: 38.dp,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border.symmetric(
                                vertical: BorderSide(
                                  color: _specsBorderColor,
                                  width: 1.0,
                                ),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$_quantity',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),

                          // Plus button
                          Material(
                            color: const Color(0xFFE8F6ED),
                            child: InkWell(
                              onTap: _incrementQuantity,
                              child: SizedBox(
                                width: 36.dp,
                                height: 38.dp,
                                child: Center(
                                  child: Icon(
                                    Icons.add,
                                    size: 16.dp,
                                    color: _primaryGreen,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 8.dp),

                  // Unit label (e.g. Bag(s), Piece(s))
                  Text(
                    unitForQty,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
              ),

              SizedBox(width: 8.dp),

              // Estimated Total
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total (Estimated)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 2.dp),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '₹ $totalString',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: _primaryGreen,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BOTTOM FIXED PLACE ORDER BAR
  // ===========================================================================
  Widget _buildBottomPlaceOrderBar() {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: _specsBorderColor,
            width: 1.0,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16.dp,
        right: 16.dp,
        top: 12.dp,
        bottom: math.max(12.dp, bottomInset),
      ),
      child: SizedBox(
        height: 52.dp,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.dp),
            ),
          ),
          onPressed: _isPlacingOrder ? null : _handlePlaceOrder,
          child: _isPlacingOrder
              ? SizedBox(
                  width: 22.dp,
                  height: 22.dp,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 20.dp,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8.dp),
                    Text(
                      'Place Order',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

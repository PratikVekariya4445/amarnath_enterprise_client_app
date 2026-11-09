import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:amarnath_enterprise_client_app/features/orders/domain/entities/order_entity.dart';
import 'package:amarnath_enterprise_client_app/features/orders/domain/repositories/order_repository.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/widgets/order_status_badge.dart';

/// Screen displaying complete details of an Order placed by the Client.
class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
    this.orderRepository,
  });

  final String orderId;
  final OrderEntity? initialOrder;
  final OrderRepository? orderRepository;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late final OrderRepository _repository;
  OrderEntity? _order;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.orderRepository ?? OrderRepositoryImpl();
    _order = widget.initialOrder;

    if (_order == null) {
      _loadOrder();
    }
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetched = await _repository.getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = fetched;
          _isLoading = false;
          if (fetched == null) {
            _errorMessage = 'Order not found';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load order: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF00864D),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF00864D),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Order Details',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00864D)),
        ),
      );
    }

    if (_errorMessage != null || _order == null) {
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
                _errorMessage ?? 'Order details unavailable',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111111),
                ),
              ),
              SizedBox(height: 16.dp),
              ElevatedButton(
                onPressed: _loadOrder,
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

    final order = _order!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.dp, vertical: 16.dp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Status Banner Card
          _buildStatusCard(order),

          SizedBox(height: 14.dp),

          // 2. Product Information Card
          _buildProductCard(order),

          SizedBox(height: 14.dp),

          // 3. Price Breakdown Card
          _buildPriceBreakdownCard(order),

          SizedBox(height: 14.dp),

          // 4. Client / Delivery Card
          _buildClientInfoCard(order),

          SizedBox(height: 24.dp),
        ],
      ),
    );
  }

  Widget _buildStatusCard(OrderEntity order) {
    return Container(
      padding: EdgeInsets.all(16.dp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.dp),
        border: Border.all(
          color: const Color(0xFFD9DDE0),
          width: 1.dp,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.displayOrderNumber,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111111),
                ),
              ),
              OrderStatusBadge(status: order.clientStatus),
            ],
          ),
          SizedBox(height: 8.dp),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14.dp,
                color: const Color(0xFF454545),
              ),
              SizedBox(width: 6.dp),
              Text(
                'Placed on ${order.formattedDateTime}',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  color: const Color(0xFF454545),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(OrderEntity order) {
    final image = (order.productImage != null && order.productImage!.isNotEmpty)
        ? order.productImage!
        : (order.productImageUrl ?? '');

    return Container(
      padding: EdgeInsets.all(16.dp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.dp),
        border: Border.all(
          color: const Color(0xFFD9DDE0),
          width: 1.dp,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Details',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111111),
            ),
          ),
          SizedBox(height: 12.dp),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64.dp,
                height: 68.dp,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFA),
                  borderRadius: BorderRadius.circular(10.dp),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: _buildThumbnailImage(image),
              ),
              SizedBox(width: 14.dp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.productName,
                      style: TextStyle(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    SizedBox(height: 4.dp),
                    Text(
                      order.displaySpecification,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        color: const Color(0xFF454545),
                      ),
                    ),
                    SizedBox(height: 6.dp),
                    Text(
                      order.displayQuantityAndPrice,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF111111),
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

  Widget _buildPriceBreakdownCard(OrderEntity order) {
    return Container(
      padding: EdgeInsets.all(16.dp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.dp),
        border: Border.all(
          color: const Color(0xFFD9DDE0),
          width: 1.dp,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111111),
            ),
          ),
          SizedBox(height: 12.dp),
          _buildSummaryRow(
            'Price (${order.quantity} x ₹${order.price.toStringAsFixed(0)})',
            order.formattedTotalAmount,
          ),
          SizedBox(height: 8.dp),
          _buildSummaryRow('Delivery / Shipping', 'Free'),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.dp),
            child: const Divider(color: Color(0xFFD9DDE0), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111111),
                ),
              ),
              Text(
                order.formattedTotalAmount,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00864D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfoCard(OrderEntity order) {
    return Container(
      padding: EdgeInsets.all(16.dp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.dp),
        border: Border.all(
          color: const Color(0xFFD9DDE0),
          width: 1.dp,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Client Information',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111111),
            ),
          ),
          SizedBox(height: 12.dp),
          _buildInfoItem(Icons.person_outline_rounded, 'Name', order.clientName),
          if (order.clientMobile.isNotEmpty) ...[
            SizedBox(height: 8.dp),
            _buildInfoItem(Icons.phone_outlined, 'Phone', order.clientMobile),
          ],
          if (order.companyName.isNotEmpty) ...[
            SizedBox(height: 8.dp),
            _buildInfoItem(Icons.business_outlined, 'Company', order.companyName),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5.sp,
            color: const Color(0xFF454545),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111111),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.dp, color: const Color(0xFF454545)),
        SizedBox(width: 8.dp),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12.5.sp,
            color: const Color(0xFF454545),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111111),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnailImage(String image) {
    if (image.isEmpty) {
      return Icon(
        Icons.inventory_2_outlined,
        color: const Color(0xFF888888),
        size: 32.dp,
      );
    }

    if (image.startsWith('http://') || image.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.contain,
        placeholder: (context, url) => Center(
          child: SizedBox(
            width: 16.dp,
            height: 16.dp,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00864D)),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Icon(
          Icons.inventory_2_outlined,
          color: const Color(0xFF888888),
          size: 32.dp,
        ),
      );
    }

    if (image.startsWith('assets/')) {
      return Image.asset(
        image,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(
          Icons.inventory_2_outlined,
          color: const Color(0xFF888888),
          size: 32.dp,
        ),
      );
    }

    return Icon(
      Icons.inventory_2_outlined,
      color: const Color(0xFF888888),
      size: 32.dp,
    );
  }
}

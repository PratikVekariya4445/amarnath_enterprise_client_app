import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/orders/domain/entities/order_entity.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/widgets/order_status_badge.dart';

/// Compact Order Card matching reference design specifications.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  final OrderEntity order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 16.dp,
        vertical: 6.dp,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.dp),
        border: Border.all(
          color: const Color(0xFFD9DDE0),
          width: 1.dp,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.dp),
          child: Padding(
            padding: EdgeInsets.all(16.dp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // ROW 1: Order Header (ID, Date & Status)
                // ==========================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.displayOrderNumber,
                            style: TextStyle(
                              fontSize: 15.5.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF111111),
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 3.dp),
                          Text(
                            order.formattedDateTime,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF454545),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.dp),
                    OrderStatusBadge(status: order.clientStatus),
                  ],
                ),

                SizedBox(height: 14.dp),

                // ==========================================
                // ROW 2: Product Thumbnail, Details, Total, Chevron
                // ==========================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Area 1: Product Thumbnail
                    _buildProductThumbnail(),

                    // Area 2: Product Information
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 12.dp, right: 6.dp),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              order.productName,
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF111111),
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 3.dp),
                            Text(
                              order.displaySpecification,
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF454545),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.dp),
                            Text(
                              order.displayQuantityAndPrice,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF111111),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Area 3: Vertical Divider
                    Container(
                      width: 1.dp,
                      height: 42.dp,
                      color: const Color(0xFFD9DDE0),
                      margin: EdgeInsets.symmetric(horizontal: 8.dp),
                    ),

                    // Area 4: Total Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF454545),
                          ),
                        ),
                        SizedBox(height: 2.dp),
                        Text(
                          order.formattedTotalAmount,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00864D),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),

                    // Area 5: Trailing Chevron
                    Padding(
                      padding: EdgeInsets.only(left: 4.dp),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 24.dp,
                        color: const Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductThumbnail() {
    final image = (order.productImage != null && order.productImage!.isNotEmpty)
        ? order.productImage!
        : (order.productImageUrl ?? '');

    return Container(
      width: 52.dp,
      height: 56.dp,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFA),
        borderRadius: BorderRadius.circular(8.dp),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: _buildThumbnailImage(image),
    );
  }

  Widget _buildThumbnailImage(String image) {
    if (image.isEmpty) {
      return Icon(
        Icons.inventory_2_outlined,
        color: const Color(0xFF888888),
        size: 28.dp,
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
          size: 28.dp,
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
          size: 28.dp,
        ),
      );
    }

    return Icon(
      Icons.inventory_2_outlined,
      color: const Color(0xFF888888),
      size: 28.dp,
    );
  }
}

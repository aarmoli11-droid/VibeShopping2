import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../comparison/providers/comparison_provider.dart';
import '../models/product.dart';
import '../helpers/product_display_helper.dart';
import '../../manual_lists/models/manual_list_entity.dart';
import '../../manual_lists/widgets/add_to_list_sheet.dart';
import 'vibe_image_slider.dart';
import '../../../core/vibe_constants.dart';
import '../../../core/vibe_formatter.dart';

class VibeProductCard extends StatelessWidget {
  const VibeProductCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  final ProductEntity data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final priceLabel = ProductDisplayHelper.displayPrice(data);
    final urls = ProductDisplayHelper.validImageUrls(data);
    final storeData = ProductDisplayHelper.supermarketData(data);

    return Material(
      color: VibeColors.backgroundWhite,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: VibeImageSlider(url: urls),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: VibeColors.navy,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    priceLabel,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _PriceComparison(data: data),
                  const SizedBox(height: 6),
                  if (storeData != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: VibeColors.mint.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          if (storeData['logo_url'] != null &&
                              storeData['logo_url'].toString().isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: storeData['logo_url']!,
                                width: 16,
                                height: 16,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(
                                    Icons.storefront,
                                    size: 16,
                                    color: VibeColors.navy),
                              ),
                            )
                          else
                            const Icon(Icons.storefront,
                                size: 16, color: VibeColors.navy),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              storeData['name'] ?? 'Tienda',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: VibeColors.navy,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  final storeName = storeData?['name'] ?? 'Desconocida';
                  final storeId =
                      data.prices.isNotEmpty ? data.prices.first.storeId : '';
                  final price = data.referencePrice;

                  final itemProduct = ManualListItemEntity(
                    productId: data.id,
                    storeId: storeId,
                    storeNameSnapshot: storeName,
                    unitPriceSnapshot: price,
                    quantity: 1,
                  );

                  AddToListSheet.show(context, itemProduct);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: VibeColors.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceComparison extends StatelessWidget {
  final ProductEntity data;

  const _PriceComparison({required this.data});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ComparisonProvider>();
    final preview = ProductDisplayHelper.getComparisonPreview(data, provider);
    if (preview == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (preview.bestStoreLogoUrl != null &&
              preview.bestStoreLogoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: CachedNetworkImage(
                imageUrl: preview.bestStoreLogoUrl!,
                width: 12,
                height: 12,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox(width: 12),
              ),
            )
          else
            const Icon(Icons.storefront, size: 12, color: Colors.green),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              preview.bestStoreName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            VibeFormatter.formatPrice(preview.bestPrice),
            style: const TextStyle(
              fontSize: 9,
              color: Colors.green,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (preview.savings > 0) ...[
            const SizedBox(width: 3),
            Text(
              '-${VibeFormatter.formatPrice(preview.savings)}',
              style: TextStyle(
                fontSize: 8,
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

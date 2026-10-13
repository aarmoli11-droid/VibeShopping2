import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/responsive.dart';
import '../models/product.dart';
import '../helpers/product_display_helper.dart';
import '../../comparison/models/comparison_result.dart';
import '../../comparison/models/comparison_summary.dart';
import '../../comparison/providers/comparison_provider.dart';
import '../../comparison/widgets/store_price_comparison.dart';

class ProductDetailView extends StatefulWidget {
  const ProductDetailView({
    super.key,
    required this.product,
  });

  final ProductEntity product;

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  @override
  Widget build(BuildContext context) {
    final imageUrl = ProductDisplayHelper.primaryImage(widget.product);
    final price = ProductDisplayHelper.displayPrice(widget.product);
    final comparisonProvider = context.read<ComparisonProvider>();
    final result = comparisonProvider.compareProduct(widget.product.id);
    final summary = comparisonProvider.summaryFor(widget.product.id);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Dos columnas solo cuando hay ancho real para ambas.
          final twoColumns = VibeResponsive.isDesktop(constraints.maxWidth);

          if (twoColumns) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: _buildImage(imageUrl, padding: 32),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 24, bottom: 32),
                        child: _buildDetails(price, result, summary),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty)
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.3,
                    child: _buildImage(imageUrl, padding: 48),
                  ),
                const SizedBox(height: 24),
                _buildDetails(price, result, summary),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // Imagen con zoom. Se reutiliza en móvil (sobre la información) y en la
  // columna izquierda de tablet/escritorio.
  Widget _buildImage(String? imageUrl, {required double padding}) {
    if (imageUrl == null || imageUrl.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.all(padding),
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 3.0,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          filterQuality: FilterQuality.high,
          fit: BoxFit.contain,
          progressIndicatorBuilder: (context, url, progress) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  // Nombre, precio, nota y comparación de precios.
  Widget _buildDetails(
    String price,
    ComparisonResult? result,
    ComparisonSummary? summary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name,
                style: const TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Cantidad estándar disponible",
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (result != null && summary != null)
          StorePriceComparison(result: result, summary: summary),
      ],
    );
  }
}

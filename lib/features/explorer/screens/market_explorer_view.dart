import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/vibe_constants.dart';
import '../../products/widgets/vibe_product_card.dart';
import '../../products/screens/product_detail_view.dart';
import '../providers/explorer_provider.dart';
import '../../shopping_assistant/shopping_assistant_screen.dart';
import '../widgets/vibe_brand_logo.dart';
import '../widgets/vibe_search_bar.dart';
import '../widgets/vibe_category_bar.dart';
import '../widgets/vibe_selection_modals.dart';
import '../widgets/store_filter_selector.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/empty_product_state.dart';

class MarketExplorerView extends StatefulWidget {
  const MarketExplorerView({super.key});

  @override
  State<MarketExplorerView> createState() => _MarketExplorerViewState();
}

class _MarketExplorerViewState extends State<MarketExplorerView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ExplorerProvider>().initialize();
      _precacheStoreLogos();
    });
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      context.read<ExplorerProvider>().setSearchQuery(_searchController.text);
    });
  }

  void _precacheStoreLogos() {
    final stores = context.read<ExplorerProvider>().stores;
    for (final store in stores) {
      if (store.logoUrl != null && store.logoUrl!.isNotEmpty) {
        unawaited(precacheImage(
          CachedNetworkImageProvider(store.logoUrl!),
          context,
          onError: (_, __) {},
        ));
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExplorerProvider>();
    final isLoading = provider.productsLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: const SizedBox.shrink(),
            actions: [
              IconButton(
                tooltip: 'Asistente de compras',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ShoppingAssistantScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.tips_and_updates_rounded,
                    color: VibeColors.navy),
              ),
            ],
            title: const VibeBrandLogo(),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: VibeSearchBar(
                  controller: _searchController,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: StoreFilterSelector(
                label: provider.storeFilterLabel,
                selectedStoreIds: provider.selectedStoreIds,
                stores: provider.stores,
                onTap: () => VibeSelectionModals.openStorePicker(
                  context,
                  provider.allStores,
                  provider.selectedStoreIds,
                  provider.stores,
                  (all, selected) => provider.setStoreFilter(all, selected),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: VibeCategoryBar(
              categories: provider.categories,
              selectedCategoryId: provider.categoryId,
              onCategorySelected: (id) => provider.setCategory(id),
            ),
          ),
          SliverToBoxAdapter(
            child: isLoading
                ? const ShimmerLoading()
                : _buildProductContent(provider),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildProductContent(ExplorerProvider provider) {
    final grouped = provider.groupedProducts;

    if (grouped.isEmpty) {
      if (!provider.allStores && provider.selectedStoreIds.isNotEmpty) {
        final label = provider.selectedStoreIds.length == 1
            ? provider.storeNameById(provider.selectedStoreIds.first)
            : provider.selectedStoreIds
                .map((id) => provider.storeNameById(id))
                .join(' o ');
        return EmptyProductState(storeName: label);
      }
      return const EmptyProductState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final sectionTitle = grouped.keys.elementAt(index);
        final productsInSection = grouped[sectionTitle]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                sectionTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: VibeColors.navy,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            SizedBox(
              height: 240,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: productsInSection.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, productIndex) {
                  final product = productsInSection[productIndex];
                  return SizedBox(
                    width: 170.0,
                    child: VibeProductCard(
                      data: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailView(
                              product: product,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

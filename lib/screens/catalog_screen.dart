import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../state/cart_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/glass.dart';
import '../widgets/product_image.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

/// Always scrollable so pull-to-refresh works even with few (or no) items.
const _physics = AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());

/// The three production UI states of the catalog.
enum LoadState { loading, success, error }

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final List<Product> _products = [];
  LoadState _state = LoadState.loading;
  String _error = '';
  bool _grid = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Fetches the catalog. [showSpinner] is false for pull-to-refresh, because
  /// the RefreshIndicator already shows its own spinner over the old list.
  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _state = LoadState.loading);
    try {
      final products = await context.read<ProductService>().fetchProducts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      setState(() {
        _products
          ..clear()
          ..addAll(products);
        _state = LoadState.success;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _state = LoadState.error;
      });
    }
  }

  void _open(Product p) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ProductDetailScreen(product: p)),
    );
  }

  void _remove(Product p) {
    final index = _products.indexOf(p);
    setState(() => _products.removeAt(index));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Removed "${p.title}"',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: AppColors.orangeLight,
            onPressed: () {
              // Skip if the screen is gone or a reload already brought it back.
              if (!mounted || _products.any((x) => x.id == p.id)) return;
              setState(
                () => _products.insert(index.clamp(0, _products.length), p),
              );
            },
          ),
        ),
      );
  }

  Widget _dismissible(
    Product p, {
    required double radius,
    required Widget child,
  }) {
    return Dismissible(
      key: ValueKey(p.id),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _remove(p),
      child: child,
    );
  }

  Widget _feed() {
    if (_products.isEmpty) {
      return _EmptyCatalog(key: const ValueKey('empty'), onReload: _load);
    }
    if (_grid) {
      return GridView.builder(
        key: const ValueKey('grid'),
        physics: _physics,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.66,
        ),
        itemCount: _products.length,
        itemBuilder: (_, i) => _dismissible(
          _products[i],
          radius: 26,
          child: _ProductCard(
            product: _products[i],
            onTap: () => _open(_products[i]),
          ),
        ),
      );
    }
    return ListView.separated(
      key: const ValueKey('list'),
      physics: _physics,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
      itemCount: _products.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 0.5,
        color: Colors.white.withValues(alpha: 0.25),
      ),
      itemBuilder: (_, i) => _dismissible(
        _products[i],
        radius: 18,
        child: _ProductRow(
          product: _products[i],
          onTap: () => _open(_products[i]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = switch (_state) {
      LoadState.loading => const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(color: Colors.white),
      ),
      LoadState.error => _ErrorView(
        key: const ValueKey('error'),
        message: _error,
        onRetry: _load,
      ),
      LoadState.success => RefreshIndicator(
        key: const ValueKey('success'),
        onRefresh: () => _load(showSpinner: false),
        color: AppColors.ink,
        backgroundColor: Colors.white,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _feed(),
        ),
      ),
    };

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: ScreenHeader(
              title: 'Catalog',
              onBack: widget.onBack,
              trailing: CartBadgeButton(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CartScreen()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: SectionHeader(
                    title: _grid ? 'Grid catalog' : 'List feed',
                    action: _state == LoadState.success
                        ? '${_products.length} items'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                GlassCircleButton(
                  size: 40,
                  icon: _grid
                      ? Icons.view_list_rounded
                      : Icons.grid_view_rounded,
                  onTap: () => setState(() => _grid = !_grid),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Hero(
              tag: 'product_image_${product.id}',
              child: SizedBox(
                width: 64,
                height: 64,
                child: ProductImage(url: product.imageUrl, radius: 16),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Rating(
                    rating: product.rating,
                    reviewCount: product.reviewCount,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPrice(product.price),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _CartToggle(product: product),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 26,
      opacity: 0.55,
      borderOpacity: 0.6,
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Hero(
                    tag: 'product_image_${product.id}',
                    child: ProductImage(
                      url: product.imageUrl,
                      radius: 18,
                      padding: 14,
                      iconSize: 36,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _CartToggle(product: product),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Rating(rating: product.rating, color: AppColors.ink),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          formatPrice(product.price),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Add to Cart" pill that flips to "In cart" while the product is selected.
class _CartToggle extends StatelessWidget {
  const _CartToggle({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final inCart = context.select<CartProvider, bool>(
      (c) => c.contains(product),
    );
    return Pressable(
      onTap: () => context.read<CartProvider>().toggle(product),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: inCart ? AppColors.orange : AppColors.ink,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              inCart ? Icons.check_rounded : Icons.add_shopping_cart_rounded,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              inCart ? 'In cart' : 'Add to Cart',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Star, rating and (optionally) the number of reviews.
class Rating extends StatelessWidget {
  const Rating({
    super.key,
    required this.rating,
    required this.color,
    this.reviewCount,
    this.fontSize = 12,
    this.longLabel = false,
  });

  final double rating;
  final int? reviewCount;
  final Color color;
  final double fontSize;

  /// "(120 reviews)" instead of the compact "(120)".
  final bool longLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: fontSize + 3, color: AppColors.orange),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              longLabel ? '($reviewCount reviews)' : '($reviewCount)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                color: color.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Offline / timeout / server error, with a button that retries the request.
class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 130),
      children: [
        Glass(
          opacity: 0.12,
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(height: 12),
              const Text('You are offline', style: AppText.section),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(height: 1.35, fontSize: 13),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry Connection'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({super.key, required this.onReload});

  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: _physics,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 130),
      children: [
        Glass(
          opacity: 0.12,
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 12),
              const Text('Catalog is Empty', style: AppText.section),
              const SizedBox(height: 6),
              Text(
                'Reload the catalog, or pull down to refresh.',
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(height: 1.35, fontSize: 13),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Reload catalog',
                  icon: Icons.refresh_rounded,
                  onTap: onReload,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

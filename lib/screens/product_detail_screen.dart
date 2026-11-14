import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/cart_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/glass.dart';
import '../widgets/product_image.dart';
import '../widgets/share_sheet.dart';
import 'cart_screen.dart';
import 'catalog_screen.dart' show Rating;

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openCart() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const CartScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.gallery;

    return Scaffold(
      backgroundColor: Palette.of(context).bgBottom,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: ScreenHeader(
                    title: 'Details',
                    onBack: () => Navigator.of(context).pop(),
                    trailing: GlassCircleButton(
                      icon: Icons.ios_share_rounded,
                      onTap: () => showShareSheet(context, product),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      // ---------- Photo carousel ----------
                      SizedBox(
                        height: 320,
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: images.length,
                              onPageChanged: (i) => setState(() => _page = i),
                              itemBuilder: (_, i) {
                                final photo = ProductImage(
                                  url: images[i],
                                  radius: 28,
                                  padding: 32,
                                  iconSize: 56,
                                );
                                // Only the first photo flies in from the list.
                                return i == 0
                                    ? Hero(
                                        tag: 'product_image_${product.id}',
                                        child: photo,
                                      )
                                    : photo;
                              },
                            ),
                            Positioned(
                              top: 14,
                              right: 14,
                              child: StatusChip(
                                label: '${_page + 1} / ${images.length}',
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 14,
                              child: _Dots(count: images.length, index: _page),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ---------- Info ----------
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _CategoryBadge(category: product.category),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        product.title,
                        style: AppText.title.copyWith(height: 1.25),
                      ),
                      const SizedBox(height: 8),
                      Rating(
                        rating: product.rating,
                        reviewCount: product.reviewCount,
                        color: Colors.white,
                        fontSize: 13,
                        longLabel: true,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        formatPrice(product.price),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Glass(
                        opacity: 0.14,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Description', style: AppText.section),
                            const SizedBox(height: 8),
                            Text(
                              product.description,
                              style: AppText.body.copyWith(height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ---------- Sticky "Add to Cart" ----------
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: _AddToCartButton(
                      product: product,
                      onOpenCart: _openCart,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Adds the product; once it is in the cart, the button opens the cart.
class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({required this.product, required this.onOpenCart});

  final Product product;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) {
    final inCart = context.select<CartProvider, bool>(
      (c) => c.contains(product),
    );
    return PrimaryButton(
      label: inCart ? 'View Cart' : 'Add to Cart',
      icon: inCart ? Icons.shopping_bag_rounded : Icons.add_shopping_cart,
      onTap: inCart
          ? onOpenCart
          : () => context.read<CartProvider>().toggle(product),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Page dots; the active one stretches into a pill.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index
                  ? AppColors.orange
                  : AppColors.ink.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

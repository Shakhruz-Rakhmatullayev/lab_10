/// A store product from https://fakestoreapi.com/products
///
/// Example JSON:
/// ```json
/// {
///   "id": 1,
///   "title": "Fjallraven - Foldsack No. 1 Backpack",
///   "price": 109.95,
///   "description": "Your perfect pack for everyday use...",
///   "category": "men's clothing",
///   "image": "https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_t.png",
///   "rating": { "rate": 3.9, "count": 120 }
/// }
/// ```
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
  });

  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  final double rating;
  final int reviewCount;

  /// Type-safe deserialization.
  ///
  /// * Numbers are read as `num` and then converted, so `22` (int) and
  ///   `22.5` (double) both work. A plain `as double` crashes on an int.
  /// * Every field has a null-safe fallback, so a missing key never crashes.
  factory Product.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'] is Map<String, dynamic>
        ? json['rating'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return Product(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Untitled product',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? 'No description.',
      category: json['category'] as String? ?? 'other',
      imageUrl: json['image'] as String? ?? '',
      rating: (rating['rate'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (rating['count'] as num?)?.toInt() ?? 0,
    );
  }

  /// The API has one photo per product, so the carousel shows it three times.
  List<String> get gallery => [imageUrl, imageUrl, imageUrl];

  /// Deep link shown in the Share sheet.
  String get deepLink => 'narxoz://store/product/$id';
}

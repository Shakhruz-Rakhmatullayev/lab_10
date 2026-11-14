import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/product.dart';

/// A failed request, with a message that is safe to show to the user.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Loads the catalog from the Fake Store REST API.
class ProductService {
  ProductService({http.Client? client}) : _client = client ?? http.Client();

  static final Uri productsUri = Uri.parse('https://fakestoreapi.com/products');
  static const timeout = Duration(seconds: 10);

  final http.Client _client;

  /// `GET /products` with a 10-second timeout.
  ///
  /// Throws [ApiException] for 404, 500, other status codes, timeouts,
  /// no connection (e.g. Airplane mode) and malformed JSON.
  Future<List<Product>> fetchProducts() async {
    try {
      final response = await _client.get(productsUri).timeout(timeout);

      switch (response.statusCode) {
        case 200:
          final decoded = jsonDecode(response.body);
          if (decoded is! List) {
            throw const ApiException('Unexpected response from the server.');
          }
          return decoded
              .whereType<Map<String, dynamic>>()
              .map(Product.fromJson)
              .toList();
        case 404:
          throw const ApiException('Products not found (404).');
        case 500:
          throw const ApiException('Server error (500). Please try later.');
        default:
          throw ApiException('Request failed (${response.statusCode}).');
      }
    } on TimeoutException {
      throw const ApiException(
        'The connection timed out after 10 seconds. Check your internet.',
      );
    } on SocketException {
      throw const ApiException(
        'No internet connection. Turn off Airplane mode and try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        'No internet connection. Turn off Airplane mode and try again.',
      );
    } on FormatException {
      throw const ApiException('Could not read the data from the server.');
    }
  }
}

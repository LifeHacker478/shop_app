import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop_app/model/http_exception.dart';
import 'package:shop_app/provider/product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [];
  List<Product> get items {
    return [..._items];
  }

  final String authToken;
  final String userId;

  Products(
    this.authToken,
    this._items,
    this.userId,
  );

  List<Product> get favoriteItems {
    return _items.where((element) => element.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> fetchAndSetProducts() async {
    var url =
        'https://fir-flutter-999a6.firebaseio.com/products.json?auth=$authToken';
    try {
      final res = await http.get(url);
      final extractedData = json.decode(res.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }
      url =
          'https://fir-flutter-999a6.firebaseio.com/userFavorites/$userId.json?auth=$authToken';
      final favoriteRes = await http.get(url);
      final favData = json.decode(favoriteRes.body);
      final List<Product> loadedProducts = [];
      extractedData.forEach(
        (key, value) {
          loadedProducts.add(
            Product(
              id: key,
              title: value['title'],
              imageUrl: value['imageUrl'],
              price: value['price'],
              description: value['description'],
              isFavorite: favData == null ? false : favData[key] ?? false,
            ),
          );
        },
      );
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> addProduct(Product product) async {
    final url =
        'https://fir-flutter-999a6.firebaseio.com/products.json?auth=$authToken';
    try {
      final res = await http.post(
        url,
        body: jsonEncode(
          {
            'title': product.title,
            'description': product.description,
            'imageUrl': product.imageUrl,
            'price': product.price,
          },
        ),
      );
      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(res.body)['name'],
      );
      _items.add(newProduct);
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final url =
        'https://fir-flutter-999a6.firebaseio.com/products/$id.json?auth=$authToken';
    await http.patch(url,
        body: json.encode({
          'title': newProduct.title,
          'description': newProduct.description,
          'imageUrl': newProduct.imageUrl,
          'price': newProduct.price,
        }));
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      _items[prodIndex] = newProduct;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    final url =
        'https://fir-flutter-999a6.firebaseio.com/products/$id.json?auth=$authToken';
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    var existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    notifyListeners();
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('could not delete product');
    }
    existingProduct = null;
  }
}

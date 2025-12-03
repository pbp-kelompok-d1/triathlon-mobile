// test/product_detail_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:triathlon_mobile/shop/models/product.dart';
import 'package:triathlon_mobile/shop/screens/product_detail.dart';

class FakeCookieRequest implements CookieRequest {
  Map<String, Cookie> _cookies = {};
  Map<String, String> _headers = {};
  bool _loggedIn = false;
  bool _initialized = false;
  Map<String, dynamic> _jsonData = {};
  late SharedPreferences _sharedPreferences;

  Future<dynamic> Function(String url)? onGet;
  Future<dynamic> Function(String url, dynamic body)? onPost;

  FakeCookieRequest() {
    SharedPreferences.setMockInitialValues({});
  }

  @override
  Map<String, Cookie> get cookies => _cookies;

  @override
  set cookies(Map<String, Cookie> value) => _cookies = value;

  @override
  bool get loggedIn => _loggedIn;

  @override
  set loggedIn(bool value) => _loggedIn = value;

  @override
  bool get initialized => _initialized;

  @override
  set initialized(bool value) => _initialized = value;

  @override
  Map<String, String> get headers => _headers;

  @override
  set headers(Map<String, String> value) => _headers = value;

  @override
  Map<String, dynamic> get jsonData => _jsonData;

  @override
  set jsonData(Map<String, dynamic> value) => _jsonData = value;

  @override
  SharedPreferences get local => _sharedPreferences;

  @override
  set local(SharedPreferences value) => _sharedPreferences = value;

  @override
  Future<dynamic> get(String url) async {
    if (onGet != null) return onGet!(url);
    return {};
  }

  @override
  Future<dynamic> post(String url, dynamic body) async {
    if (onPost != null) return onPost!(url, body);
    return {};
  }

  @override
  Future<dynamic> postJson(String url, dynamic body) async => {};

  @override
  Future<void> init() async {
    _initialized = true;
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  @override
  Future<dynamic> persist(String key) async => null;

  @override
  Future<dynamic> login(String url, dynamic body) async {
    _loggedIn = true;
    return {};
  }

  @override
  Future<dynamic> logout(String url) async {
    _loggedIn = false;
    return {};
  }

  @override
  void setCsrfTokenFromHeaders(Map<String, String> headers) {}

  @override
  Future<dynamic> multipart(
      String url,
      Map<String, String> body,
      Map<String, String> files,
      ) async =>
      {};

  @override
  Map<String, dynamic> getJsonData() => _jsonData;

  @override
  void setLoggedIn(bool value) => _loggedIn = value;

  @override
  void setCsrf(String csrfToken) {}

  @override
  void setSession(String sessionId) {}

  @override
  void setHeaders(Map<String, String> newHeaders) => _headers = newHeaders;

  void reset() {
    _cookies = {};
    _headers = {};
    _loggedIn = false;
    _initialized = false;
    _jsonData = {};
    onGet = null;
    onPost = null;
  }
}

void main() {
  late FakeCookieRequest fakeRequest;
  late Product testProduct;

  setUp(() {
    fakeRequest = FakeCookieRequest();
    testProduct = const Product(
      id: '101',
      sellerUsername: 'TokoTriathlon',
      name: 'Sepeda Road Bike',
      description: 'Sepeda balap ringan bahan karbon.',
      price: 15000000,
      stock: 5,
      category: 'cycling',
      thumbnail: 'http://via.placeholder.com/150',
    );
  });

  Widget createWidgetUnderTest({Product? product}) {
    return Provider<CookieRequest>.value(
      value: fakeRequest,
      child: MaterialApp(
        home: ProductDetailPage(product: product ?? testProduct),
      ),
    );
  }

  group('ProductDetailPage UI Tests', () {
    testWidgets('renders all product information correctly', (tester) async {
      fakeRequest.onGet = (_) async => {'in_wishlist': false};

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Sepeda Road Bike'), findsOneWidget);
        expect(find.textContaining('Rp15.000.000'), findsOneWidget);
        expect(find.text('Sepeda balap ringan bahan karbon.'), findsOneWidget);
        expect(find.text('Cycling'), findsOneWidget);
        expect(find.text('Sold by TokoTriathlon'), findsOneWidget);
        expect(find.text('5 available'), findsOneWidget);
      });
    });

    testWidgets('displays price and stock sections', (tester) async {
      fakeRequest.onGet = (_) async => {'in_wishlist': false};

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Price'), findsOneWidget);
        expect(find.text('Stock'), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
      });
    });

    testWidgets('displays empty description message when no description', (tester) async {
      fakeRequest.onGet = (_) async => {'in_wishlist': false};

      final emptyDescProduct = const Product(
        id: '999',
        name: 'Test',
        description: '',
        price: 1000,
        stock: 1,
        category: 'other',
        thumbnail: '',
        sellerUsername: 'Seller',
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createWidgetUnderTest(product: emptyDescProduct));
        await tester.pumpAndSettle();

        expect(find.text('No description available.'), findsOneWidget);
      });
    });
  });

  group('Add to Cart Tests', () {
    testWidgets('add to cart success shows green snackbar', (tester) async {
      fakeRequest.onGet = (_) async => {'in_wishlist': false};
      fakeRequest.onPost = (url, _) async {
        if (url.contains('/shop/api/cart/add/${testProduct.id}/')) {
          return {'status': 'success', 'message': 'Added to cart successfully'};
        }
        return {};
      };

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Find button by icon and text together
        final addToCartButton = find.widgetWithIcon(ElevatedButton, Icons.shopping_cart);
        expect(addToCartButton, findsOneWidget);

        await tester.tap(addToCartButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Added to cart'), findsOneWidget);
      });
    });

    testWidgets('add to cart failure shows error snackbar', (tester) async {
      fakeRequest.onGet = (_) async => {'in_wishlist': false};
      fakeRequest.onPost = (url, _) async {
        return {'status': 'error', 'message': 'Failed to add to cart'};
      };

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final addToCartButton = find.widgetWithIcon(ElevatedButton, Icons.shopping_cart);
        await tester.tap(addToCartButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Error:'), findsOneWidget);
      });
    });

    testWidgets('out of stock product disables add to cart button', (tester) async {
      fakeRequest.onGet = (_) async => {'in_wishlist': false};

      final outOfStockProduct = const Product(
        id: '102',
        name: 'Barang Habis',
        description: 'Habis.',
        price: 1000,
        stock: 0,
        category: 'other',
        thumbnail: '',
        sellerUsername: 'SellerA',
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createWidgetUnderTest(product: outOfStockProduct));
        await tester.pumpAndSettle();

        expect(find.text('0 available'), findsOneWidget);

        // Find the button and check if it's disabled
        final buttons = find.byType(ElevatedButton);
        expect(buttons, findsWidgets);

        final addToCartButton = find.widgetWithIcon(ElevatedButton, Icons.shopping_cart);
        if (addToCartButton.evaluate().isNotEmpty) {
          final button = tester.widget<ElevatedButton>(addToCartButton);
          expect(button.onPressed, isNull);
        }
      });
    });
  });

  group('Wishlist Tests', () {
    testWidgets('wishlist toggle from not in wishlist to in wishlist', (tester) async {
      var inWishlist = false;

      fakeRequest.onGet = (_) async => {'in_wishlist': inWishlist};
      fakeRequest.onPost = (_, __) async {
        inWishlist = !inWishlist;
        return {
          'success': true,
          'inWishlist': inWishlist,
          'message': 'Product added to wishlist',
        };
      };

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.favorite_border), findsOneWidget);

        await tester.tap(find.byIcon(Icons.favorite_border));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Check for SnackBar instead of exact text
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('wishlist'), findsWidgets);

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.favorite), findsOneWidget);
      });
    });

    testWidgets('wishlist toggle from in wishlist to not in wishlist', (tester) async {
      var inWishlist = true;

      fakeRequest.onGet = (_) async => {'in_wishlist': inWishlist};
      fakeRequest.onPost = (_, __) async {
        inWishlist = !inWishlist;
        return {
          'success': true,
          'inWishlist': inWishlist,
          'message': 'Product removed from wishlist',
        };
      };

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.favorite), findsOneWidget);

        await tester.tap(find.byIcon(Icons.favorite));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('wishlist'), findsWidgets);

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      });
    });
  });
}

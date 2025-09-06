import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/main.dart'; // Replace with your actual app import

void main() {
  group('Cart Unit Tests', () {
    test('Cart calculates total and count correctly', () {
      final cart = Cart();
      final product1 = Product(id: '1', name: 'Phone', price: 100.0, stock: 5);
      final product2 = Product(id: '2', name: 'Laptop', price: 900.0, stock: 2);

      cart.addProduct(product1);
      cart.addProduct(product2);

      expect(cart.total, 1000.0);
      expect(cart.count, 2);

      cart.removeProduct(product1);
      expect(cart.total, 900.0);

      cart.clear();
      expect(cart.count, 0);
      expect(cart.total, 0.0);
    });

    test('Cart items are immutable from outside', () {
      final cart = Cart();
      final product = Product(id: '1', name: 'Phone', price: 100.0, stock: 5);

      cart.addProduct(product);

      // Accessing cart.items should not allow modification
      expect(() => cart.items.add(product), throwsA(isA<UnsupportedError>()));
      expect(() => cart.items.remove(product), throwsA(isA<UnsupportedError>()));
    });

    test('Cart handles multiple identical products correctly', () {
      final cart = Cart();
      final product = Product(id: '1', name: 'Phone', price: 100.0, stock: 5);

      cart.addProduct(product);
      cart.addProduct(product); // Add same product again

      expect(cart.count, 2);
      expect(cart.total, 200.0);

      cart.removeProduct(product);
      expect(cart.count, 1);
      expect(cart.total, 100.0);
    });

    test('Cart clear removes all items', () {
      final cart = Cart();
      final product1 = Product(id: '1', name: 'Phone', price: 100.0, stock: 5);
      final product2 = Product(id: '2', name: 'Laptop', price: 900.0, stock: 2);

      cart.addProduct(product1);
      cart.addProduct(product2);

      expect(cart.count, 2);

      cart.clear();
      expect(cart.count, 0);
      expect(cart.total, 0.0);
    });
  });
}

import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String? description;

  Product({required this.id, required this.name, this.description});
}

class ProductCatalog extends StatefulWidget {
  const ProductCatalog({super.key});

  @override
  State<ProductCatalog> createState() => _ProductCatalogState();
}

class _ProductCatalogState extends State<ProductCatalog> {
  final List<Product> _products = [
    Product(id: '1', name: 'Phone', description: 'Smartphone with cool features'),
    Product(id: '2', name: 'Laptop', description: 'High performance laptop'),
    Product(id: '3', name: 'Tablet', description: 'Portable and lightweight'),
  ];

  void _addToCart(Product product) {
    // Your add to cart logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${product.name} to cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return ListTile(
          leading: SizedBox(
            width: 50, // constrain width to fix overflow
            child: const Icon(Icons.image), // placeholder instead of NetworkImage
          ),
          title: Text(product.name),
          subtitle: Text(product.description ?? ''),
          trailing: IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: () => _addToCart(product),
          ),
        );
      },
    );
  }
}

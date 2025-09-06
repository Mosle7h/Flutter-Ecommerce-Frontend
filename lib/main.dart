import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini E-Commerce',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// API Service Class
class ApiService {
  static const String baseUrl = 'http://localhost:8080'; // For web browser

  static Future<http.Response> register(String email, String password, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
        'name': name,
      }),
    );
    return response;
  }

  static Future<http.Response> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );
    return response;
  }

  static Future<List<Product>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));
    
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  static Future<http.Response> addProduct(Product product) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(product.toJson()),
    );
    return response;
  }

  static Future<List<Order>> getOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/orders'));
    
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  static Future<http.Response> placeOrder(Order order) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(order.toJson()),
    );
    return response;
  }
}

// Cart Model
class Cart {
  final List<Product> _items = [];

  List<Product> get items => List.unmodifiable(_items);

  void addProduct(Product product) {
    _items.add(product);
  }

  void removeProduct(Product product) {
    _items.remove(product);
  }

  void clear() {
    _items.clear();
  }

  double get total {
    return _items.fold(0.0, (sum, item) => sum + item.price);
  }

  int get count => _items.length;
}

// Authentication Screen
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isAdmin = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (!_isLogin)
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              if (_isLogin)
                CheckboxListTile(
                  title: const Text('Login as Admin'),
                  value: _isAdmin,
                  onChanged: (value) {
                    setState(() {
                      _isAdmin = value!;
                    });
                  },
                ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                          });
                          
                          try {
                            if (_isLogin) {
                              // Login logic
                              final response = await ApiService.login(
                                _emailController.text,
                                _passwordController.text,
                              );
                              
                              if (response.statusCode == 200) {
                                if (_isAdmin) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AdminDashboard(),
                                    ),
                                  );
                                } else {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserDashboard(),
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Login failed: ${response.body}'),
                                  ),
                                );
                              }
                            } else {
                              // Register logic
                              final response = await ApiService.register(
                                _emailController.text,
                                _passwordController.text,
                                _nameController.text,
                              );
                              
                              if (response.statusCode == 200) {
                                Navigator.pushReplacement(
                                  context,
                                    MaterialPageRoute(
                                      builder: (context) => UserDashboard(),
                                    ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Registration failed: ${response.body}'),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                              ),
                            );
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                      child: Text(_isLogin ? 'Login' : 'Register'),
                    ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(_isLogin
                    ? 'Need an account? Register'
                    : 'Have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Product Model
class Product {
  final String id;
  final String name;
  final double price;
  int stock;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.imageUrl = 'https://via.placeholder.com/150',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock'] ?? 0,
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/150',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
    };
  }
}

// Order Model
class Order {
  final String id;
  final DateTime date;
  final List<Product> products;
  final double total;

  Order({
    required this.id,
    required this.date,
    required this.products,
    required this.total,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? '',
      date: DateTime.parse(json['date']),
      products: (json['products'] as List<dynamic>?)
          ?.map((productJson) => Product.fromJson(productJson))
          .toList() ?? [],
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'products': products.map((product) => product.toJson()).toList(),
      'total': total,
    };
  }
}

// Sample Data (fallback if API fails)
List<Product> products = [
  Product(id: '1', name: 'Smartphone', price: 599.99, stock: 10),
  Product(id: '2', name: 'Laptop', price: 1299.99, stock: 3),
  Product(id: '3', name: 'Headphones', price: 99.99, stock: 0),
  Product(id: '4', name: 'Smart Watch', price: 249.99, stock: 7),
  Product(id: '5', name: 'Tablet', price: 399.99, stock: 2),
];

List<Order> orders = [
  Order(
    id: '1001',
    date: DateTime.now().subtract(const Duration(days: 2)),
    products: [products[0], products[2]],
    total: 699.98,
  ),
  Order(
    id: '1002',
    date: DateTime.now().subtract(const Duration(days: 5)),
    products: [products[1], products[3], products[4]],
    total: 1949.97,
  ),
];

// User Dashboard
class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _currentIndex = 0;
  final Cart _cart = Cart(); // Single cart instance for the entire dashboard

  @override
  Widget build(BuildContext context) {
    // Create screens with the shared cart
    final List<Widget> _screens = [
      ProductCatalog(cart: _cart), // Pass the same cart
      CartScreen(cart: _cart),     // Pass the same cart
      const OrderHistory(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Commerce App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuthScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shop),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Orders',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// Product Catalog Screen
class ProductCatalog extends StatefulWidget {
  final Cart cart;
  const ProductCatalog({super.key, required this.cart});

  @override
  State<ProductCatalog> createState() => _ProductCatalogState();
}

class _ProductCatalogState extends State<ProductCatalog> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ApiService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to sample data if API fails
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return ProductCard(product: product, cart: widget.cart);
      },
    );
  }
}

// Product Card Widget
class ProductCard extends StatelessWidget {
  final Product product;
  final Cart cart;

  const ProductCard({super.key, required this.product, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: Image.network(
          product.imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
        title: Text(product.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\$${product.price.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            product.stock == 0
                ? const Text(
                    'Out of stock',
                    style: TextStyle(color: Colors.red),
                  )
                : Text('In stock: ${product.stock}'),
          ],
        ),
        trailing: product.stock > 0
            ? IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: () {
                  cart.addProduct(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${product.name} to cart'),
                    ),
                  );
                },
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetail(product: product, cart: cart),
            ),
          );
        },
      ),
    );
  }
}

// Product Detail Screen
class ProductDetail extends StatelessWidget {
  final Product product;
  final Cart cart;

  const ProductDetail({super.key, required this.product, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(
                product.imageUrl,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              product.stock > 0 ? 'In Stock: ${product.stock}' : 'Out of Stock',
              style: TextStyle(
                color: product.stock > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (product.stock > 0)
              ElevatedButton(
                onPressed: () {
                  cart.addProduct(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${product.name} to cart'),
                    ),
                  );
                },
                child: const Text('Add to Cart'),
              ),
          ],
        ),
      ),
    );
  }
}

// Cart Screen
class CartScreen extends StatefulWidget {
  final Cart cart;
  const CartScreen({super.key, required this.cart});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: widget.cart.items.length,
            itemBuilder: (context, index) {
              final product = widget.cart.items[index];
              return ListTile(
                leading: Image.network(
                  product.imageUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
                title: Text(product.name),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    setState(() {
                      widget.cart.removeProduct(product);
                    });
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${widget.cart.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      // Create order from cart items
                      final order = Order(
                        id: '',
                        date: DateTime.now(),
                        products: widget.cart.items,
                        total: widget.cart.total,
                      );
                      
                      final response = await ApiService.placeOrder(order);
                      
                      if (response.statusCode == 200) {
                        setState(() {
                          widget.cart.clear();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order placed successfully!'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to place order: ${response.body}'),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error placing order: $e'),
                        ),
                      );
                    }
                  },
                  child: const Text('Place Order'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Order History Screen
class OrderHistory extends StatefulWidget {
  const OrderHistory({super.key});

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await ApiService.getOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to sample data if API fails
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return ListView.builder(
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text('Order #${order.id}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('yyyy-MM-dd – kk:mm').format(order.date)),
                Text('Total: \$${order.total.toStringAsFixed(2)}'),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // View order details
            },
          ),
        );
      },
    );
  }
}

// Admin Dashboard
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const ManageProducts(),
    const ViewOrders(),
    const LowStockAlert(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuthScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Low Stock',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddProductDialog(),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// Manage Products Screen
class ManageProducts extends StatefulWidget {
  const ManageProducts({super.key});

  @override
  State<ManageProducts> createState() => _ManageProductsState();
}

class _ManageProductsState extends State<ManageProducts> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ApiService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to sample data if API fails
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return ListTile(
          leading: Image.network(
            product.imageUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
          title: Text(product.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('\$${product.price.toStringAsFixed(2)}'),
              Text('Stock: ${product.stock}'),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Edit product
            },
          ),
        );
      },
    );
  }
}

// View Orders Screen
class ViewOrders extends StatefulWidget {
  const ViewOrders({super.key});

  @override
  State<ViewOrders> createState() => _ViewOrdersState();
}

class _ViewOrdersState extends State<ViewOrders> {
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await ApiService.getOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to sample data if API fails
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return ListView.builder(
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text('Order #${order.id}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('yyyy-MM-dd – kk:mm').format(order.date)),
                Text('Total: \$${order.total.toStringAsFixed(2)}'),
                Text('Items: ${order.products.length}'),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // View order details
            },
          ),
        );
      },
    );
  }
}

// Low Stock Alert Screen
class LowStockAlert extends StatefulWidget {
  const LowStockAlert({super.key});

  @override
  State<LowStockAlert> createState() => _LowStockAlertState();
}

class _LowStockAlertState extends State<LowStockAlert> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ApiService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to sample data if API fails
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final lowStockProducts = _products.where((product) => product.stock < 5).toList();

    if (lowStockProducts.isEmpty) {
      return const Center(
        child: Text('No low stock items'),
      );
    }

    return ListView.builder(
      itemCount: lowStockProducts.length,
      itemBuilder: (context, index) {
        final product = lowStockProducts[index];
        return ListTile(
          leading: Image.network(
            product.imageUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
          title: Text(product.name),
          subtitle: Text('Stock: ${product.stock}'),
          trailing: const Icon(Icons.warning, color: Colors.orange),
        );
      },
    );
  }
}

// Add Product Dialog
class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Product'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a product name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(labelText: 'Stock'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter stock quantity';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isLoading = true;
                    });
                    
                    try {
                      final product = Product(
                        id: '',
                        name: _nameController.text,
                        price: double.parse(_priceController.text),
                        stock: int.parse(_stockController.text),
                      );
                      
                      final response = await ApiService.addProduct(product);
                      
                      if (response.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Product added successfully'),
                          ),
                        );
                        Navigator.of(context).pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to add product: ${response.body}'),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error adding product: $e'),
                        ),
                      );
                    } finally {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
                child: const Text('Add Product'),
              ),
      ],
    );
  }
}
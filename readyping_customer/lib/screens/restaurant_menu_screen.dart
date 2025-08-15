import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/restaurant_provider.dart';
import '../providers/order_provider.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';

class RestaurantMenuScreen extends StatefulWidget {
  final String? restaurantId;
  final String? qrCode;

  const RestaurantMenuScreen({
    super.key,
    this.restaurantId,
    this.qrCode,
  });

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  String? _selectedCategory;
  final Map<String, int> _cart = {};
  double _cartTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  void _loadRestaurantData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final restaurantProvider = context.read<RestaurantProvider>();
      
      if (widget.qrCode != null) {
        // Load restaurant by QR code
        restaurantProvider.getRestaurantByQR(widget.qrCode!);
      } else if (widget.restaurantId != null) {
        // Load restaurant by ID
        restaurantProvider.getRestaurant(widget.restaurantId!);
      } else {
        // Load demo data
        restaurantProvider.generateDemoData();
      }
    });
  }

  void _addToCart(MenuItem item) {
    setState(() {
      _cart[item.id] = (_cart[item.id] ?? 0) + 1;
      _updateCartTotal();
    });
  }

  void _removeFromCart(String itemId) {
    setState(() {
      if (_cart[itemId] != null) {
        if (_cart[itemId]! > 1) {
          _cart[itemId] = _cart[itemId]! - 1;
        } else {
          _cart.remove(itemId);
        }
        _updateCartTotal();
      }
    });
  }

  void _updateCartTotal() {
    final restaurantProvider = context.read<RestaurantProvider>();
    _cartTotal = 0.0;
    
    for (final entry in _cart.entries) {
      final item = restaurantProvider.menuItems.firstWhere(
        (item) => item.id == entry.key,
        orElse: () => MenuItem(
          id: entry.key,
          name: 'Unknown Item',
          description: '',
          price: 0.0,
          category: '',
          isAvailable: true,
          tags: [],
        ),
      );
      _cartTotal += item.price * entry.value;
    }
  }

  void _showCart() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CartBottomSheet(
        cart: _cart,
        total: _cartTotal,
        onRemove: _removeFromCart,
        onPlaceOrder: _placeOrder,
      ),
    );
  }

  void _placeOrder() {
    if (_cart.isEmpty) return;

    final restaurantProvider = context.read<RestaurantProvider>();
    final restaurant = restaurantProvider.selectedRestaurant;
    
    if (restaurant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create order items
    final orderItems = _cart.entries.map((entry) {
      final item = restaurantProvider.menuItems.firstWhere(
        (item) => item.id == entry.key,
      );
      return {
        'menuItemId': item.id,
        'name': item.name,
        'quantity': entry.value,
        'price': item.price,
      };
    }).toList();

    // Create order data
    final orderData = {
      'restaurantId': restaurant.id,
      'restaurantName': restaurant.name,
      'items': orderItems,
      'totalAmount': _cartTotal,
    };

    // Place order
    context.read<OrderProvider>().createOrder(orderData).then((success) {
      if (success) {
        Navigator.of(context).pop(); // Close cart
        _showOrderSuccess();
        setState(() {
          _cart.clear();
          _cartTotal = 0.0;
        });
      }
    });
  }

  void _showOrderSuccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Placed Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green[600],
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your order has been placed and will be ready soon.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ₹${_cartTotal.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to home
            },
            child: const Text('View Orders'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to home
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<RestaurantProvider>(
        builder: (context, restaurantProvider, child) {
          if (restaurantProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            );
          }

          if (restaurantProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load menu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    restaurantProvider.error!,
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final restaurant = restaurantProvider.selectedRestaurant;
          if (restaurant == null) {
            return const Center(
              child: Text('Restaurant not found'),
            );
          }

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppTheme.primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 64,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          restaurant.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber[300],
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${restaurant.rating.toStringAsFixed(1)} (${restaurant.reviewCount})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              // Categories
              SliverToBoxAdapter(
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: restaurantProvider.categories.length,
                    itemBuilder: (context, index) {
                      final category = restaurantProvider.categories[index];
                      final isSelected = _selectedCategory == category;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = isSelected ? null : category;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppTheme.primaryColor 
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected 
                                    ? AppTheme.primaryColor 
                                    : AppTheme.primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected 
                                    ? Colors.white 
                                    : AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Menu Items
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final items = restaurantProvider.filteredMenuItems;
                      if (index >= items.length) return null;
                      
                      final item = items[index];
                      final quantity = _cart[item.id] ?? 0;
                      
                      return _MenuItemCard(
                        item: item,
                        quantity: quantity,
                        onAdd: () => _addToCart(item),
                        onRemove: () => _removeFromCart(item.id),
                      );
                    },
                    childCount: restaurantProvider.filteredMenuItems.length,
                  ),
                ),
              ),

              // Bottom padding for cart button
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showCart,
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                'Cart (${_cart.values.fold(0, (sum, quantity) => sum + quantity)}) - ₹${_cartTotal.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _MenuItemCard({
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Item Image/Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.restaurant,
                color: AppTheme.primaryColor,
                size: 40,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const Spacer(),
                      if (quantity > 0) ...[
                        IconButton(
                          onPressed: onRemove,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppTheme.primaryColor,
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      IconButton(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartBottomSheet extends StatelessWidget {
  final Map<String, int> cart;
  final double total;
  final Function(String) onRemove;
  final VoidCallback onPlaceOrder;

  const _CartBottomSheet({
    required this.cart,
    required this.total,
    required this.onRemove,
    required this.onPlaceOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Your Cart',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${cart.values.fold(0, (sum, quantity) => sum + quantity)} items',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Cart Items
          if (cart.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: cart.length,
                itemBuilder: (context, index) {
                  final itemId = cart.keys.elementAt(index);
                  final quantity = cart[itemId]!;
                  
                  // TODO: Get item details from provider
                  final itemName = 'Item $itemId';
                  final itemPrice = 100.0; // TODO: Get from provider
                  
                  return ListTile(
                    title: Text(itemName),
                    subtitle: Text('₹${itemPrice.toStringAsFixed(0)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('x$quantity'),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => onRemove(itemId),
                          icon: const Icon(Icons.remove_circle_outline),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          
          // Total and Place Order
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cart.isEmpty ? null : onPlaceOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Place Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
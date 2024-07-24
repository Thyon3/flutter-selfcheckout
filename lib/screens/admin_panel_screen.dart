import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/widgets/chart_widgets.dart';
import 'package:selfcheckoutapp/widgets/responsive_widgets.dart';
import 'package:selfcheckoutapp/widgets/form_widgets.dart';
import 'package:selfcheckoutapp/utils/app_utils.dart';
import 'package:selfcheckoutapp/constants.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<User> _users = [];
  List<Product> _products = [];
  List<Order> _orders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading admin data
    await Future.delayed(Duration(milliseconds: 1000));

    setState(() {
      _users = _generateMockUsers();
      _products = _generateMockProducts();
      _orders = _generateMockOrders();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAdminData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Dashboard'),
            Tab(text: 'Users'),
            Tab(text: 'Products'),
            Tab(text: 'Orders'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildUsersTab(),
                _buildProductsTab(),
                _buildOrdersTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    return ResponsiveLayout(
      mobile: _buildDashboardMobile(),
      tablet: _buildDashboardTablet(),
      desktop: _buildDashboardDesktop(),
    );
  }

  Widget _buildDashboardMobile() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAdminStats(),
          SizedBox(height: 24),
          _buildQuickActions(),
          SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildDashboardTablet() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          _buildAdminStats(),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildQuickActions()),
              SizedBox(width: 24),
              Expanded(child: _buildRecentActivity()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardDesktop() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          _buildAdminStats(),
          SizedBox(height: 32),
          Row(
            children: [
              Expanded(flex: 2, child: _buildQuickActions()),
              SizedBox(width: 32),
              Expanded(child: _buildRecentActivity()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStats() {
    return ResponsiveGrid(
      mobileColumns: 2,
      tabletColumns: 4,
      desktopColumns: 4,
      spacing: 16,
      children: [
        StatCard(
          title: 'Total Users',
          value: '${_users.length}',
          subtitle: '+12 this week',
          color: Colors.blue,
          icon: Icons.people,
          showProgress: true,
          progress: 0.75,
        ),
        StatCard(
          title: 'Total Products',
          value: '${_products.length}',
          subtitle: '+5 this week',
          color: Colors.green,
          icon: Icons.inventory,
          showProgress: true,
          progress: 0.82,
        ),
        StatCard(
          title: 'Total Orders',
          value: '${_orders.length}',
          subtitle: '+23 this week',
          color: Colors.orange,
          icon: Icons.shopping_cart,
          showProgress: true,
          progress: 0.68,
        ),
        StatCard(
          title: 'Revenue',
          value: 'Rs 45,230',
          subtitle: '+8.3% this week',
          color: Colors.purple,
          icon: Icons.trending_up,
          showProgress: true,
          progress: 0.91,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Constants.boldHeadingAppBar.copyWith(fontSize: 18),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: Text('Add User'),
                  avatar: Icon(Icons.person_add, size: 18),
                  onPressed: _addUser,
                ),
                ActionChip(
                  label: Text('Add Product'),
                  avatar: Icon(Icons.add_shopping_cart, size: 18),
                  onPressed: _addProduct,
                ),
                ActionChip(
                  label: Text('View Reports'),
                  avatar: Icon(Icons.assessment, size: 18),
                  onPressed: _viewReports,
                ),
                ActionChip(
                  label: Text('System Backup'),
                  avatar: Icon(Icons.backup, size: 18),
                  onPressed: _systemBackup,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Constants.boldHeadingAppBar.copyWith(fontSize: 18),
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                final activity = _getRecentActivities()[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: activity['color'] as Color,
                    child: Icon(activity['icon'] as IconData, color: Colors.white, size: 20),
                  ),
                  title: Text(activity['title'] as String),
                  subtitle: Text(activity['subtitle'] as String),
                  trailing: Text(
                    AppUtils.getRelativeTime(activity['timestamp'] as DateTime),
                    style: Constants.smallText,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: SearchField(
                  hintText: 'Search users...',
                  onChanged: (value) {
                    // Implement search
                  },
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _addUser,
                icon: Icon(Icons.add),
                label: Text('Add User'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildUsersTable(),
        ),
      ],
    );
  }

  Widget _buildUsersTable() {
    return Card(
      margin: EdgeInsets.all(16),
      child: DataTable(
        columns: [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Joined')),
          DataColumn(label: Text('Actions')),
        ],
        rows: _users.map((user) {
          return DataRow(
            cells: [
              DataCell(Text(user.name)),
              DataCell(Text(user.email)),
              DataCell(Text(user.role)),
              DataCell(
                StatusBadge(
                  status: user.status,
                  color: user.status == 'Active' ? Colors.green : Colors.red,
                ),
              ),
              DataCell(Text(AppUtils.formatDate(user.joinedDate))),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, size: 18),
                      onPressed: () => _editUser(user),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, size: 18),
                      onPressed: () => _deleteUser(user),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: SearchField(
                  hintText: 'Search products...',
                  onChanged: (value) {
                    // Implement search
                  },
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _addProduct,
                icon: Icon(Icons.add),
                label: Text('Add Product'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildProductsTable(),
        ),
      ],
    );
  }

  Widget _buildProductsTable() {
    return Card(
      margin: EdgeInsets.all(16),
      child: DataTable(
        columns: [
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Price')),
          DataColumn(label: Text('Stock')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: _products.map((product) {
          return DataRow(
            cells: [
              DataCell(Text(product.name)),
              DataCell(Text(product.category)),
              DataCell(Text('Rs ${product.price.toStringAsFixed(2)}')),
              DataCell(Text('${product.stock}')),
              DataCell(
                StatusBadge(
                  status: product.status,
                  color: _getStockStatusColor(product.stock),
                ),
              ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, size: 18),
                      onPressed: () => _editProduct(product),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, size: 18),
                      onPressed: () => _deleteProduct(product),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: SearchField(
                  hintText: 'Search orders...',
                  onChanged: (value) {
                    // Implement search
                  },
                ),
              ),
              SizedBox(width: 16),
              DropdownButtonFormField<String>(
                value: 'All',
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: ['All', 'Pending', 'Processing', 'Completed', 'Cancelled'].map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) {
                  // Implement filter
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildOrdersTable(),
        ),
      ],
    );
  }

  Widget _buildOrdersTable() {
    return Card(
      margin: EdgeInsets.all(16),
      child: DataTable(
        columns: [
          DataColumn(label: Text('Order ID')),
          DataColumn(label: Text('Customer')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Actions')),
        ],
        rows: _orders.map((order) {
          return DataRow(
            cells: [
              DataCell(Text('#${order.id}')),
              DataCell(Text(order.customerName)),
              DataCell(Text('Rs ${order.amount.toStringAsFixed(2)}')),
              DataCell(
                StatusBadge(
                  status: order.status,
                  color: _getOrderStatusColor(order.status),
                ),
              ),
              DataCell(Text(AppUtils.formatDate(order.date))),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.visibility, size: 18),
                      onPressed: () => _viewOrder(order),
                      tooltip: 'View',
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, size: 18),
                      onPressed: () => _editOrder(order),
                      tooltip: 'Edit',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Settings',
            style: Constants.boldHeadingAppBar.copyWith(fontSize: 24),
          ),
          SizedBox(height: 24),
          _buildGeneralSettings(),
          SizedBox(height: 24),
          _buildNotificationSettings(),
          SizedBox(height: 24),
          _buildSecuritySettings(),
          SizedBox(height: 24),
          _buildBackupSettings(),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Settings',
              style: Constants.boldText.copyWith(fontSize: 18),
            ),
            SizedBox(height: 16),
            SwitchFormField(
              title: 'Maintenance Mode',
              subtitle: 'Put the app in maintenance mode',
              value: false,
              onChanged: (value) {
                // Handle maintenance mode
              },
            ),
            SizedBox(height: 16),
            SwitchFormField(
              title: 'Debug Mode',
              subtitle: 'Enable debug logging',
              value: false,
              onChanged: (value) {
                // Handle debug mode
              },
            ),
            SizedBox(height: 16),
            DropdownFormField<String>(
              label: 'Default Language',
              value: 'English',
              items: ['English', 'Sinhala', 'Tamil'].map((lang) {
                return DropdownMenuItem(value: lang, child: Text(lang));
              }).toList(),
              onChanged: (value) {
                // Handle language change
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: Constants.boldText.copyWith(fontSize: 18),
            ),
            SizedBox(height: 16),
            SwitchFormField(
              title: 'Email Notifications',
              subtitle: 'Send email notifications to users',
              value: true,
              onChanged: (value) {
                // Handle email notifications
              },
            ),
            SizedBox(height: 16),
            SwitchFormField(
              title: 'Push Notifications',
              subtitle: 'Send push notifications to users',
              value: true,
              onChanged: (value) {
                // Handle push notifications
              },
            ),
            SizedBox(height: 16),
            SwitchFormField(
              title: 'SMS Notifications',
              subtitle: 'Send SMS notifications to users',
              value: false,
              onChanged: (value) {
                // Handle SMS notifications
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Settings',
              style: Constants.boldText.copyWith(fontSize: 18),
            ),
            SizedBox(height: 16),
            SwitchFormField(
              title: 'Two-Factor Authentication',
              subtitle: 'Require 2FA for admin accounts',
              value: true,
              onChanged: (value) {
                // Handle 2FA
              },
            ),
            SizedBox(height: 16),
            SwitchFormField(
              title: 'Session Timeout',
              subtitle: 'Automatically log out inactive users',
              value: true,
              onChanged: (value) {
                // Handle session timeout
              },
            ),
            SizedBox(height: 16),
            NumberField(
              label: 'Session Timeout (minutes)',
              value: 30,
              isInteger: true,
              min: 5,
              max: 120,
              onChanged: (value) {
                // Handle session timeout value
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSettings() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup Settings',
              style: Constants.boldText.copyWith(fontSize: 18),
            ),
            SizedBox(height: 16),
            SwitchFormField(
              title: 'Auto Backup',
              subtitle: 'Automatically backup data daily',
              value: true,
              onChanged: (value) {
                // Handle auto backup
              },
            ),
            SizedBox(height: 16),
            DropdownFormField<String>(
              label: 'Backup Frequency',
              value: 'Daily',
              items: ['Hourly', 'Daily', 'Weekly', 'Monthly'].map((freq) {
                return DropdownMenuItem(value: freq, child: Text(freq));
              }).toList(),
              onChanged: (value) {
                // Handle backup frequency
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _manualBackup,
                    icon: Icon(Icons.backup),
                    label: Text('Manual Backup'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _restoreBackup,
                    icon: Icon(Icons.restore),
                    label: Text('Restore Backup'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStockStatusColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock < 10) return Colors.orange;
    return Colors.green;
  }

  Color _getOrderStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Processing':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _getRecentActivities() {
    return [
      {
        'title': 'New user registered',
        'subtitle': 'John Doe joined the platform',
        'icon': Icons.person_add,
        'color': Colors.green,
        'timestamp': DateTime.now().subtract(Duration(hours: 2)),
      },
      {
        'title': 'Product updated',
        'subtitle': 'Fresh Tomatoes price changed',
        'icon': Icons.edit,
        'color': Colors.blue,
        'timestamp': DateTime.now().subtract(Duration(hours: 4)),
      },
      {
        'title': 'Order completed',
        'subtitle': 'Order #1234 was delivered',
        'icon': Icons.check_circle,
        'color': Colors.green,
        'timestamp': DateTime.now().subtract(Duration(hours: 6)),
      },
      {
        'title': 'System backup',
        'subtitle': 'Automatic backup completed',
        'icon': Icons.backup,
        'color': Colors.purple,
        'timestamp': DateTime.now().subtract(Duration(hours: 12)),
      },
      {
        'title': 'Low stock alert',
        'subtitle': '5 products are running low on stock',
        'icon': Icons.warning,
        'color': Colors.orange,
        'timestamp': DateTime.now().subtract(Duration(days: 1)),
      },
    ];
  }

  List<User> _generateMockUsers() {
    return [
      User(id: '1', name: 'John Doe', email: 'john@example.com', role: 'Admin', status: 'Active', joinedDate: DateTime.now().subtract(Duration(days: 30))),
      User(id: '2', name: 'Jane Smith', email: 'jane@example.com', role: 'User', status: 'Active', joinedDate: DateTime.now().subtract(Duration(days: 15))),
      User(id: '3', name: 'Bob Johnson', email: 'bob@example.com', role: 'User', status: 'Inactive', joinedDate: DateTime.now().subtract(Duration(days: 45))),
      User(id: '4', name: 'Alice Brown', email: 'alice@example.com', role: 'Manager', status: 'Active', joinedDate: DateTime.now().subtract(Duration(days: 60))),
      User(id: '5', name: 'Charlie Wilson', email: 'charlie@example.com', role: 'User', status: 'Active', joinedDate: DateTime.now().subtract(Duration(days: 7))),
    ];
  }

  List<Product> _generateMockProducts() {
    return [
      Product(id: '1', name: 'Fresh Tomatoes', category: 'Vegetables', price: 45.50, stock: 150, status: 'In Stock'),
      Product(id: '2', name: 'Organic Apples', category: 'Fruits', price: 120.00, stock: 5, status: 'Low Stock'),
      Product(id: '3', name: 'Whole Milk', category: 'Dairy', price: 85.00, stock: 0, status: 'Out of Stock'),
      Product(id: '4', name: 'Bread', category: 'Bakery', price: 65.00, stock: 80, status: 'In Stock'),
      Product(id: '5', name: 'Eggs', category: 'Dairy', price: 180.00, stock: 25, status: 'In Stock'),
    ];
  }

  List<Order> _generateMockOrders() {
    return [
      Order(id: '1234', customerName: 'John Doe', amount: 1250.50, status: 'Completed', date: DateTime.now().subtract(Duration(days: 1))),
      Order(id: '1235', customerName: 'Jane Smith', amount: 890.25, status: 'Processing', date: DateTime.now().subtract(Duration(hours: 6))),
      Order(id: '1236', customerName: 'Bob Johnson', amount: 450.75, status: 'Pending', date: DateTime.now().subtract(Duration(hours: 12))),
      Order(id: '1237', customerName: 'Alice Brown', amount: 2100.00, status: 'Completed', date: DateTime.now().subtract(Duration(days: 2))),
      Order(id: '1238', customerName: 'Charlie Wilson', amount: 675.50, status: 'Cancelled', date: DateTime.now().subtract(Duration(days: 3))),
    ];
  }

  void _addUser() {
    AppUtils.showSnackBar(context, 'Add user functionality coming soon!');
  }

  void _addProduct() {
    AppUtils.showSnackBar(context, 'Add product functionality coming soon!');
  }

  void _viewReports() {
    AppUtils.showSnackBar(context, 'Reports functionality coming soon!');
  }

  void _systemBackup() {
    AppUtils.showSnackBar(context, 'System backup initiated...');
  }

  void _editUser(User user) {
    AppUtils.showSnackBar(context, 'Edit user: ${user.name}');
  }

  void _deleteUser(User user) {
    AppUtils.showConfirmationDialog(
      context,
      'Delete User',
      'Are you sure you want to delete ${user.name}?',
    ).then((confirmed) {
      if (confirmed) {
        setState(() {
          _users.removeWhere((u) => u.id == user.id);
        });
        AppUtils.showSuccessSnackBar(context, 'User deleted successfully');
      }
    });
  }

  void _editProduct(Product product) {
    AppUtils.showSnackBar(context, 'Edit product: ${product.name}');
  }

  void _deleteProduct(Product product) {
    AppUtils.showConfirmationDialog(
      context,
      'Delete Product',
      'Are you sure you want to delete ${product.name}?',
    ).then((confirmed) {
      if (confirmed) {
        setState(() {
          _products.removeWhere((p) => p.id == product.id);
        });
        AppUtils.showSuccessSnackBar(context, 'Product deleted successfully');
      }
    });
  }

  void _viewOrder(Order order) {
    AppUtils.showSnackBar(context, 'View order: #${order.id}');
  }

  void _editOrder(Order order) {
    AppUtils.showSnackBar(context, 'Edit order: #${order.id}');
  }

  void _openSettings() {
    AppUtils.showSnackBar(context, 'Settings functionality coming soon!');
  }

  void _manualBackup() {
    AppUtils.showSnackBar(context, 'Manual backup initiated...');
  }

  void _restoreBackup() {
    AppUtils.showSnackBar(context, 'Restore backup functionality coming soon!');
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final DateTime joinedDate;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.joinedDate,
  });
}

class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final String status;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.status,
  });
}

class Order {
  final String id;
  final String customerName;
  final double amount;
  final String status;
  final DateTime date;

  Order({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.status,
    required this.date,
  });
}

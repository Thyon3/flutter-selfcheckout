import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/services/firebase_services.dart';
import 'package:selfcheckoutapp/widgets/advanced_widgets.dart';
import 'package:selfcheckoutapp/widgets/responsive_widgets.dart';
import 'package:selfcheckoutapp/utils/app_utils.dart';
import 'package:selfcheckoutapp/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseServices _firebaseServices = FirebaseServices();
  
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _recentPurchases = [];
  List<Map<String, dynamic>> _favoriteItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      final userData = await _firebaseServices.getUserData(_firebaseServices.userId!);
      final purchasesSnapshot = await _firebaseServices.usersCartHistoryRef
          .doc(_firebaseServices.userId!)
          .collection('purchases')
          .orderBy('date', descending: true)
          .limit(5)
          .get();
      
      setState(() {
        _userData = userData.data();
        _recentPurchases = purchasesSnapshot.docs.map((doc) => doc.data()).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppUtils.showErrorSnackBar(context, 'Failed to load dashboard data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Analytics'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAnalyticsTab(),
                _buildActivityTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return ResponsiveLayout(
      mobile: _buildOverviewMobile(),
      tablet: _buildOverviewTablet(),
      desktop: _buildOverviewDesktop(),
    );
  }

  Widget _buildOverviewMobile() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          SizedBox(height: 16),
          _buildQuickStatsGrid(),
          SizedBox(height: 16),
          _buildRecentPurchasesCard(),
          SizedBox(height: 16),
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildOverviewTablet() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildWelcomeCard()),
              SizedBox(width: 16),
              Expanded(child: _buildQuickStatsGrid()),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildRecentPurchasesCard()),
              SizedBox(width: 16),
              Expanded(child: _buildQuickActionsCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewDesktop() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(flex: 2, child: _buildWelcomeCard()),
              SizedBox(width: 24),
              Expanded(child: _buildQuickStatsGrid()),
            ],
          ),
          SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _buildRecentPurchasesCard()),
              SizedBox(width: 24),
              Expanded(child: _buildQuickActionsCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final userName = _userData?['name'] ?? 'User';
    final greeting = AppUtils.getGreeting();

    return AnimatedCard(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Constants.primaryColor, Constants.accentColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, $userName!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Welcome back to your shopping dashboard',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  AppUtils.formatDate(DateTime.now()),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    return ResponsiveGrid(
      mobileColumns: 2,
      tabletColumns: 2,
      desktopColumns: 2,
      spacing: 12,
      children: [
        CountCard(
          title: 'Total Purchases',
          count: _recentPurchases.length,
          color: Colors.blue,
          icon: Icons.shopping_bag,
        ),
        CountCard(
          title: 'Favorites',
          count: _favoriteItems.length,
          color: Colors.red,
          icon: Icons.favorite,
        ),
        CountCard(
          title: 'This Month',
          count: _getThisMonthPurchases(),
          color: Colors.green,
          icon: Icons.trending_up,
        ),
        CountCard(
          title: 'Saved Items',
          count: _getSavedItemsCount(),
          color: Colors.orange,
          icon: Icons.bookmark,
        ),
      ],
    );
  }

  Widget _buildRecentPurchasesCard() {
    return InfoCard(
      title: 'Recent Purchases',
      subtitle: 'Your latest shopping activity',
      trailing: Icon(Icons.arrow_forward),
      onTap: () {
        // Navigate to purchase history
      },
      child: Column(
        children: _recentPurchases.take(3).map((purchase) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Constants.primaryColor.withOpacity(0.1),
              child: Icon(Icons.receipt, color: Constants.primaryColor),
            ),
            title: Text(
              purchase['total'] != null 
                  ? AppUtils.formatPrice(purchase['total'].toDouble())
                  : 'N/A',
              style: Constants.boldText,
            ),
            subtitle: Text(
              purchase['date'] != null
                  ? AppUtils.formatDateTime(DateTime.parse(purchase['date']))
                  : 'Unknown date',
            ),
            trailing: StatusBadge(
              status: purchase['status'] ?? 'completed',
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return InfoCard(
      title: 'Quick Actions',
      subtitle: 'Common tasks and shortcuts',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ActionChip(
            label: Text('New Shopping'),
            avatar: Icon(Icons.add_shopping_cart, size: 18),
            onPressed: () {
              // Navigate to shopping cart
            },
          ),
          ActionChip(
            label: Text('View History'),
            avatar: Icon(Icons.history, size: 18),
            onPressed: () {
              // Navigate to history
            },
          ),
          ActionChip(
            label: Text('Manage List'),
            avatar: Icon(Icons.list, size: 18),
            onPressed: () {
              // Navigate to shopping list
            },
          ),
          ActionChip(
            label: Text('Settings'),
            avatar: Icon(Icons.settings, size: 18),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shopping Analytics',
            style: Constants.boldHeadingAppBar.copyWith(fontSize: 24),
          ),
          SizedBox(height: 24),
          _buildSpendingChart(),
          SizedBox(height: 24),
          _buildCategoryBreakdown(),
          SizedBox(height: 24),
          _buildMonthlyTrends(),
        ],
      ),
    );
  }

  Widget _buildSpendingChart() {
    return InfoCard(
      title: 'Spending Overview',
      subtitle: 'Your shopping expenses over time',
      child: Container(
        height: 200,
        child: Center(
          child: Text('Spending Chart\n(Chart implementation needed)'),
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return InfoCard(
      title: 'Category Breakdown',
      subtitle: 'Spending by product category',
      child: Container(
        height: 200,
        child: Center(
          child: Text('Category Chart\n(Chart implementation needed)'),
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildMonthlyTrends() {
    return InfoCard(
      title: 'Monthly Trends',
      subtitle: 'Your shopping patterns',
      child: Container(
        height: 200,
        child: Center(
          child: Text('Trends Chart\n(Chart implementation needed)'),
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Constants.boldHeadingAppBar.copyWith(fontSize: 24),
          ),
          SizedBox(height: 24),
          _buildActivityList(),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    final activities = _generateMockActivities();
    
    if (activities.isEmpty) {
      return EmptyState(
        title: 'No recent activity',
        subtitle: 'Your shopping activity will appear here',
        icon: Icon(Icons.history, size: 64, color: Colors.grey[400]),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return ActivityTile(activity: activity);
      },
    );
  }

  List<Map<String, dynamic>> _generateMockActivities() {
    return [
      {
        'type': 'purchase',
        'title': 'Completed Purchase',
        'description': 'Total: Rs 1,250.00',
        'timestamp': DateTime.now().subtract(Duration(hours: 2)),
        'icon': Icons.check_circle,
        'color': Colors.green,
      },
      {
        'type': 'cart',
        'title': 'Added to Cart',
        'description': 'Fresh Vegetables x3',
        'timestamp': DateTime.now().subtract(Duration(hours: 5)),
        'icon': Icons.add_shopping_cart,
        'color': Colors.blue,
      },
      {
        'type': 'list',
        'title': 'Updated Shopping List',
        'description': 'Added 5 new items',
        'timestamp': DateTime.now().subtract(Duration(days: 1)),
        'icon': Icons.list,
        'color': Colors.orange,
      },
    ];
  }

  int _getThisMonthPurchases() {
    final now = DateTime.now();
    return _recentPurchases.where((purchase) {
      if (purchase['date'] == null) return false;
      final purchaseDate = DateTime.parse(purchase['date']);
      return purchaseDate.year == now.year && purchaseDate.month == now.month;
    }).length;
  }

  int _getSavedItemsCount() {
    // Mock implementation - would get from actual saved items
    return 12;
  }
}

class ActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: (activity['color'] as Color).withOpacity(0.1),
          child: Icon(
            activity['icon'] as IconData,
            color: activity['color'] as Color,
          ),
        ),
        title: Text(
          activity['title'] as String,
          style: Constants.boldText,
        ),
        subtitle: Text(activity['description'] as String),
        trailing: Text(
          AppUtils.getRelativeTime(activity['timestamp'] as DateTime),
          style: Constants.smallText.copyWith(color: Colors.grey[600]),
        ),
      ),
    );
  }
}

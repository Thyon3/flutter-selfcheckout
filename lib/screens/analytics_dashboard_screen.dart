import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/widgets/chart_widgets.dart';
import 'package:selfcheckoutapp/widgets/responsive_widgets.dart';
import 'package:selfcheckoutapp/utils/app_utils.dart';
import 'package:selfcheckoutapp/constants.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({Key? key}) : super(key: key);

  @override
  _AnalyticsDashboardScreenState createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Week';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeDateRange();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeDateRange() {
    final now = DateTime.now();
    setState(() {
      _dateRange = DateTimeRange(
        start: now.subtract(Duration(days: 7)),
        end: now,
      );
    });
  }

  void _changePeriod(String period) {
    final now = DateTime.now();
    DateTimeRange newRange;

    switch (period) {
      case 'Day':
        newRange = DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );
        break;
      case 'Week':
        newRange = DateTimeRange(
          start: now.subtract(Duration(days: 7)),
          end: now,
        );
        break;
      case 'Month':
        newRange = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
        break;
      case 'Year':
        newRange = DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
        break;
      default:
        newRange = _dateRange!;
    }

    setState(() {
      _selectedPeriod = period;
      _dateRange = newRange;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _exportAnalytics,
            tooltip: 'Export Analytics',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Sales'),
            Tab(text: 'Products'),
            Tab(text: 'Customers'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSalesTab(),
                _buildProductsTab(),
                _buildCustomersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Period: ',
            style: Constants.regularText.copyWith(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Day', 'Week', 'Month', 'Year'].map((period) {
                  final isSelected = period == _selectedPeriod;
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(period),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) _changePeriod(period);
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Constants.primaryColor.withOpacity(0.2),
                      checkmarkColor: Constants.primaryColor,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (_dateRange != null)
            Text(
              '${AppUtils.formatDate(_dateRange!.start)} - ${AppUtils.formatDate(_dateRange!.end)}',
              style: Constants.smallText.copyWith(color: Colors.grey[600]),
            ),
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
        children: [
          _buildKeyMetricsGrid(),
          SizedBox(height: 24),
          _buildRevenueChart(),
          SizedBox(height: 24),
          _buildTopProducts(),
        ],
      ),
    );
  }

  Widget _buildOverviewTablet() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          _buildKeyMetricsGrid(),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildRevenueChart()),
              SizedBox(width: 24),
              Expanded(child: _buildTopProducts()),
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
        children: [
          _buildKeyMetricsGrid(),
          SizedBox(height: 32),
          Row(
            children: [
              Expanded(flex: 2, child: _buildRevenueChart()),
              SizedBox(width: 32),
              Expanded(child: _buildTopProducts()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsGrid() {
    return ResponsiveGrid(
      mobileColumns: 2,
      tabletColumns: 4,
      desktopColumns: 4,
      spacing: 16,
      children: [
        StatCard(
          title: 'Total Revenue',
          value: 'Rs 45,230',
          subtitle: '+12.5% from last period',
          color: Colors.green,
          icon: Icons.trending_up,
          showProgress: true,
          progress: 0.75,
        ),
        StatCard(
          title: 'Total Orders',
          value: '1,234',
          subtitle: '+8.3% from last period',
          color: Colors.blue,
          icon: Icons.shopping_cart,
          showProgress: true,
          progress: 0.68,
        ),
        StatCard(
          title: 'Avg. Order Value',
          value: 'Rs 36.67',
          subtitle: '+3.2% from last period',
          color: Colors.orange,
          icon: Icons.receipt,
          showProgress: true,
          progress: 0.82,
        ),
        StatCard(
          title: 'Conversion Rate',
          value: '4.8%',
          subtitle: '+0.5% from last period',
          color: Colors.purple,
          icon: Icons.people,
          showProgress: true,
          progress: 0.48,
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Trend',
              style: Constants.boldHeadingAppBar.copyWith(fontSize: 18),
            ),
            SizedBox(height: 16),
            LineChartWidget(
              height: 200,
              data: _getRevenueData(),
              showArea: true,
              showGridLines: true,
              showPoints: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Products',
              style: Constants.boldHeadingAppBar.copyWith(fontSize: 18),
            ),
            SizedBox(height: 16),
            BarChartWidget(
              height: 200,
              data: _getTopProductsData(),
              showValues: true,
              showGridLines: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSalesOverview(),
          SizedBox(height: 24),
          _buildSalesByCategory(),
          SizedBox(height: 24),
          _buildSalesByTime(),
        ],
      ),
    );
  }

  Widget _buildSalesOverview() {
    return ResponsiveGrid(
      mobileColumns: 2,
      tabletColumns: 4,
      desktopColumns: 4,
      spacing: 16,
      children: [
        StatCard(
          title: 'Today\'s Sales',
          value: 'Rs 3,450',
          subtitle: '23 orders',
          color: Colors.green,
          icon: Icons.today,
        ),
        StatCard(
          title: 'This Week',
          value: 'Rs 12,340',
          subtitle: '89 orders',
          color: Colors.blue,
          icon: Icons.date_range,
        ),
        StatCard(
          title: 'This Month',
          value: 'Rs 45,230',
          subtitle: '1,234 orders',
          color: Colors.orange,
          icon: Icons.calendar_month,
        ),
        StatCard(
          title: 'This Year',
          value: 'Rs 234,560',
          subtitle: '8,901 orders',
          color: Colors.purple,
          icon: Icons.calendar_today,
        ),
      ],
    );
  }

  Widget _buildSalesByCategory() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales by Category',
              style: Constants.boldHeadingAppBar.copyWith(fontSize: 18),
            ),
            SizedBox(height: 16),
            PieChartWidget(
              size: 200,
              data: _getCategoryData(),
              showLabels: true,
              showLegend: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesByTime() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales by Time of Day',
              style: Constants.boldHeadingAppBar.copyWith(fontSize: 18),
            ),
            SizedBox(height: 16),
            BarChartWidget(
              height: 200,
              data: _getTimeData(),
              showValues: true,
              showGridLines: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProductMetrics(),
          SizedBox(height: 24),
          _buildProductPerformance(),
          SizedBox(height: 24),
          _buildProductTrends(),
        ],
      ),
    );
  }

  Widget _buildProductMetrics() {
    return ResponsiveGrid(
      mobileColumns: 2,
      tabletColumns: 3,
      desktopColumns: 4,
      spacing: 16,
      children: [
        StatCard(
          title: 'Total Products',
          value: '2,456',
          subtitle: '+156 new this month',
          color: Colors.blue,
          icon: Icons.inventory,
        ),
        StatCard(
          title: 'Active Products',
          value: '1,892',
          subtitle: '77% of total',
          color: Colors.green,
          icon: Icons.check_circle,
        ),
        StatCard(
          title: 'Out of Stock',
          value: '23',
          subtitle: '1.2% of total',
          color: Colors.red,
          icon: Icons.warning,
        ),
        StatCard(
          title: 'Low Stock',
          value: '45',
          subtitle: '2.3% of total',
          color: Colors.orange,
          icon: Icons.inventory_2,
        ),
      ],
    );
  }

  Widget _buildProductPerformance() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Performance',
              style: Constants.boldHeadingAppBar.copyWith(fontSize: 18),
            ),
            SizedBox(height: 16),
            _buildProductTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTable() {
    final products = [
      {'name': 'Fresh Tomatoes', 'sales': 234, 'revenue': 5850, 'growth': '+12%'},
      {'name': 'Organic Apples', 'sales': 189, 'revenue': 7560, 'growth': '+8%'},
      {'name': 'Whole Milk', 'sales': 156, 'revenue': 4680, 'growth': '+15%'},
      {'name': 'Bread', 'sales': 145, 'revenue': 2175, 'growth': '-3%'},
      {'name': 'Eggs', 'sales': 123, 'revenue': 3690, 'growth': '+5%'},
    ];

    return DataTable(
      columns: [
        DataColumn(label: Text('Product')),
        DataColumn(label: Text('Sales')),
        DataColumn(label: Text('Revenue')),
        DataColumn(label: Text('Growth')),
      ],
      rows: products.map((product) {
        return DataRow(
          cells: [
            DataCell(Text(product['name']!)),
            DataCell(Text(product['sales']!)),
            DataCell(Text('Rs ${product['revenue']}')),
            DataCell(
              Text(
                product['growth']!,
                style: TextStyle(
                  color: product['growth']!.startsWith('+') ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildProductTrends() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Trends',
              style: Constants.boldHeadingAppBar.copyWith(fontSize: 18),
            ),
            SizedBox(height: 16),
            LineChartWidget(
              height: 200,
              data: _getProductTrendData(),
              showArea: false,
              showGridLines: true,
              showPoints: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomersTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCustomerMetrics(),
          SizedBox(height: 24),
          _buildCustomerGrowth(),
          SizedBox(height: 24),
          _buildCustomerSegments(),
        ],
      ),
    );
  }

  Widget _buildCustomerMetrics() {
    return ResponsiveGrid(
      mobileColumns: 2,
      tabletColumns: 3,
      desktopColumns: 4,
      spacing: 16,
      children: [
        StatCard(
          title: 'Total Customers',
          value: '3,456',
          subtitle: '+234 this month',
          color: Colors.blue,
          icon: Icons.people,
        ),
        StatCard(
          title: 'Active Customers',
          value: '1,234',
          subtitle: '35.7% of total',
          color: Colors.green,
          icon: Icons.person,
        ),
        StatCard(
          title: 'New Customers',
          value: '234',
          subtitle: '+12% from last month',
          color: Colors.orange,
          icon: Icons.person_add,
        ),
        StatCard(
          title: 'Returning Rate',
          value: '67.8%',
          subtitle: '+2.3% from last month',
          color: Colors.purple,
          icon: Icons.repeat,
        ),
      ],
    );
  }

  Widget _buildCustomerGrowth() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Growth',
              style: Constants.boldHeadingAppBar.copyWith(fontSize: 18),
            ),
            SizedBox(height: 16),
            LineChartWidget(
              height: 200,
              data: _getCustomerGrowthData(),
              showArea: true,
              showGridLines: true,
              showPoints: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSegments() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Segments',
              style: Constants.boldHeadingAppBar.copyWith(fontSize: 18),
            ),
            SizedBox(height: 16),
            PieChartWidget(
              size: 200,
              data: _getCustomerSegmentData(),
              showLabels: true,
              showLegend: true,
            ),
          ],
        ),
      ),
    );
  }

  List<ChartData> _getRevenueData() {
    return [
      ChartData(label: 'Mon', value: 3200),
      ChartData(label: 'Tue', value: 2800),
      ChartData(label: 'Wed', value: 3500),
      ChartData(label: 'Thu', value: 3100),
      ChartData(label: 'Fri', value: 4200),
      ChartData(label: 'Sat', value: 3800),
      ChartData(label: 'Sun', value: 2900),
    ];
  }

  List<ChartData> _getTopProductsData() {
    return [
      ChartData(label: 'Tomatoes', value: 234),
      ChartData(label: 'Apples', value: 189),
      ChartData(label: 'Milk', value: 156),
      ChartData(label: 'Bread', value: 145),
      ChartData(label: 'Eggs', value: 123),
    ];
  }

  List<ChartData> _getCategoryData() {
    return [
      ChartData(label: 'Vegetables', value: 35),
      ChartData(label: 'Fruits', value: 25),
      ChartData(label: 'Dairy', value: 20),
      ChartData(label: 'Bakery', value: 12),
      ChartData(label: 'Meat', value: 8),
    ];
  }

  List<ChartData> _getTimeData() {
    return [
      ChartData(label: '6AM', value: 120),
      ChartData(label: '9AM', value: 340),
      ChartData(label: '12PM', value: 560),
      ChartData(label: '3PM', value: 420),
      ChartData(label: '6PM', value: 380),
      ChartData(label: '9PM', value: 180),
    ];
  }

  List<ChartData> _getProductTrendData() {
    return [
      ChartData(label: 'Week 1', value: 120),
      ChartData(label: 'Week 2', value: 145),
      ChartData(label: 'Week 3', value: 134),
      ChartData(label: 'Week 4', value: 167),
    ];
  }

  List<ChartData> _getCustomerGrowthData() {
    return [
      ChartData(label: 'Jan', value: 2800),
      ChartData(label: 'Feb', value: 2950),
      ChartData(label: 'Mar', value: 3100),
      ChartData(label: 'Apr', value: 3250),
      ChartData(label: 'May', value: 3400),
      ChartData(label: 'Jun', value: 3456),
    ];
  }

  List<ChartData> _getCustomerSegmentData() {
    return [
      ChartData(label: 'Regular', value: 45),
      ChartData(label: 'Occasional', value: 30),
      ChartData(label: 'New', value: 15),
      ChartData(label: 'Inactive', value: 10),
    ];
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _selectedPeriod = 'Custom';
      });
    }
  }

  void _exportAnalytics() {
    AppUtils.showSnackBar(context, 'Exporting analytics data...');
    // Implement export functionality
  }
}

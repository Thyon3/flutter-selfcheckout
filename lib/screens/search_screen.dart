import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/models/item.dart';
import 'package:selfcheckoutapp/widgets/advanced_widgets.dart';
import 'package:selfcheckoutapp/widgets/responsive_widgets.dart';
import 'package:selfcheckoutapp/utils/app_utils.dart';
import 'package:selfcheckoutapp/constants.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<Item> _searchResults = [];
  List<Item> _filteredResults = [];
  List<String> _searchHistory = [];
  List<String> _categories = [];
  String _selectedCategory = 'All';
  String _sortBy = 'Name';
  bool _isSearching = false;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSearchHistory();
    _loadCategories();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadSearchHistory() {
    // Load search history from preferences
    setState(() {
      _searchHistory = [
        'Fresh Vegetables',
        'Dairy Products',
        'Bread',
        'Fruits',
        'Rice',
      ];
    });
  }

  void _loadCategories() {
    setState(() {
      _categories = [
        'All',
        'Vegetables',
        'Fruits',
        'Dairy',
        'Bakery',
        'Meat',
        'Beverages',
        'Snacks',
        'Household',
      ];
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _filteredResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Simulate search delay
    Future.delayed(Duration(milliseconds: 500), () {
      // Mock search results
      final mockResults = [
        Item(
          name: 'Fresh Tomatoes',
          barcode: '1234567890',
          price: 45.50,
          weight: 500,
          quantity: 1,
          photo: '',
          category: 'Vegetables',
          description: 'Fresh, ripe tomatoes perfect for salads and cooking',
        ),
        Item(
          name: 'Organic Apples',
          barcode: '2345678901',
          price: 120.00,
          weight: 1000,
          quantity: 1,
          photo: '',
          category: 'Fruits',
          description: 'Crisp and sweet organic apples',
        ),
        Item(
          name: 'Whole Milk',
          barcode: '3456789012',
          price: 85.00,
          weight: 1000,
          quantity: 1,
          photo: '',
          category: 'Dairy',
          description: 'Fresh whole milk from local farms',
        ),
      ];

      setState(() {
        _searchResults = mockResults.where((item) {
          final searchTerms = AppUtils.splitSearchQuery(query);
          return AppUtils.matchesSearch(item.name, searchTerms) ||
                 AppUtils.matchesSearch(item.description ?? '', searchTerms) ||
                 AppUtils.matchesSearch(item.category ?? '', searchTerms);
        }).toList();
        
        _filteredResults = List.from(_searchResults);
        _applyFilters();
        _isSearching = false;
      });

      // Add to search history
      if (query.trim().isNotEmpty) {
        _addToSearchHistory(query.trim());
      }
    });
  }

  void _addToSearchHistory(String query) {
    setState(() {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredResults = List.from(_searchResults);
      
      // Apply category filter
      if (_selectedCategory != 'All') {
        _filteredResults = _filteredResults
            .where((item) => item.category == _selectedCategory)
            .toList();
      }
      
      // Apply sorting
      _filteredResults.sort((a, b) {
        switch (_sortBy) {
          case 'Name':
            return a.name.compareTo(b.name);
          case 'Price (Low to High)':
            return a.price.compareTo(b.price);
          case 'Price (High to Low)':
            return b.price.compareTo(a.price);
          case 'Category':
            return (a.category ?? '').compareTo(b.category ?? '');
          default:
            return 0;
        }
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _filteredResults = [];
    });
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Products'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Search'),
            Tab(text: 'Categories'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildCategoriesTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        _buildSearchBar(),
        if (_showFilters) _buildFilterPanel(),
        Expanded(
          child: _isSearching
              ? Center(child: CircularProgressIndicator())
              : _filteredResults.isEmpty
                  ? _buildEmptyState()
                  : _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: SearchField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _performSearch,
              onClear: _clearSearch,
              hintText: 'Search for products...',
              suffixIcon: IconButton(
                icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
                onPressed: _toggleFilters,
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.barcode_scanner),
            onPressed: _scanBarcode,
            tooltip: 'Scan Barcode',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Constants.boldText.copyWith(fontSize: 16),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: Text('Reset'),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Category',
            style: Constants.regularText.copyWith(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected = category == _selectedCategory;
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                  _applyFilters();
                },
                backgroundColor: Colors.white,
                selectedColor: Constants.primaryColor.withOpacity(0.2),
                checkmarkColor: Constants.primaryColor,
              );
            }).toList(),
          ),
          SizedBox(height: 16),
          Text(
            'Sort By',
            style: Constants.regularText.copyWith(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _sortBy,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              'Name',
              'Price (Low to High)',
              'Price (High to Low)',
              'Category',
            ].map((sortOption) {
              return DropdownMenuItem(
                value: sortOption,
                child: Text(sortOption),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
              });
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ResponsiveGrid(
      mobileColumns: 2,
      tabletColumns: 3,
      desktopColumns: 4,
      spacing: 12,
      children: _filteredResults.map((item) {
        return ProductCard(
          product: item,
          onTap: () => _viewProductDetails(item),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      title: 'No products found',
      subtitle: 'Try searching with different keywords',
      icon: Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
      action: ElevatedButton.icon(
        onPressed: _scanBarcode,
        icon: Icon(Icons.barcode_scanner),
        label: Text('Scan Barcode'),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return ResponsiveGrid(
      mobileColumns: 2,
      tabletColumns: 3,
      desktopColumns: 4,
      spacing: 16,
      children: _categories.where((cat) => cat != 'All').map((category) {
        return CategoryCard(
          category: category,
          onTap: () => _searchByCategory(category),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryTab() {
    if (_searchHistory.isEmpty) {
      return EmptyState(
        title: 'No search history',
        subtitle: 'Your recent searches will appear here',
        icon: Icon(Icons.history, size: 64, color: Colors.grey[400]),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _searchHistory.length,
      itemBuilder: (context, index) {
        final query = _searchHistory[index];
        return HistoryTile(
          query: query,
          onTap: () {
            _searchController.text = query;
            _performSearch(query);
            _tabController.animateTo(0);
          },
          onDelete: () {
            setState(() {
              _searchHistory.removeAt(index);
            });
          },
        );
      },
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'All';
      _sortBy = 'Name';
    });
    _applyFilters();
  }

  void _scanBarcode() {
    // Implement barcode scanning
    AppUtils.showSnackBar(context, 'Barcode scanner coming soon!');
  }

  void _viewProductDetails(Item product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: product),
      ),
    );
  }

  void _searchByCategory(String category) {
    _searchController.text = category;
    _performSearch(category);
    _tabController.animateTo(0);
  }
}

class ProductCard extends StatelessWidget {
  final Item product;
  final VoidCallback onTap;

  const ProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: onTap,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: product.photo != null && product.photo!.isNotEmpty
                    ? Image.network(
                        product.photo!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image, size: 48, color: Colors.grey[400]);
                        },
                      )
                    : Icon(Icons.image, size: 48, color: Colors.grey[400]),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Constants.regularText.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    if (product.category != null)
                      Text(
                        product.category!,
                        style: Constants.smallText.copyWith(color: Colors.grey[600]),
                      ),
                    SizedBox(height: 2),
                    Text(
                      AppUtils.formatPrice(product.price),
                      style: Constants.boldText.copyWith(
                        color: Constants.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String category;
  final VoidCallback onTap;

  const CategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppUtils.getCategoryIcon(category),
                style: TextStyle(fontSize: 32),
              ),
              SizedBox(height: 8),
              Text(
                category,
                style: Constants.regularText.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryTile extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const HistoryTile({
    required this.query,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.history, color: Colors.grey[600]),
      title: Text(query),
      trailing: IconButton(
        icon: Icon(Icons.clear),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}

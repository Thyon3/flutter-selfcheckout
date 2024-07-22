import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/models/item.dart';
import 'package:selfcheckoutapp/widgets/advanced_widgets.dart';
import 'package:selfcheckoutapp/widgets/responsive_widgets.dart';
import 'package:selfcheckoutapp/utils/app_utils.dart';
import 'package:selfcheckoutapp/constants.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Item product;
  final VoidCallback? onAddToCart;
  final VoidCallback? onAddToFavorites;
  final bool isFavorite;

  const ProductDetailsScreen({
    Key? key,
    required this.product,
    this.onAddToCart,
    this.onAddToFavorites,
    this.isFavorite = false,
  }) : super(key: key);

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _quantity = 1;
  bool _isAddingToCart = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _isFavorite = widget.isFavorite;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    widget.onAddToFavorites?.call();
  }

  Future<void> _addToCart() async {
    setState(() {
      _isAddingToCart = true;
    });

    try {
      await widget.onAddToCart?.call();
      AppUtils.showSuccessSnackBar(context, 'Added to cart successfully!');
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Failed to add to cart');
    } finally {
      setState(() {
        _isAddingToCart = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildProductImage(),
              _buildProductInfo(),
              _buildTabBar(),
              _buildTabBarView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildProductImage(),
              _buildBottomActionBar(),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildProductInfo(),
                _buildTabBar(),
                _buildTabBarView(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            padding: EdgeInsets.all(32),
            child: _buildProductImage(),
          ),
        ),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductInfo(),
                SizedBox(height: 24),
                _buildTabBar(),
                SizedBox(height: 16),
                _buildTabBarView(),
                SizedBox(height: 32),
                _buildDesktopActions(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildProductImage(),
      ),
      actions: [
        IconButton(
          icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
          onPressed: _toggleFavorite,
          color: _isFavorite ? Colors.red : null,
        ),
        IconButton(
          icon: Icon(Icons.share),
          onPressed: _shareProduct,
        ),
      ],
    );
  }

  Widget _buildProductImage() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: widget.product.photo != null && widget.product.photo!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                widget.product.photo!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage();
                },
              ),
            )
          : _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_not_supported,
          size: 64,
          color: Colors.grey[400],
        ),
        SizedBox(height: 8),
        Text(
          'No Image',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: Constants.boldHeadingAppBar.copyWith(fontSize: 24),
                    ),
                    if (widget.product.category != null) ...[
                      SizedBox(height: 4),
                      StatusBadge(
                        status: widget.product.category!,
                        color: Colors.blue,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppUtils.formatPrice(widget.product.price),
                    style: Constants.boldText.copyWith(
                      fontSize: 24,
                      color: Constants.primaryColor,
                    ),
                  ),
                  if (widget.product.weight != null && widget.product.weight! > 0) ...[
                    SizedBox(height: 4),
                    Text(
                      '${widget.product.weight}g',
                      style: Constants.smallText.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          if (widget.product.description != null && widget.product.description!.isNotEmpty) ...[
            Text(
              'Description',
              style: Constants.boldText.copyWith(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              widget.product.description!,
              style: Constants.regularText.copyWith(
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
          ],
          _buildQuantitySelector(),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        Text(
          'Quantity:',
          style: Constants.boldText.copyWith(fontSize: 16),
        ),
        SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: _decrementQuantity,
                disabled: _quantity <= 1,
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  '$_quantity',
                  style: Constants.boldText,
                ),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: _incrementQuantity,
              ),
            ],
          ),
        ),
        Spacer(),
        Text(
          'Total: ${AppUtils.formatPrice(widget.product.price * _quantity)}',
          style: Constants.boldText.copyWith(
            fontSize: 18,
            color: Constants.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: [
        Tab(text: 'Details'),
        Tab(text: 'Reviews'),
        Tab(text: 'Similar'),
      ],
    );
  }

  Widget _buildTabBarView() {
    return Container(
      height: 200,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          _buildReviewsTab(),
          _buildSimilarTab(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Barcode', widget.product.barcode),
          _buildDetailRow('Price', AppUtils.formatPrice(widget.product.price)),
          if (widget.product.weight != null && widget.product.weight! > 0)
            _buildDetailRow('Weight', '${widget.product.weight}g'),
          if (widget.product.category != null)
            _buildDetailRow('Category', widget.product.category!),
          if (widget.product.addedDate != null)
            _buildDetailRow('Added', AppUtils.formatDate(widget.product.addedDate!)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Constants.regularText.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Constants.regularText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.reviews, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: Constants.regularText.copyWith(color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Be the first to review this product',
            style: Constants.smallText.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Similar products',
            style: Constants.regularText.copyWith(color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Loading similar products...',
            style: Constants.smallText.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
            color: _isFavorite ? Colors.red : null,
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareProduct,
          ),
          SizedBox(width: 16),
          Expanded(
            child: LoadingButton(
              text: 'Add to Cart',
              onPressed: _addToCart,
              isLoading: _isAddingToCart,
              icon: Icon(Icons.add_shopping_cart),
              isFullWidth: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _toggleFavorite,
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            label: Text(_isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: LoadingButton(
            text: 'Add to Cart',
            onPressed: _addToCart,
            isLoading: _isAddingToCart,
            icon: Icon(Icons.add_shopping_cart),
            isFullWidth: true,
          ),
        ),
      ],
    );
  }

  void _shareProduct() {
    // Implement share functionality
    AppUtils.showSnackBar(context, 'Share functionality coming soon!');
  }
}

import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/widgets/advanced_widgets.dart';
import 'package:selfcheckoutapp/widgets/responsive_widgets.dart';
import 'package:selfcheckoutapp/utils/app_utils.dart';
import 'package:selfcheckoutapp/constants.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  _HelpSupportScreenState createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  List<HelpArticle> _allArticles = [];
  List<HelpArticle> _filteredArticles = [];
  List<HelpCategory> _categories = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadHelpData();
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadHelpData() {
    setState(() {
      _categories = [
        HelpCategory(
          id: 'getting-started',
          name: 'Getting Started',
          icon: Icons.play_arrow,
          color: Colors.blue,
          description: 'Learn the basics of using the app',
        ),
        HelpCategory(
          id: 'shopping',
          name: 'Shopping',
          icon: Icons.shopping_cart,
          color: Colors.green,
          description: 'How to shop and manage your cart',
        ),
        HelpCategory(
          id: 'payment',
          name: 'Payment',
          icon: Icons.payment,
          color: Colors.orange,
          description: 'Payment methods and checkout',
        ),
        HelpCategory(
          id: 'account',
          name: 'Account',
          icon: Icons.person,
          color: Colors.purple,
          description: 'Manage your profile and settings',
        ),
        HelpCategory(
          id: 'troubleshooting',
          name: 'Troubleshooting',
          icon: Icons.build,
          color: Colors.red,
          description: 'Common issues and solutions',
        ),
      ];

      _allArticles = [
        HelpArticle(
          id: '1',
          title: 'How to create an account',
          category: 'getting-started',
          content: '''
# Creating Your Account

To get started with ScanGo, you'll need to create an account:

1. Download the ScanGo app from your app store
2. Tap on "Create Account" 
3. Enter your email address and create a password
4. Fill in your personal information
5. Verify your email address
6. You're ready to start shopping!

## Tips
- Use a strong password with at least 8 characters
- Make sure your email address is correct
- Keep your login information secure
          ''',
          views: 1250,
          helpful: 89,
        ),
        HelpArticle(
          id: '2',
          title: 'Adding items to your cart',
          category: 'shopping',
          content: '''
# Adding Items to Cart

There are several ways to add items to your cart:

## Using Barcode Scanner
1. Tap the scan button
2. Point your camera at the product barcode
3. Wait for the app to recognize the product
4. Confirm the item details
5. Tap "Add to Cart"

## Manual Search
1. Tap the search bar
2. Type the product name
3. Select the product from results
4. Choose quantity
5. Tap "Add to Cart"

## Tips
- Make sure the barcode is well-lit and clear
- Hold your camera steady while scanning
- Check the product details before adding
          ''',
          views: 890,
          helpful: 76,
        ),
        HelpArticle(
          id: '3',
          title: 'Payment methods',
          category: 'payment',
          content: '''
# Payment Methods

ScanGo supports multiple payment options:

## Credit/Debit Cards
- Visa, Mastercard, American Express
- Save cards for faster checkout
- Secure payment processing

## Digital Wallets
- Google Pay
- Apple Pay
- PayPal

## Cash on Delivery
- Pay when you receive your order
- Available in select areas

## Tips
- Always check your payment details
- Keep your payment information secure
- Contact support if you have payment issues
          ''',
          views: 1100,
          helpful: 92,
        ),
        HelpArticle(
          id: '4',
          title: 'Managing your profile',
          category: 'account',
          content: '''
# Profile Management

Keep your profile information up to date:

## Personal Information
- Update your name and contact details
- Add a profile picture
- Set your preferences

## Security Settings
- Change your password regularly
- Enable two-factor authentication
- Review login activity

## Privacy Settings
- Control data sharing
- Manage notification preferences
- Set account visibility

## Tips
- Review your profile periodically
- Use a strong, unique password
- Enable security features for protection
          ''',
          views: 650,
          helpful: 58,
        ),
        HelpArticle(
          id: '5',
          title: 'App not working properly',
          category: 'troubleshooting',
          content: '''
# Common Issues and Solutions

## App Crashing
1. Restart the app
2. Clear app cache
3. Update to the latest version
4. Restart your device
5. Reinstall if necessary

## Barcode Scanner Not Working
1. Check camera permissions
2. Ensure good lighting
3. Clean your camera lens
4. Hold the device steady
5. Try manual search

## Login Issues
1. Check your email/password
2. Reset your password if needed
3. Clear app data and cache
4. Update the app
5. Contact support if issues persist

## Tips
- Keep your app updated
- Report bugs to help improve the app
- Check internet connection for online features
          ''',
          views: 1450,
          helpful: 103,
        ),
      ];

      _filteredArticles = List.from(_allArticles);
    });
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      if (query.isEmpty) {
        _filteredArticles = List.from(_allArticles);
      } else {
        _filteredArticles = _allArticles.where((article) {
          return article.title.toLowerCase().contains(query) ||
                 article.content.toLowerCase().contains(query) ||
                 article.category.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'FAQ'),
            Tab(text: 'Categories'),
            Tab(text: 'Contact'),
            Tab(text: 'About'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQTab(),
          _buildCategoriesTab(),
          _buildContactTab(),
          _buildAboutTab(),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: SearchField(
            controller: _searchController,
            hintText: 'Search for help articles...',
          ),
        ),
        Expanded(
          child: _filteredArticles.isEmpty
              ? EmptyState(
                  title: 'No articles found',
                  subtitle: 'Try searching with different keywords',
                  icon: Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredArticles.length,
                  itemBuilder: (context, index) {
                    return ArticleTile(article: _filteredArticles[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    return ResponsiveGrid(
      mobileColumns: 2,
      tabletColumns: 3,
      desktopColumns: 4,
      spacing: 16,
      children: _categories.map((category) {
        return CategoryCard(
          category: category,
          onTap: () => _viewCategoryArticles(category),
        );
      }).toList(),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Support',
            style: Constants.boldHeadingAppBar.copyWith(fontSize: 24),
          ),
          SizedBox(height: 24),
          InfoCard(
            title: 'Email Support',
            subtitle: 'support@scango.app',
            leading: Icon(Icons.email, color: Constants.primaryColor),
            onTap: () => _contactSupport('email'),
          ),
          SizedBox(height: 16),
          InfoCard(
            title: 'Phone Support',
            subtitle: '1-800-SCAN-GO',
            leading: Icon(Icons.phone, color: Constants.primaryColor),
            onTap: () => _contactSupport('phone'),
          ),
          SizedBox(height: 16),
          InfoCard(
            title: 'Live Chat',
            subtitle: 'Chat with our support team',
            leading: Icon(Icons.chat, color: Constants.primaryColor),
            onTap: () => _contactSupport('chat'),
          ),
          SizedBox(height: 32),
          Text(
            'Support Hours',
            style: Constants.boldText.copyWith(fontSize: 18),
          ),
          SizedBox(height: 16),
          InfoCard(
            title: 'Monday - Friday',
            subtitle: '9:00 AM - 6:00 PM',
            leading: Icon(Icons.schedule, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          InfoCard(
            title: 'Saturday - Sunday',
            subtitle: '10:00 AM - 4:00 PM',
            leading: Icon(Icons.schedule, color: Colors.grey[600]),
          ),
          SizedBox(height: 32),
          Text(
            'Frequently Asked Questions',
            style: Constants.boldText.copyWith(fontSize: 18),
          ),
          SizedBox(height: 16),
          ..._buildQuickFAQs(),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Constants.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'ScanGo',
                  style: Constants.boldHeadingAppBar.copyWith(fontSize: 28),
                ),
                SizedBox(height: 8),
                Text(
                  'Version 1.0.0',
                  style: Constants.regularText.copyWith(color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                StatusBadge(status: 'Active'),
              ],
            ),
          ),
          SizedBox(height: 32),
          Text(
            'About ScanGo',
            style: Constants.boldHeadingAppBar.copyWith(fontSize: 20),
          ),
          SizedBox(height: 16),
          Text(
            'ScanGo is your ultimate shopping companion, making grocery shopping faster, easier, and more convenient. With our innovative barcode scanning technology and smart shopping features, you can breeze through your shopping trips with confidence.',
            style: Constants.regularText.copyWith(height: 1.5),
          ),
          SizedBox(height: 24),
          Text(
            'Key Features',
            style: Constants.boldText.copyWith(fontSize: 18),
          ),
          SizedBox(height: 16),
          _buildFeatureItem(Icons.qr_code_scanner, 'Fast Barcode Scanning'),
          _buildFeatureItem(Icons.shopping_cart, 'Smart Cart Management'),
          _buildFeatureItem(Icons.payment, 'Secure Payment Options'),
          _buildFeatureItem(Icons.history, 'Purchase History'),
          _buildFeatureItem(Icons.list, 'Shopping Lists'),
          _buildFeatureItem(Icons.favorite, 'Favorites & Wishlist'),
          SizedBox(height: 24),
          Text(
            'Legal Information',
            style: Constants.boldText.copyWith(fontSize: 18),
          ),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.description),
            title: Text('Terms of Service'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: _openTermsOfService,
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacy Policy'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: _openPrivacyPolicy,
          ),
          ListTile(
            leading: Icon(Icons.gavel),
            title: Text('Legal Notices'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: _openLegalNotices,
          ),
          SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  '© 2024 ScanGo Inc.',
                  style: Constants.smallText.copyWith(color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  'All rights reserved.',
                  style: Constants.smallText.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFAQs() {
    final quickFAQs = [
      {
        'question': 'How do I reset my password?',
        'answer': 'Go to Settings > Security > Change Password',
      },
      {
        'question': 'Can I use the app offline?',
        'answer': 'Some features work offline, but scanning requires internet.',
      },
      {
        'question': 'How do I contact support?',
        'answer': 'Use the Contact tab or email support@scango.app',
      },
    ];

    return quickFAQs.map((faq) {
      return ExpansionTile(
        title: Text(faq['question']!),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(faq['answer']!),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Constants.primaryColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Constants.regularText,
            ),
          ),
        ],
      ),
    );
  }

  void _viewCategoryArticles(HelpCategory category) {
    final articles = _allArticles.where((article) => article.category == category.id).toList();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryArticlesScreen(
          category: category,
          articles: articles,
        ),
      ),
    );
  }

  void _contactSupport(String method) {
    switch (method) {
      case 'email':
        // Open email app
        AppUtils.showSnackBar(context, 'Opening email app...');
        break;
      case 'phone':
        // Open phone dialer
        AppUtils.showSnackBar(context, 'Opening phone dialer...');
        break;
      case 'chat':
        // Open live chat
        AppUtils.showSnackBar(context, 'Live chat coming soon...');
        break;
    }
  }

  void _openTermsOfService() {
    AppUtils.showSnackBar(context, 'Terms of Service coming soon...');
  }

  void _openPrivacyPolicy() {
    AppUtils.showSnackBar(context, 'Privacy Policy coming soon...');
  }

  void _openLegalNotices() {
    AppUtils.showSnackBar(context, 'Legal Notices coming soon...');
  }
}

class HelpArticle {
  final String id;
  final String title;
  final String category;
  final String content;
  final int views;
  final int helpful;

  HelpArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.views,
    required this.helpful,
  });
}

class HelpCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  HelpCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class ArticleTile extends StatelessWidget {
  final HelpArticle article;

  const ArticleTile({required this.article});

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleScreen(article: article),
          ),
        );
      },
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Constants.primaryColor.withOpacity(0.1),
          child: Icon(Icons.article, color: Constants.primaryColor),
        ),
        title: Text(
          article.title,
          style: Constants.boldText,
        ),
        subtitle: Text(
          '${article.views} views • ${article.helpful} found helpful',
          style: Constants.smallText.copyWith(color: Colors.grey[600]),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final HelpCategory category;
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
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: category.color.withOpacity(0.1),
                child: Icon(category.icon, color: category.color),
              ),
              SizedBox(height: 12),
              Text(
                category.name,
                style: Constants.boldText,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                category.description,
                style: Constants.smallText.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArticleScreen extends StatelessWidget {
  final HelpArticle article;

  const ArticleScreen({required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help Article'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareArticle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.title,
              style: Constants.boldHeadingAppBar.copyWith(fontSize: 24),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  '${article.views} views',
                  style: Constants.smallText.copyWith(color: Colors.grey[600]),
                ),
                SizedBox(width: 16),
                Icon(Icons.thumb_up, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  '${article.helpful} helpful',
                  style: Constants.smallText.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                article.content,
                style: Constants.regularText.copyWith(height: 1.6),
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _markHelpful,
                    icon: Icon(Icons.thumb_up),
                    label: Text('Helpful'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _markNotHelpful,
                    icon: Icon(Icons.thumb_down),
                    label: Text('Not Helpful'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _shareArticle() {
    // Implement share functionality
  }

  void _markHelpful() {
    // Implement helpful feedback
  }

  void _markNotHelpful() {
    // Implement not helpful feedback
  }
}

class CategoryArticlesScreen extends StatelessWidget {
  final HelpCategory category;
  final List<HelpArticle> articles;

  const CategoryArticlesScreen({
    required this.category,
    required this.articles,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: articles.isEmpty
          ? EmptyState(
              title: 'No articles found',
              subtitle: 'There are no articles in this category yet',
              icon: Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: articles.length,
              itemBuilder: (context, index) {
                return ArticleTile(article: articles[index]);
              },
            ),
    );
  }
}

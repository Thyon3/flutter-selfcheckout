import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/services/firebase_services.dart';
import 'package:selfcheckoutapp/widgets/form_widgets.dart';
import 'package:selfcheckoutapp/widgets/advanced_widgets.dart';
import 'package:selfcheckoutapp/widgets/responsive_widgets.dart';
import 'package:selfcheckoutapp/utils/app_utils.dart';
import 'package:selfcheckoutapp/constants.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({Key? key}) : super(key: key);

  @override
  _ProfileManagementScreenState createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseServices _firebaseServices = FirebaseServices();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isChangingPassword = false;
  Map<String, dynamic>? _userData;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userDoc = await _firebaseServices.getUserData(_firebaseServices.userId!);
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userData = data;
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppUtils.showErrorSnackBar(context, 'Failed to load profile data');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _firebaseServices.saveUserData(_firebaseServices.userId!, updatedData);
      
      setState(() {
        _userData = {..._userData!, ...updatedData};
        _isSaving = false;
      });

      AppUtils.showSuccessSnackBar(context, 'Profile updated successfully!');
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      AppUtils.showErrorSnackBar(context, 'Failed to update profile');
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _isChangingPassword = true;
    });

    try {
      // This would typically involve re-authentication with current password
      // and then updating the password in Firebase Auth
      
      await Future.delayed(Duration(seconds: 2)); // Simulate API call
      
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      
      setState(() {
        _isChangingPassword = false;
      });

      AppUtils.showSuccessSnackBar(context, 'Password changed successfully!');
    } catch (e) {
      setState(() {
        _isChangingPassword = false;
      });
      AppUtils.showErrorSnackBar(context, 'Failed to change password');
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await AppUtils.showConfirmationDialog(
      context,
      'Delete Account',
      'Are you sure you want to delete your account? This action cannot be undone.',
    );

    if (!confirmed) return;

    // Implement account deletion logic
    AppUtils.showSnackBar(context, 'Account deletion not implemented yet');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Personal Info'),
            Tab(text: 'Security'),
            Tab(text: 'Preferences'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalInfoTab(),
                _buildSecurityTab(),
                _buildPreferencesTab(),
              ],
            ),
    );
  }

  Widget _buildPersonalInfoTab() {
    return ResponsiveLayout(
      mobile: _buildPersonalInfoMobile(),
      tablet: _buildPersonalInfoTablet(),
      desktop: _buildPersonalInfoDesktop(),
    );
  }

  Widget _buildPersonalInfoMobile() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileImageSection(),
            SizedBox(height: 24),
            _buildPersonalInfoFields(),
            SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoTablet() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(flex: 1, child: _buildProfileImageSection()),
          SizedBox(width: 32),
          Expanded(flex: 2, child: _buildPersonalInfoFields()),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoDesktop() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(32),
      child: Row(
        children: [
          Expanded(flex: 1, child: _buildProfileImageSection()),
          SizedBox(width: 48),
          Expanded(flex: 2, child: _buildPersonalInfoFields()),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Constants.primaryColor.withOpacity(0.1),
          backgroundImage: _profileImage != null 
              ? FileImage(_profileImage!) as ImageProvider
              : null,
          child: _profileImage == null
              ? Icon(Icons.person, size: 60, color: Constants.primaryColor)
              : null,
        ),
        SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _changeProfileImage,
          icon: Icon(Icons.camera_alt),
          label: Text('Change Photo'),
        ),
        SizedBox(height: 8),
        TextButton(
          onPressed: _removeProfileImage,
          child: Text('Remove Photo'),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoFields() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: Constants.boldHeadingAppBar.copyWith(fontSize: 20),
          ),
          SizedBox(height: 24),
          NameField(
            label: 'Full Name',
            controller: _nameController,
            required: true,
          ),
          SizedBox(height: 16),
          EmailField(
            label: 'Email Address',
            controller: _emailController,
            required: true,
          ),
          SizedBox(height: 16),
          PhoneField(
            label: 'Phone Number',
            controller: _phoneController,
            required: false,
          ),
          SizedBox(height: 24),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return LoadingButton(
      text: 'Save Changes',
      onPressed: _saveProfile,
      isLoading: _isSaving,
      isFullWidth: true,
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security Settings',
            style: Constants.boldHeadingAppBar.copyWith(fontSize: 20),
          ),
          SizedBox(height: 24),
          Form(
            key: _passwordFormKey,
            child: Column(
              children: [
                PasswordField(
                  label: 'Current Password',
                  controller: _currentPasswordController,
                  required: true,
                ),
                SizedBox(height: 16),
                PasswordField(
                  label: 'New Password',
                  controller: _newPasswordController,
                  required: true,
                  minLength: 8,
                ),
                SizedBox(height: 16),
                ValidatedTextField(
                  label: 'Confirm New Password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  required: true,
                  validator: (value) {
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                LoadingButton(
                  text: 'Change Password',
                  onPressed: _changePassword,
                  isLoading: _isChangingPassword,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
          Divider(),
          SizedBox(height: 16),
          Text(
            'Danger Zone',
            style: Constants.boldHeadingAppBar.copyWith(
              fontSize: 18,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 16),
          InfoCard(
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and all data',
            leading: Icon(Icons.warning, color: Colors.red),
            onTap: _deleteAccount,
            color: Colors.red.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Preferences',
            style: Constants.boldHeadingAppBar.copyWith(fontSize: 20),
          ),
          SizedBox(height: 24),
          _buildNotificationPreferences(),
          SizedBox(height: 24),
          _buildPrivacyPreferences(),
          SizedBox(height: 24),
          _buildDataManagement(),
        ],
      ),
    );
  }

  Widget _buildNotificationPreferences() {
    return InfoCard(
      title: 'Notifications',
      subtitle: 'Manage your notification preferences',
      child: Column(
        children: [
          SwitchFormField(
            title: 'Push Notifications',
            subtitle: 'Receive push notifications for updates',
            value: true,
            onChanged: (value) {
              // Handle notification preference
            },
          ),
          SizedBox(height: 16),
          SwitchFormField(
            title: 'Email Notifications',
            subtitle: 'Receive email updates and newsletters',
            value: false,
            onChanged: (value) {
              // Handle email preference
            },
          ),
          SizedBox(height: 16),
          SwitchFormField(
            title: 'SMS Notifications',
            subtitle: 'Receive SMS alerts for important updates',
            value: false,
            onChanged: (value) {
              // Handle SMS preference
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPreferences() {
    return InfoCard(
      title: 'Privacy',
      subtitle: 'Control your privacy settings',
      child: Column(
        children: [
          SwitchFormField(
            title: 'Profile Visibility',
            subtitle: 'Make your profile visible to other users',
            value: false,
            onChanged: (value) {
              // Handle profile visibility
            },
          ),
          SizedBox(height: 16),
          SwitchFormField(
            title: 'Activity Status',
            subtitle: 'Show when you are online or active',
            value: true,
            onChanged: (value) {
              // Handle activity status
            },
          ),
          SizedBox(height: 16),
          SwitchFormField(
            title: 'Data Analytics',
            subtitle: 'Help improve the app with anonymous usage data',
            value: true,
            onChanged: (value) {
              // Handle analytics preference
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagement() {
    return InfoCard(
      title: 'Data Management',
      subtitle: 'Manage your data and account',
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.download),
            title: Text('Export Data'),
            subtitle: Text('Download all your data'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: _exportData,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.backup),
            title: Text('Backup Data'),
            subtitle: Text('Create a backup of your data'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: _backupData,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.restore),
            title: Text('Restore Data'),
            subtitle: Text('Restore data from backup'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: _restoreData,
          ),
        ],
      ),
    );
  }

  void _changeProfileImage() {
    // Implement image picker
    AppUtils.showSnackBar(context, 'Image picker coming soon!');
  }

  void _removeProfileImage() {
    setState(() {
      _profileImage = null;
    });
    AppUtils.showSnackBar(context, 'Profile image removed');
  }

  void _exportData() {
    // Implement data export
    AppUtils.showSnackBar(context, 'Data export coming soon!');
  }

  void _backupData() {
    // Implement data backup
    AppUtils.showSnackBar(context, 'Data backup coming soon!');
  }

  void _restoreData() {
    // Implement data restore
    AppUtils.showSnackBar(context, 'Data restore coming soon!');
  }
}

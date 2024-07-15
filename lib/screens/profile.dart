import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/services/firebase_services.dart';
import 'package:selfcheckoutapp/widgets/custom_button.dart';
import 'package:selfcheckoutapp/widgets/custom_input.dart';
import 'package:selfcheckoutapp/widgets/profile_avatar.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await _firebaseServices.getUserData(_firebaseServices.userId!);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _userData = data;
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('Name cannot be empty');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firebaseServices.saveUserData(
        _firebaseServices.userId!,
        {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      
      _showSuccessDialog('Profile updated successfully!');
    } catch (e) {
      _showErrorDialog('Failed to update profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xff1faa00),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.0),
              Avatar(
                radius: 50.0,
                name: _nameController.text,
              ),
              SizedBox(height: 20.0),
              Text(
                'Edit Your Profile',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1faa00),
                ),
              ),
              SizedBox(height: 30.0),
              CustomInput(
                hintText: 'Full Name',
                textEditingController: _nameController,
                textInputType: TextInputType.name,
              ),
              SizedBox(height: 16.0),
              CustomInput(
                hintText: 'Email Address',
                textEditingController: _emailController,
                textInputType: TextInputType.emailAddress,
                enableSuggestions: false,
                autocorrect: false,
              ),
              SizedBox(height: 16.0),
              CustomInput(
                hintText: 'Phone Number',
                textEditingController: _phoneController,
                textInputType: TextInputType.phone,
              ),
              SizedBox(height: 30.0),
              CustomBtn(
                text: 'Save Profile',
                onPressed: _saveProfile,
                isLoading: _isLoading,
              ),
              SizedBox(height: 20.0),
              Text(
                'Member since: ${_userData?['createdAt'] != null ? _formatDate(_userData!['createdAt']) : 'Unknown'}',
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 40.0),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

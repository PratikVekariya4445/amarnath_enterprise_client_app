import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/models/client_model.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';

/// Screen allowing the Client to view and update profile, shop name, and business address.
class MyDetailsScreen extends StatefulWidget {
  const MyDetailsScreen({
    super.key,
    this.initialProfile,
    this.authRepository,
  });

  final ClientModel? initialProfile;
  final AuthRepository? authRepository;

  @override
  State<MyDetailsScreen> createState() => _MyDetailsScreenState();
}

class _MyDetailsScreenState extends State<MyDetailsScreen> {
  late final AuthRepository _authRepository;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  late final TextEditingController _mobileController;
  late final TextEditingController _addressController;

  bool _isLoading = false;
  bool _isSaving = false;
  ClientModel? _profile;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepositoryImpl();
    _profile = widget.initialProfile;

    _nameController = TextEditingController(text: _profile?.name ?? '');
    _companyController = TextEditingController(text: _profile?.companyName ?? '');
    _mobileController = TextEditingController(text: _profile?.mobile ?? '');
    _addressController = TextEditingController(text: _profile?.address ?? '');

    if (_profile == null) {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _authRepository.getCurrentClientProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
          if (profile != null) {
            _nameController.text = profile.name;
            _companyController.text = profile.companyName;
            _mobileController.text = profile.mobile;
            _addressController.text = profile.address ?? '';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _authRepository.updateClientProfile(
        name: _nameController.text.trim(),
        companyName: _companyController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile details updated successfully!'),
            backgroundColor: Color(0xFF00864D),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update details: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF00864D),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5FAF7),
        appBar: AppBar(
          backgroundColor: const Color(0xFF00864D),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'My Details',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00864D)),
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(18.dp),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header card banner
                      Container(
                        padding: EdgeInsets.all(16.dp),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18.dp),
                          border: Border.all(color: const Color(0xFFD9DDE0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48.dp,
                              height: 48.dp,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDFF9E7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.storefront_outlined,
                                color: Color(0xFF087A42),
                              ),
                            ),
                            SizedBox(width: 14.dp),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Business & Personal Information',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF111111),
                                    ),
                                  ),
                                  SizedBox(height: 2.dp),
                                  Text(
                                    'Keep your profile and shop details current for accurate deliveries.',
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      color: const Color(0xFF454545),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 18.dp),

                      // Input Fields Card
                      Container(
                        padding: EdgeInsets.all(18.dp),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18.dp),
                          border: Border.all(color: const Color(0xFFD9DDE0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Full Name'),
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDecoration(
                                hint: 'Enter your full name',
                                icon: Icons.person_outline_rounded,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Name cannot be empty';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 16.dp),

                            _buildFieldLabel('Shop / Company Name'),
                            TextFormField(
                              controller: _companyController,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDecoration(
                                hint: 'Enter your shop or company name',
                                icon: Icons.storefront_outlined,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Shop name cannot be empty';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 16.dp),

                            _buildFieldLabel('Mobile Number (Registered)'),
                            TextFormField(
                              controller: _mobileController,
                              readOnly: true,
                              enabled: false,
                              decoration: _inputDecoration(
                                hint: 'Registered mobile number',
                                icon: Icons.call_outlined,
                                helper: 'Mobile number cannot be changed directly.',
                              ),
                            ),

                            SizedBox(height: 16.dp),

                            _buildFieldLabel('Business / Delivery Address'),
                            TextFormField(
                              controller: _addressController,
                              maxLines: 3,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: _inputDecoration(
                                hint: 'Enter your complete delivery address, market yard, city and pincode',
                                icon: Icons.location_on_outlined,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Business address cannot be empty';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.dp),

                      // Save Button
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00864D),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF00864D).withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.dp),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.dp),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? SizedBox(
                                width: 20.dp,
                                height: 20.dp,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.dp),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111111),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? helper,
  }) {
    return InputDecoration(
      hintText: hint,
      helperText: helper,
      helperStyle: TextStyle(fontSize: 11.sp, color: const Color(0xFF737D86)),
      prefixIcon: Icon(icon, color: const Color(0xFF087A42), size: 20.dp),
      filled: true,
      fillColor: const Color(0xFFF9FBFA),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.dp, vertical: 12.dp),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.dp),
        borderSide: const BorderSide(color: Color(0xFFD9DDE0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.dp),
        borderSide: const BorderSide(color: Color(0xFFD9DDE0)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.dp),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.dp),
        borderSide: const BorderSide(color: Color(0xFF00864D), width: 1.5),
      ),
    );
  }
}

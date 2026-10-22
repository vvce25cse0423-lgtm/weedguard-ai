import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String? _photoPath;
  bool _loading = false;
  bool _saved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    _nameCtrl.text = user?.userMetadata?['full_name'] as String? ?? '';
    _phoneCtrl.text = user?.userMetadata?['phone'] as String? ?? '';
    _locationCtrl.text = user?.userMetadata?['location'] as String? ?? '';

    final avatarFromMeta = user?.userMetadata?['avatar_url'] as String?;
    final prefs = await SharedPreferences.getInstance();
    final localPath = prefs.getString('profile_photo_path');
    final remoteUrl = prefs.getString('profile_photo_url');

    String? photo;
    if (localPath != null && File(localPath).existsSync()) {
      photo = localPath;
    } else if (remoteUrl != null && remoteUrl.isNotEmpty) {
      photo = remoteUrl;
    } else if (avatarFromMeta != null && avatarFromMeta.isNotEmpty) {
      photo = avatarFromMeta;
    }

    if (mounted) {
      setState(() {
        _photoPath = photo;
      });
      ref.read(userAvatarProvider.notifier).setAvatar(photo);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    Navigator.of(context).pop();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (picked == null) return;

      setState(() {
        _loading = true;
        _error = null;
      });

      final appDir = await getApplicationDocumentsDirectory();
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'user';
      final fileName = 'profile_avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localFile = File('${appDir.path}/$fileName');
      await File(picked.path).copy(localFile.path);

      String? uploadedUrl;
      try {
        final bytes = await localFile.readAsBytes();
        final storagePath = '$userId/$fileName';
        await Supabase.instance.client.storage
            .from(AppConstants.profileImagesBucket)
            .uploadBinary(
              storagePath,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
        uploadedUrl = Supabase.instance.client.storage
            .from(AppConstants.profileImagesBucket)
            .getPublicUrl(storagePath);
      } catch (_) {
        // Fallback to local storage if bucket is inaccessible
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_photo_path', localFile.path);
      if (uploadedUrl != null) {
        await prefs.setString('profile_photo_url', uploadedUrl);
      }

      try {
        await Supabase.instance.client.auth.updateUser(UserAttributes(
          data: {
            'avatar_url': uploadedUrl ?? localFile.path,
          },
        ));
      } catch (_) {}

      ref.read(userAvatarProvider.notifier).setAvatar(localFile.path);
      if (mounted) {
        setState(() {
          _photoPath = localFile.path;
          _saved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not select photo. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeProfilePhoto() async {
    Navigator.of(context).pop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_photo_path');
    await prefs.remove('profile_photo_url');
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(
        data: {'avatar_url': ''},
      ));
    } catch (_) {}

    // Delete any local profile avatar files
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final files = appDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('profile_avatar_'))
          .toList();
      for (final f in files) {
        try {
          if (f.existsSync()) f.deleteSync();
        } catch (_) {}
      }
    } catch (_) {}

    ref.read(userAvatarProvider.notifier).setAvatar(null);
    if (mounted) {
      setState(() {
        _photoPath = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo removed'),
          backgroundColor: Color(0xFF1B5E20),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF1B5E20)),
                ),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => _pickProfilePhoto(ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF1B5E20)),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => _pickProfilePhoto(ImageSource.gallery),
              ),
              if (_photoPath != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD32F2F)),
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.w600),
                  ),
                  onTap: _removeProfilePhoto,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage() {
    if (_photoPath != null && _photoPath!.isNotEmpty) {
      if (_photoPath!.startsWith('http')) {
        return Image.network(
          _photoPath!,
          fit: BoxFit.cover,
          width: 96,
          height: 96,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.person_rounded,
            size: 50,
            color: Color(0xFF2E7D32),
          ),
        );
      }
      final file = File(_photoPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: 96,
          height: 96,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.person_rounded,
            size: 50,
            color: Color(0xFF2E7D32),
          ),
        );
      }
    }
    return const Icon(
      Icons.person_rounded,
      size: 52,
      color: Color(0xFF2E7D32),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _saved = false;
    });
    try {
      final updateData = {
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
      };
      if (_photoPath != null) {
        updateData['avatar_url'] = _photoPath!;
        ref.read(userAvatarProvider.notifier).setAvatar(_photoPath!);
      }
      await Supabase.instance.client.auth.updateUser(UserAttributes(
        data: updateData,
      ));
      setState(() => _saved = true);
    } catch (_) {
      setState(() => _error = 'Could not update profile. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B4332),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1B4332)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/profile_bg.png',
            fit: BoxFit.cover,
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Photo Header
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _loading ? null : _showPhotoOptions,
                                child: Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: const Color(0xFF2E7D32), width: 3),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x22000000),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: _buildAvatarImage(),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _loading ? null : _showPhotoOptions,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF1B5E20),
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x33000000),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _loading ? null : _showPhotoOptions,
                            icon: const Icon(Icons.add_a_photo_outlined, size: 16, color: Color(0xFF1B5E20)),
                            label: Text(
                              _photoPath != null ? 'Change Profile Photo' : 'Add Profile Photo',
                              style: const TextStyle(
                                color: Color(0xFF1B5E20),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.85),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: const BorderSide(color: Color(0xFFC8E6C9)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.verified_user_rounded, color: Color(0xFF2E7D32), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email.isNotEmpty ? email : 'Farmer Account',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1B4332),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Verified Farmer Account',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFCDD2)),
                        ),
                        child: Text(_error!, style: const TextStyle(color: Color(0xFFC62828), fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                    if (_saved) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: const Text('Profile updated successfully.', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            style: const TextStyle(fontSize: 14.5, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: 'Full name',
                              labelStyle: const TextStyle(color: Color(0xFF4A7A4A), fontSize: 13.5),
                              prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF2E7D32), size: 20),
                              filled: true,
                              fillColor: const Color(0xFFF9FBF9),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD0E1D0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD0E1D0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontSize: 14.5, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: 'Phone number',
                              labelStyle: const TextStyle(color: Color(0xFF4A7A4A), fontSize: 13.5),
                              prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF2E7D32), size: 20),
                              filled: true,
                              fillColor: const Color(0xFFF9FBF9),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD0E1D0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD0E1D0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _locationCtrl,
                            style: const TextStyle(fontSize: 14.5, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: 'Location / Region',
                              labelStyle: const TextStyle(color: Color(0xFF4A7A4A), fontSize: 13.5),
                              prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF2E7D32), size: 20),
                              filled: true,
                              fillColor: const Color(0xFFF9FBF9),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD0E1D0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD0E1D0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 2,
                              ),
                              icon: _loading
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.save_rounded, size: 18),
                              label: Text(
                                _loading ? 'Saving...' : 'Save Changes',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/field_model.dart';
import '../../data/fields_repository.dart';

const _cropTypes = [
  'Rice','Wheat','Sugarcane','Cotton','Maize','Soybean','Pulses',
  'Vegetables','Groundnut','Sunflower','Other',
];

class CreateFieldScreen extends StatefulWidget {
  final String? fieldId;
  const CreateFieldScreen({super.key, this.fieldId});

  @override
  State<CreateFieldScreen> createState() => _CreateFieldScreenState();
}

class _CreateFieldScreenState extends State<CreateFieldScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _cropType = _cropTypes.first;
  DateTime? _plantingDate;
  double? _latitude;
  double? _longitude;
  bool _loading = false;
  bool _locating = false;
  String? _error;
  FieldModel? _existingField;

  bool get _isEditing => widget.fieldId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadExistingField();
  }

  Future<void> _loadExistingField() async {
    setState(() => _loading = true);
    try {
      final repo = FieldsRepository(Supabase.instance.client);
      _existingField = await repo.getField(widget.fieldId!);
      _nameCtrl.text = _existingField!.name;
      _cropType = _existingField!.cropType;
      if (_existingField!.areHectares != null) _areaCtrl.text = _existingField!.areHectares!.toString();
      if (_existingField!.locationLabel != null) _locationCtrl.text = _existingField!.locationLabel!;
      if (_existingField!.notes != null) _notesCtrl.text = _existingField!.notes!;
      _plantingDate = _existingField!.plantingDate;
      _latitude = _existingField!.latitude;
      _longitude = _existingField!.longitude;
    } catch (_) {
      setState(() => _error = 'Could not load field data.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _areaCtrl.dispose();
    _locationCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _plantingDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _plantingDate = date);
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() { _error = 'Location permission is permanently denied. Enable it in settings.'; _locating = false; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _locationCtrl.text = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      });
    } catch (_) {
      setState(() => _error = 'Could not detect location. Try entering it manually.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final repo = FieldsRepository(Supabase.instance.client);
      if (_isEditing && _existingField != null) {
        await repo.updateField(_existingField!.copyWith(
          name: _nameCtrl.text.trim(),
          cropType: _cropType,
          areHectares: _areaCtrl.text.isEmpty ? null : double.tryParse(_areaCtrl.text),
          latitude: _latitude,
          longitude: _longitude,
          locationLabel: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
          plantingDate: _plantingDate,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        ));
      } else {
        await repo.createField(
          name: _nameCtrl.text.trim(),
          cropType: _cropType,
          areaHectares: _areaCtrl.text.isEmpty ? null : double.tryParse(_areaCtrl.text),
          latitude: _latitude,
          longitude: _longitude,
          locationLabel: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
          plantingDate: _plantingDate,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF7),
      body: _loading && _isEditing
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : CustomScrollView(
              slivers: [
                // ── Curved Header with landscape & back button ──
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/add_field_template.png'),
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                        ),
                      ),
                      // Top gradient overlay to ensure text and back button legibility
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.55),
                              Colors.transparent,
                              const Color(0xFFF6FBF7),
                            ],
                            stops: const [0.0, 0.65, 1.0],
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.35),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                                ),
                                child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Form Content ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFCDD2)),
                              ),
                              child: Text(_error!, style: const TextStyle(color: Color(0xFFC62828), fontSize: 13)),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── Field information section ──
                          _buildSectionCard(
                            icon: Icons.eco,
                            iconColor: const Color(0xFF2D6A4F),
                            title: AppLocalizations.of(context).fieldInfo,
                            children: [
                              _buildInputField(
                                label: AppLocalizations.of(context).fieldName,
                                icon: Icons.spa_outlined,
                                child: TextFormField(
                                  controller: _nameCtrl,
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context).enterFieldName,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? AppLocalizations.of(context).fieldNameReq : null,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildInputField(
                                label: AppLocalizations.of(context).cropType,
                                icon: Icons.grass_outlined,
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _cropType,
                                    isDense: true,
                                    isExpanded: true,
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2D6A4F)),
                                    items: _cropTypes.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)))).toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _cropType = v);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildInputField(
                                label: AppLocalizations.of(context).areaHectares,
                                icon: Icons.landscape_outlined,
                                child: TextFormField(
                                  controller: _areaCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context).enterArea,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  validator: (v) {
                                    if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Enter a valid number';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ── Location section ──
                          _buildSectionCard(
                            icon: Icons.location_on,
                            iconColor: const Color(0xFF2D6A4F),
                            title: AppLocalizations.of(context).locationText,
                            children: [
                              _buildInputField(
                                label: AppLocalizations.of(context).locationLabel,
                                icon: Icons.place_outlined,
                                trailing: GestureDetector(
                                  onTap: _locating ? null : _detectLocation,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE8F5E9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: _locating
                                        ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B5E20))))
                                        : const Icon(Icons.my_location_rounded, color: Color(0xFF1B5E20), size: 20),
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _locationCtrl,
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context).locationLabel,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ── Planting details section ──
                          _buildSectionCard(
                            icon: Icons.calendar_month,
                            iconColor: const Color(0xFF2D6A4F),
                            title: AppLocalizations.of(context).plantingDetails,
                            children: [
                              _buildInputField(
                                label: AppLocalizations.of(context).plantingDate,
                                icon: Icons.calendar_today_outlined,
                                trailing: const Icon(Icons.calendar_today_outlined, color: Color(0xFF2D6A4F), size: 18),
                                onTap: _pickDate,
                                child: Text(
                                  _plantingDate != null ? DateFormatter.formatDate(_plantingDate!) : AppLocalizations.of(context).selectDate,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: _plantingDate != null ? FontWeight.w600 : FontWeight.w400,
                                    color: _plantingDate != null ? const Color(0xFF1B4332) : Colors.grey.shade500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildInputField(
                                label: AppLocalizations.of(context).notesOptional,
                                icon: Icons.notes_outlined,
                                child: TextFormField(
                                  controller: _notesCtrl,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context).addNotesHint,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // ── Save Field Button ──
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: const Color(0xFF1B5E20).withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                              ),
                              child: _loading
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.check_circle_outline, size: 20, color: Colors.white),
                                            ),
                                            const SizedBox(width: 14),
                                            Text(
                                              _isEditing ? AppLocalizations.of(context).saveChanges : AppLocalizations.of(context).saveField,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                                      ],
                                    ),
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

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B4332),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required Widget child,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FCF9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2EFE3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF2D6A4F), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  child,
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}


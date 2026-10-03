import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit field' : 'Add field')),
      body: _loading && _isEditing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(6)),
                        child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _SectionLabel('Field information'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Field name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Field name is required' : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _cropType,
                      decoration: const InputDecoration(labelText: 'Crop type'),
                      items: _cropTypes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) { if (v != null) setState(() => _cropType = v); },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _areaCtrl,
                      decoration: const InputDecoration(labelText: 'Area (hectares)', hintText: 'e.g. 2.5'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel('Location'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _locationCtrl,
                            decoration: const InputDecoration(labelText: 'Location label or coordinates'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          onPressed: _locating ? null : _detectLocation,
                          icon: _locating
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location_outlined),
                          tooltip: 'Use current location',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel('Planting details'),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(6),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Planting date',
                          suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                        ),
                        child: Text(
                          _plantingDate != null ? DateFormatter.formatDate(_plantingDate!) : 'Select date',
                          style: TextStyle(
                            color: _plantingDate != null ? AppColors.textPrimary : AppColors.textDisabled,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(labelText: 'Notes (optional)'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_isEditing ? 'Save changes' : 'Add field'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: Theme.of(context).textTheme.headlineSmall);
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/field_model.dart';
import '../../../../core/utils/date_formatter.dart';

class FieldCard extends StatelessWidget {
  final FieldModel field;
  final VoidCallback onTap;

  const FieldCard({super.key, required this.field, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8F0E8), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F5E9), Color(0xFFD8F3DC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D6A4F).withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.grass_rounded, color: Color(0xFF2D6A4F), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4332),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8F1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFC8E6C9), width: 0.8),
                          ),
                          child: Text(
                            field.cropType,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                        if (field.areHectares != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${field.areHectares!.toStringAsFixed(1)} ha',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B8F71),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF8),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE8F0E8)),
                ),
                child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF2D6A4F), size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

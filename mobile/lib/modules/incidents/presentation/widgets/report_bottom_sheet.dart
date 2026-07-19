import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../core/types/coordinate.dart';
import '../../domain/incident_entities.dart';
import '../providers/incident_providers.dart';

const _laPazCenter = Coordinate(lat: -16.5000, lng: -68.1500);

class ReportBottomSheet extends ConsumerStatefulWidget {
  const ReportBottomSheet({super.key});

  @override
  ConsumerState<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends ConsumerState<ReportBottomSheet> {
  IncidentKind _selectedKind = IncidentKind.blockade;
  final _descController = TextEditingController();
  File? _photo;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1080,
    );
    if (xFile != null && mounted) {
      setState(() => _photo = File(xFile.path));
    }
  }

  Future<void> _submit() async {
    final desc = _descController.text.trim();
    if (desc.length < 3) {
      setState(() => _error = 'Escribe al menos 3 caracteres');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final pos = await ref.read(locationServiceProvider).getCurrentCoordinate();
      final position = pos ?? _laPazCenter;

      final repo = ref.read(incidentRepositoryProvider);
      final incident = await repo.report(
        kind: _selectedKind,
        position: position,
        description: desc,
        photo: _photo,
      );

      ref.read(activeIncidentsProvider.notifier).addOptimistic(incident);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Reporte enviado — necesita 3 confirmaciones para activarse',
            ),
            backgroundColor: Colors.indigo[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final charCount = _descController.text.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildDragHandle(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  Text(
                    'Reportar incidente',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().fadeIn(duration: 250.ms),
                  const Gap(20),
                  _buildKindSelector(theme),
                  const Gap(20),
                  _buildLocationIndicator(theme),
                  const Gap(20),
                  _buildDescriptionField(theme, charCount),
                  if (_error != null) ...[
                    const Gap(8),
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                    ),
                  ],
                  const Gap(16),
                  _buildPhotoButton(theme),
                  const Gap(24),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildKindSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipo de incidente', style: theme.textTheme.labelLarge),
        const Gap(10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: IncidentKind.values.map((kind) {
              final isSelected = kind == _selectedKind;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text('${kind.emoji} ${kind.label}'),
                  onSelected: (_) => setState(() => _selectedKind = kind),
                  selectedColor: kind.chipColor,
                  labelStyle: TextStyle(
                    color: isSelected ? kind.chipTextColor : null,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.normal,
                  ),
                  checkmarkColor: kind.chipTextColor,
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 50.ms);
  }

  Widget _buildLocationIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.my_location, color: Colors.indigo[600], size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu ubicación actual',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(2),
                Text(
                  'El reporte se enviará desde donde estás ahora',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildDescriptionField(ThemeData theme, int charCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: _descController,
          onChanged: (_) => setState(() {}),
          maxLength: 280,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '¿Qué está pasando? Describe brevemente…',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const Gap(4),
        Text(
          '$charCount / 280',
          style: theme.textTheme.bodySmall?.copyWith(
            color: charCount > 260 ? Colors.orange[700] : Colors.grey[500],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 150.ms);
  }

  Widget _buildPhotoButton(ThemeData theme) {
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        height: _photo != null ? 160 : 72,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
        ),
        child: _photo != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_photo!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _photo = null),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_camera_outlined,
                      color: Colors.indigo[400], size: 22),
                  const Gap(8),
                  Text(
                    'Agregar foto (opcional)',
                    style: TextStyle(color: Colors.indigo[400]),
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  Widget _buildSubmitButton() {
    return FilledButton.icon(
      onPressed: _submitting ? null : _submit,
      icon: _submitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.send),
      label: const Text('Enviar reporte'),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.indigo[700],
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: 250.ms)
        .scaleXY(begin: 0.95, curve: Curves.easeOut);
  }
}

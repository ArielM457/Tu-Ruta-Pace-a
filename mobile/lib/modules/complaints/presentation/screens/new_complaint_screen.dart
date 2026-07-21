import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/chasqui_top_bar.dart';
import '../../domain/complaint_entities.dart';
import '../providers/complaints_providers.dart';
import '../widgets/complaint_type_ui.dart';

const double _minimumDescriptionLength = 3;

class NewComplaintScreen extends ConsumerStatefulWidget {
  const NewComplaintScreen({super.key});

  @override
  ConsumerState<NewComplaintScreen> createState() =>
      _NewComplaintScreenState();
}

class _NewComplaintScreenState extends ConsumerState<NewComplaintScreen> {
  final _vehicleController = TextEditingController();
  final _routeController = TextEditingController();
  final _descriptionController = TextEditingController();
  ComplaintType? _selectedType;
  File? _photo;
  String? _error;
  bool _submitted = false;

  @override
  void dispose() {
    _vehicleController.dispose();
    _routeController.dispose();
    _descriptionController.dispose();
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
    final type = _selectedType;
    final description = _descriptionController.text.trim();
    if (type == null) {
      setState(() => _error = 'Elige el tipo de incidente');
      return;
    }
    if (description.length < _minimumDescriptionLength) {
      setState(() => _error = 'Describe lo sucedido con más detalle');
      return;
    }
    setState(() => _error = null);

    final ok = await ref.read(createComplaintControllerProvider.notifier).submit(
          type: type,
          vehicleIdentifier: _emptyToNull(_vehicleController.text),
          routeLabel: _emptyToNull(_routeController.text),
          description: description,
          photo: _photo,
        );

    if (!mounted) return;
    if (!ok) {
      final error = ref.read(createComplaintControllerProvider).error;
      setState(
        () => _error =
            error?.toString() ?? 'No se pudo enviar la denuncia. Intenta de nuevo.',
      );
      return;
    }
    setState(() => _submitted = true);
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _ComplaintSuccessView(onDone: () => context.pop());
    }

    final theme = Theme.of(context);
    final submitState = ref.watch(createComplaintControllerProvider);

    return Scaffold(
      appBar: ChasquiTopBar(
        title: 'Nueva denuncia',
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text('TIPO DE INCIDENTE', style: theme.textTheme.labelSmall),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.6,
            children: [
              for (final type in ComplaintType.values)
                _ComplaintTypeChip(
                  type: type,
                  isSelected: type == _selectedType,
                  onTap: () => setState(() => _selectedType = type),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'PLACA O NOMBRE DEL CONDUCTOR',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _vehicleController,
            decoration: const InputDecoration(hintText: 'Ej: 1234-ABC o Juan P.'),
          ),
          const SizedBox(height: 16),
          Text('RUTA / LÍNEA', style: theme.textTheme.labelSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _routeController,
            decoration: const InputDecoration(hintText: 'Ej: Minibús 130'),
          ),
          const SizedBox(height: 16),
          Text('DESCRIPCIÓN', style: theme.textTheme.labelSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Describe lo sucedido con el mayor detalle posible...',
            ),
          ),
          const SizedBox(height: 16),
          _PhotoPickerButton(photo: _photo, onTap: _pickPhoto, onClear: () {
            setState(() => _photo = null);
          }),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: submitState.isLoading ? null : _submit,
            child: submitState.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar denuncia'),
          ),
        ],
      ),
    );
  }
}

class _ComplaintTypeChip extends StatelessWidget {
  const _ComplaintTypeChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final ComplaintType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: type.label,
      button: true,
      selected: isSelected,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: isSelected ? ChasquiColors.yellow300 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? ChasquiColors.yellow600
                  : ChasquiColors.neutral200,
            ),
          ),
          child: Text(
            type.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? ChasquiColors.neutral950
                  : ChasquiColors.neutral600,
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPickerButton extends StatelessWidget {
  const _PhotoPickerButton({
    required this.photo,
    required this.onTap,
    required this.onClear,
  });

  final File? photo;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photo != null;
    return Semantics(
      label: hasPhoto ? 'Foto adjunta, toca para cambiarla' : 'Adjuntar foto opcional',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: hasPhoto ? 160 : 56,
          decoration: BoxDecoration(
            color: ChasquiColors.neutral50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ChasquiColors.neutral300,
              style: BorderStyle.solid,
            ),
          ),
          child: hasPhoto
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(photo!, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Semantics(
                        label: 'Quitar foto',
                        button: true,
                        child: InkWell(
                          onTap: onClear,
                          customBorder: const CircleBorder(),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      size: 17,
                      color: ChasquiColors.neutral400,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Adjuntar foto (opcional)',
                      style: TextStyle(
                        fontSize: 13,
                        color: ChasquiColors.neutral500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ComplaintSuccessView extends StatelessWidget {
  const _ComplaintSuccessView({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ChasquiColors.yellow200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 36,
                  color: ChasquiColors.yellow800,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Denuncia enviada',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tu reporte fue registrado. Te notificaremos en menos de 24 horas.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: ChasquiColors.neutral500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDone,
                  child: const Text('Volver'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

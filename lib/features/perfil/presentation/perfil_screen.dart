import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../config/app_config.dart';
import '../../../core/events/event_type_visuals.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/event_type.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  static const LatLng _initialLocation = LatLng(-25.2637, -57.5759);

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _imagePicker = ImagePicker();

  int _currentStep = 0;
  EventType _selectedCategory = EventType.music;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 12, minute: 0);
  bool _hasTime = true;
  LatLng _selectedLocation = _initialLocation;
  Uint8List? _coverImageBytes;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
  }

  void _goNext() {
    if (_currentStep == 2) {
      _showCreatedMessage();
      return;
    }
    setState(() => _currentStep++);
  }

  Future<void> _pickCoverImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() => _coverImageBytes = bytes);
  }

  void _showCreatedMessage() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Evento listo para publicar')));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 122 + bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      step: _currentStep,
                      onClose: () {
                        setState(() => _currentStep = 0);
                      },
                    ),
                    const SizedBox(height: 28),
                    _StepProgress(step: _currentStep),
                    const SizedBox(height: 30),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _buildStep(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 10 + bottomPadding),
              child: Row(
                children: [
                  Expanded(
                    child: _SecondaryButton(
                      label: 'Atras',
                      onPressed: _currentStep == 0 ? null : _goBack,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _PrimaryButton(
                      label: _currentStep == 2 ? 'CREAR' : 'Siguiente',
                      onPressed: _goNext,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_currentStep) {
      0 => _BasicsStep(
        key: const ValueKey(0),
        titleController: _titleController,
        descriptionController: _descriptionController,
        priceController: _priceController,
      ),
      1 => _DetailsStep(
        key: const ValueKey(1),
        selectedCategory: _selectedCategory,
        locationController: _locationController,
        selectedLocation: _selectedLocation,
        coverImageBytes: _coverImageBytes,
        onCategorySelected: (type) {
          setState(() => _selectedCategory = type);
        },
        onLocationSelected: (location) {
          setState(() => _selectedLocation = location);
        },
        onPickCover: _pickCoverImage,
      ),
      _ => _DateStep(
        key: const ValueKey(2),
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        hasTime: _hasTime,
        onDateChanged: (date) {
          setState(() => _selectedDate = date);
        },
        onTimeChanged: (time) {
          setState(() => _selectedTime = time);
        },
        onTimeModeChanged: (value) {
          setState(() => _hasTime = value);
        },
      ),
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.step, required this.onClose});

  final int step;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final title = switch (step) {
      0 => 'Nuevo evento',
      1 => 'Los detalles',
      _ => 'Cuando?',
    };
    final subtitle = switch (step) {
      0 => 'Nombre, descripcion y precio',
      1 => 'Categoria, ubicacion e imagen',
      _ => 'Dia y horario del evento',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PASO ${step + 1} DE 3',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.onSurfaceMuted,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        IconButton.filled(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceElevated,
            foregroundColor: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: (step + 1) / 3,
        minHeight: 4,
        backgroundColor: AppColors.surfaceElevated,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }
}

class _BasicsStep extends StatelessWidget {
  const _BasicsStep({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.priceController,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('NOMBRE DEL EVENTO *'),
        _AppTextField(
          controller: titleController,
          hintText: 'Ej. Noche de jazz en vivo',
          icon: Icons.event_rounded,
        ),
        const SizedBox(height: 22),
        const _SectionLabel('DESCRIPCION'),
        _AppTextField(
          controller: descriptionController,
          hintText: 'Cuenta que va a pasar...',
          icon: Icons.notes_rounded,
          maxLines: 4,
        ),
        const SizedBox(height: 22),
        const _SectionLabel('PRECIO'),
        _AppTextField(
          controller: priceController,
          hintText: 'Gs 0',
          icon: Icons.payments_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: [_GuaraniPriceFormatter()],
        ),
      ],
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    super.key,
    required this.selectedCategory,
    required this.locationController,
    required this.selectedLocation,
    required this.coverImageBytes,
    required this.onCategorySelected,
    required this.onLocationSelected,
    required this.onPickCover,
  });

  final EventType selectedCategory;
  final TextEditingController locationController;
  final LatLng selectedLocation;
  final Uint8List? coverImageBytes;
  final ValueChanged<EventType> onCategorySelected;
  final ValueChanged<LatLng> onLocationSelected;
  final VoidCallback onPickCover;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('CATEGORIA *'),
        SizedBox(
          height: 58,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: EventType.filterable.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final type = EventType.filterable[index];
              return _CategoryChip(
                type: type,
                selected: type == selectedCategory,
                onTap: () => onCategorySelected(type),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('UBICACION *'),
        _LocationPicker(
          controller: locationController,
          selectedLocation: selectedLocation,
          onLocationSelected: onLocationSelected,
        ),
        const SizedBox(height: 24),
        const _SectionLabel('IMAGEN (opcional)'),
        _CoverPicker(imageBytes: coverImageBytes, onTap: onPickCover),
      ],
    );
  }
}

class _DateStep extends StatelessWidget {
  const _DateStep({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.hasTime,
    required this.onDateChanged,
    required this.onTimeChanged,
    required this.onTimeModeChanged,
  });

  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final bool hasTime;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final ValueChanged<bool> onTimeModeChanged;

  Future<void> _pickDate(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: DateUtils.dateOnly(selectedDate).isBefore(today)
          ? today
          : selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.onSurface,
              surface: AppColors.surface,
              onSurface: AppColors.onSurface,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: AppColors.surface,
              todayBorder: BorderSide(color: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) onDateChanged(date);
  }

  Future<void> _pickTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.onSurface,
              surface: AppColors.surface,
              onSurface: AppColors.onSurface,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.surface,
              hourMinuteColor: AppColors.surfaceElevated,
              hourMinuteTextColor: AppColors.onSurface,
              dialHandColor: AppColors.primary,
              dialBackgroundColor: AppColors.surfaceElevated,
              entryModeIconColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) onTimeChanged(time);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatMediumDate(selectedDate);
    final timeLabel = selectedTime.format(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('DIA'),
        _PickerTile(
          icon: Icons.calendar_month_rounded,
          label: dateLabel,
          onTap: () => _pickDate(context),
        ),
        const SizedBox(height: 28),
        const _SectionLabel('HORARIO'),
        Row(
          children: [
            _ModeChip(
              label: 'Sin horario',
              selected: !hasTime,
              onTap: () => onTimeModeChanged(false),
            ),
            const SizedBox(width: 12),
            _ModeChip(
              label: 'Con horario',
              selected: hasTime,
              onTap: () => onTimeModeChanged(true),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (hasTime)
          _PickerTile(
            icon: Icons.schedule_rounded,
            label: timeLabel,
            onTap: () => _pickTime(context),
          )
        else
          const _TimePill(label: 'Durante todo el dia'),
      ],
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: AppColors.onSurface, fontSize: 17),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.onSurfaceMuted),
        prefixIcon: Icon(icon, color: AppColors.onSurfaceMuted),
        filled: true,
        fillColor: const Color(0xFF171A1D),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.surfaceElevated),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.surfaceElevated),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _LocationPicker extends StatefulWidget {
  const _LocationPicker({
    required this.controller,
    required this.selectedLocation,
    required this.onLocationSelected,
  });

  final TextEditingController controller;
  final LatLng selectedLocation;
  final ValueChanged<LatLng> onLocationSelected;

  @override
  State<_LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<_LocationPicker> {
  final _placesService = _GooglePlacesService();
  GoogleMapController? _mapController;
  Timer? _debounce;
  List<_PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;
  String? _searchMessage;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onQueryChanged);
  }

  @override
  void didUpdateWidget(covariant _LocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onQueryChanged);
      widget.controller.addListener(_onQueryChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController?.dispose();
    widget.controller.removeListener(_onQueryChanged);
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    final query = widget.controller.text.trim();
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _searchMessage = null;
      });
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _searchLocation(query),
    );
  }

  Future<void> _searchLocation([String? forcedQuery]) async {
    final query = (forcedQuery ?? widget.controller.text).trim();
    if (query.length < 3) return;

    setState(() {
      _isSearching = true;
      _searchMessage = null;
    });
    final suggestions = await _placesService.search(query);
    if (!mounted) return;
    setState(() {
      _suggestions = suggestions;
      _isSearching = false;
      _searchMessage = suggestions.isEmpty
          ? 'No se encontraron resultados'
          : null;
    });
  }

  Future<void> _selectSuggestion(_PlaceSuggestion suggestion) async {
    final location =
        suggestion.location ?? await _placesService.resolve(suggestion.placeId);
    if (location == null || !mounted) return;

    widget.controller.text = suggestion.description;
    widget.onLocationSelected(location);
    setState(() => _suggestions = []);
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(location, 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasApiKey = AppConfig.hasGoogleMapsApiKey;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF171A1D),
          border: Border.all(color: AppColors.surfaceElevated),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 17,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchLocation(),
                    decoration: InputDecoration(
                      hintText: hasApiKey
                          ? 'Buscar direccion en Google Maps...'
                          : 'Configura GOOGLE_MAPS_API_KEY',
                      hintStyle: const TextStyle(
                        color: AppColors.onSurfaceMuted,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.onSurfaceMuted,
                      ),
                      suffixIcon: widget.controller.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                widget.controller.clear();
                                setState(() {
                                  _suggestions = [];
                                  _searchMessage = null;
                                });
                              },
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Buscar',
                  onPressed: hasApiKey && !_isSearching
                      ? () => _searchLocation()
                      : null,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
              ],
            ),
            if (_isSearching) const LinearProgressIndicator(minHeight: 2),
            if (_searchMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _searchMessage!,
                    style: const TextStyle(
                      color: AppColors.onSurfaceMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            if (_suggestions.isNotEmpty)
              ..._suggestions
                  .take(4)
                  .map(
                    (suggestion) => ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        suggestion.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _selectSuggestion(suggestion),
                    ),
                  ),
            const Divider(height: 1, color: AppColors.surfaceElevated),
            SizedBox(
              height: 190,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: widget.selectedLocation,
                  zoom: 14,
                ),
                onMapCreated: (controller) => _mapController = controller,
                markers: {
                  Marker(
                    markerId: const MarkerId('event-location'),
                    position: widget.selectedLocation,
                  ),
                },
                onTap: (location) {
                  widget.onLocationSelected(location);
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(location),
                  );
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverPicker extends StatelessWidget {
  const _CoverPicker({required this.imageBytes, required this.onTap});

  final Uint8List? imageBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 188,
      height: 188,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surfaceElevated),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: imageBytes == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.transparent,
                          foregroundColor: AppColors.primary,
                          child: Icon(Icons.add_rounded, size: 38),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Agregar portada',
                          style: TextStyle(
                            color: AppColors.onSurfaceMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(imageBytes!, fit: BoxFit.cover),
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.56,
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final EventType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? EventTypeVisuals.color(type).withValues(alpha: 0.22)
              : null,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? EventTypeVisuals.color(type)
                : AppColors.surfaceElevated,
          ),
        ),
        child: Row(
          children: [
            Icon(
              EventTypeVisuals.icon(type),
              color: EventTypeVisuals.color(type),
            ),
            const SizedBox(width: 10),
            Text(
              type.label,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.surfaceElevated,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.onSurface, fontSize: 22),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.surfaceElevated),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.onSurfaceMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        child: Text(label),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.onSurfaceMuted,
          side: BorderSide(
            color: onPressed == null
                ? AppColors.surfaceElevated
                : AppColors.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        child: Text(label),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.onSurfaceMuted,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _GuaraniPriceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = 'Gs ${_groupDigits(digits)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _groupDigits(String value) {
    final buffer = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      final remaining = value.length - index;
      buffer.write(value[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }
}

class _GooglePlacesService {
  static const _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  Future<List<_PlaceSuggestion>> search(String query) async {
    if (!AppConfig.hasGoogleMapsApiKey) return [];

    final uri = Uri.parse('$_baseUrl/autocomplete/json').replace(
      queryParameters: {
        'input': query,
        'key': AppConfig.googleMapsApiKey,
        'language': 'es',
        'components': 'country:py',
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final predictions = data['predictions'] as List<dynamic>? ?? [];
      final placeSuggestions = predictions
          .map(
            (item) => _PlaceSuggestion.fromJson(item as Map<String, dynamic>),
          )
          .toList();
      if (placeSuggestions.isNotEmpty) return placeSuggestions;

      return _searchByGeocoding(query);
    } catch (_) {
      return _searchByGeocoding(query);
    }
  }

  Future<List<_PlaceSuggestion>> _searchByGeocoding(String query) async {
    final uri = Uri.parse(_geocodeUrl).replace(
      queryParameters: {
        'address': query,
        'key': AppConfig.googleMapsApiKey,
        'language': 'es',
        'components': 'country:PY',
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      return results
          .take(5)
          .map((item) {
            final json = item as Map<String, dynamic>;
            final geometry = json['geometry'] as Map<String, dynamic>?;
            final location = geometry?['location'] as Map<String, dynamic>?;
            if (location == null) return null;

            return _PlaceSuggestion(
              placeId:
                  json['place_id'] as String? ??
                  json['formatted_address'] as String,
              description: json['formatted_address'] as String,
              location: LatLng(
                (location['lat'] as num).toDouble(),
                (location['lng'] as num).toDouble(),
              ),
            );
          })
          .whereType<_PlaceSuggestion>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<LatLng?> resolve(String placeId) async {
    if (!AppConfig.hasGoogleMapsApiKey) return null;

    final uri = Uri.parse('$_baseUrl/details/json').replace(
      queryParameters: {
        'place_id': placeId,
        'key': AppConfig.googleMapsApiKey,
        'language': 'es',
        'fields': 'geometry',
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      final geometry = result?['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      if (location == null) return null;

      return LatLng(
        (location['lat'] as num).toDouble(),
        (location['lng'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}

class _PlaceSuggestion {
  const _PlaceSuggestion({
    required this.placeId,
    required this.description,
    this.location,
  });

  factory _PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return _PlaceSuggestion(
      placeId: json['place_id'] as String,
      description: json['description'] as String,
    );
  }

  final String placeId;
  final String description;
  final LatLng? location;
}

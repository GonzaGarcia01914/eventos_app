import 'dart:async';
import 'package:flutter/material.dart';

class AddressSearchField extends StatefulWidget {
  final Function(String) onSearch;
  final Duration debounceTime;

  const AddressSearchField({
    super.key,
    required this.onSearch,
    this.debounceTime = const Duration(milliseconds: 500),
  });

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  Timer? _debounce;

  void _onChanged(String value) {
    // Cancela el timer anterior si el usuario sigue escribiendo antes de que expire
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Inicia un nuevo timer que ejecutará la búsqueda tras el tiempo de espera definido
    _debounce = Timer(widget.debounceTime, () {
      widget.onSearch(value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: _onChanged,
      decoration: const InputDecoration(
        labelText: 'Buscar dirección',
        prefixIcon: Icon(Icons.location_on),
        border: OutlineInputBorder(),
      ),
    );
  }
}

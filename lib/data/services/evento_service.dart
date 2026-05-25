import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EventoService {
  final String baseUrl = "https://backend-eventos.eventospy.workers.dev";

  Future<bool> crearEvento({
    required String nombre,
    required String descripcion,
    required double precio,
    required List<String> categorias,
    required String ubicacionMaps,
    required XFile fotoOriginal,
    required String fecha,
    required String hora,
  }) async {
    try {
      // 1. LEER IMAGEN
      _log("1/4 - Leyendo imagen seleccionada...");
      final bytesImagen = await fotoOriginal.readAsBytes();
      if (bytesImagen.isEmpty) {
        _logError("Cancelado: la imagen seleccionada está vacía");
        return false;
      }
      _log("✅ Imagen leída: ${bytesImagen.length} bytes");

      // 2. SUBIR IMAGEN AL WORKER
      _log("2/4 - Subiendo imagen a Cloudflare R2...");
      final respuestaUpload = await _subirFoto(bytesImagen, fotoOriginal.name);
      if (respuestaUpload == null) {
        _logError("❌ Error al subir la imagen a R2");
        return false;
      }
      _log("✅ Imagen subida exitosamente");

      final String finalUrl = respuestaUpload;

      // 3. GUARDAR EN D1
      _log("3/4 - Creando evento en base de datos D1...");
      final respuestaFinal = await http.post(
        Uri.parse("$baseUrl/api/eventos"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nombre": nombre,
          "descripcion": descripcion,
          "precio": precio,
          "categorias": categorias,
          "ubicacion_maps": ubicacionMaps,
          "imagen_url": finalUrl,
          "fecha": fecha,
          "hora": hora,
        }),
      );

      if (respuestaFinal.statusCode == 201) {
        _log("✅ 4/4 - Evento creado correctamente y enviado a aprobación");
        return true;
      } else {
        _logError("❌ Error al guardar en D1 (HTTP ${respuestaFinal.statusCode})");
        _logError("Respuesta: ${respuestaFinal.body}");
        return false;
      }
    } catch (e, stacktrace) {
      _logError("❌ Excepción no controlada: $e");
      _logError("Stack trace: $stacktrace");
      return false;
    }
  }

  String _safeImageName(String originalName) {
    final extension = originalName.split('.').last.toLowerCase();
    final safeExtension = switch (extension) {
      'jpg' || 'jpeg' || 'png' || 'webp' => extension,
      _ => 'jpg',
    };
    return 'evento_${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
  }

  String _contentTypeFor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };
  }

  Future<String?> _subirFoto(List<int> bytesImagen, String originalName) async {
    try {
      // 1. Obtener URL firmada de R2
      _log("Paso 1: Solicitando URL firmada...");
      final fileName = _safeImageName(originalName);
      final respuestaFirmada = await http.post(
        Uri.parse("$baseUrl/api/obtener-url-foto"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"nombreArchivo": fileName}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logError("Timeout al obtener URL firmada (>10s)");
          throw TimeoutException('Timeout obteniendo URL firmada');
        },
      );

      if (respuestaFirmada.statusCode != 200) {
        _logError(
          "Error al obtener URL firmada: HTTP ${respuestaFirmada.statusCode}",
        );
        _logError("Respuesta: ${respuestaFirmada.body}");
        return null;
      }

      _log("✅ URL firmada obtenida");
      final datosUrl = jsonDecode(respuestaFirmada.body) as Map<String, dynamic>;
      final uploadUrl = datosUrl['uploadUrl'] as String;
      final finalUrl = datosUrl['finalUrl'] as String;

      // 2. Subir archivo directamente a R2 con la URL firmada
      _log("Paso 2: Subiendo imagen a R2 (${bytesImagen.length} bytes)...");
      final respuestaR2 = await http.put(
        Uri.parse(uploadUrl),
        body: bytesImagen,
        headers: {"Content-Type": _contentTypeFor(fileName)},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logError("Timeout al subir a R2 (>30s)");
          throw TimeoutException('Timeout subiendo a R2');
        },
      );

      if (respuestaR2.statusCode != 200) {
        _logError("Error en R2: HTTP ${respuestaR2.statusCode}");
        if (respuestaR2.body.isNotEmpty) {
          _logError("Detalles: ${respuestaR2.body}");
        }
        return null;
      }

      _log("✅ Imagen subida exitosamente a R2");
      _log("URL final: $finalUrl");
      return finalUrl;
    } catch (e) {
      _logError("Excepción en _subirFoto: $e");
      return null;
    }
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1];
    print("[EVENTOS] [$timestamp] $message");
  }

  void _logError(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1];
    print("[EVENTOS ERROR] [$timestamp] $message");
  }

  Future<List<dynamic>> obtenerEventosAprobados() async {
    try {
      _log("Obteniendo eventos aprobados...");
      final respuesta = await http.get(
        Uri.parse("$baseUrl/api/eventos/aprobados"),
      );

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body);
        _log("✅ Se cargaron ${datos.length} eventos aprobados");
        return datos;
      }

      _logError(
        "Error obteniendo eventos: HTTP ${respuesta.statusCode}",
      );
      _logError("Respuesta: ${respuesta.body}");
      return [];
    } catch (e) {
      _logError("Error de conexión: $e");
      return [];
    }
  }

  Future<List<dynamic>> obtenerEventosPendientesAdmin() async {
    try {
      _log("Obteniendo eventos pendientes (Admin)...");
      final respuesta = await http.get(
        Uri.parse("$baseUrl/api/admin/pendientes"),
      );

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body);
        _log("✅ Se cargaron ${datos.length} eventos pendientes");
        return datos;
      }

      _logError("Error obteniendo pendientes: HTTP ${respuesta.statusCode}");
      _logError("Respuesta: ${respuesta.body}");
      return [];
    } catch (e) {
      _logError("Error de conexión: $e");
      return [];
    }
  }

  Future<bool> aprobarEvento(int idEvento) async {
    try {
      _log("Aprobando evento ID $idEvento...");
      final respuesta = await http.post(
        Uri.parse("$baseUrl/api/admin/aprobar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": idEvento}),
      );

      if (respuesta.statusCode == 200) {
        _log("✅ Evento $idEvento aprobado");
        return true;
      }

      _logError("Error aprobando evento: HTTP ${respuesta.statusCode}");
      _logError("Respuesta: ${respuesta.body}");
      return false;
    } catch (e) {
      _logError("Error de conexión: $e");
      return false;
    }
  }

  Future<bool> eliminarEvento(int idEvento) async {
    try {
      _log("Eliminando evento ID $idEvento...");
      final respuesta = await http.post(
        Uri.parse("$baseUrl/api/admin/eliminar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": idEvento}),
      );

      if (respuesta.statusCode == 200) {
        _log("✅ Evento $idEvento eliminado");
        return true;
      }

      _logError("Error eliminando evento: HTTP ${respuesta.statusCode}");
      _logError("Respuesta: ${respuesta.body}");
      return false;
    } catch (e) {
      _logError("Error de conexión: $e");
      return false;
    }
  }
}

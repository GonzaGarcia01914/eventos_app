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
      print("[CrearEvento] 1/4 - Leyendo imagen seleccionada...");
      final bytesImagen = await fotoOriginal.readAsBytes();
      if (bytesImagen.isEmpty) {
        print("[CrearEvento] Cancelado: la imagen seleccionada esta vacia.");
        return false;
      }

      // 2. SUBIR IMAGEN AL WORKER
      print("[CrearEvento] 2/4 - Subiendo imagen a Cloudflare...");
      final respuestaUpload = await _subirFoto(bytesImagen, fotoOriginal.name);
      if (respuestaUpload == null) {
        print("[CrearEvento] Error al subir la imagen.");
        return false;
      }

      final String finalUrl = respuestaUpload;

      // 3. GUARDAR EN D1
      print(
        "[CrearEvento] 3/4 - Insertando datos del evento en la base de datos D1...",
      );
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
        print("[CrearEvento] Evento creado correctamente.");
        return true;
      } else {
        print("[CrearEvento] Error al guardar el registro final en D1.");
        print("   Codigo HTTP: ${respuestaFinal.statusCode}");
        print("   Cuerpo de respuesta: ${respuestaFinal.body}");
        return false;
      }
    } catch (e, stacktrace) {
      print("[CrearEvento] Excepcion atrapada en el proceso:");
      print("   Error: $e");
      print("   Stacktrace: $stacktrace");
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
    // 1. Obtener URL firmada de R2
    print("[SubirFoto] 1/2 - Obteniendo URL firmada...");
    final fileName = _safeImageName(originalName);
    final respuestaFirmada = await http.post(
      Uri.parse("$baseUrl/api/obtener-url-foto"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nombreArchivo": fileName}),
    );

    if (respuestaFirmada.statusCode != 200) {
      print(
        "[SubirFoto] Error al obtener URL firmada. Codigo: ${respuestaFirmada.statusCode}",
      );
      return null;
    }

    final datosUrl = jsonDecode(respuestaFirmada.body) as Map<String, dynamic>;
    final uploadUrl = datosUrl['uploadUrl'] as String;
    final finalUrl = datosUrl['finalUrl'] as String;

    // 2. Subir archivo directamente a R2 con la URL firmada
    print("[SubirFoto] 2/2 - Subiendo a R2...");
    try {
      final respuestaR2 = await http.put(
        Uri.parse(uploadUrl),
        body: bytesImagen,
        headers: {"Content-Type": _contentTypeFor(fileName)},
      );

      if (respuestaR2.statusCode != 200) {
        print("[SubirFoto] Error en R2. Codigo: ${respuestaR2.statusCode}");
        print("[SubirFoto] Respuesta: ${respuestaR2.body}");
        return null;
      }

      print("[SubirFoto] Archivo subido exitosamente a: $finalUrl");
      return finalUrl;
    } catch (e) {
      print("[SubirFoto] Excepcion: $e");
      return null;
    }
  }

  Future<List<dynamic>> obtenerEventosAprobados() async {
    try {
      print("📥 [ObtenerAprobados] Solicitando eventos aprobados...");
      final respuesta = await http.get(
        Uri.parse("$baseUrl/api/eventos/aprobados"),
      );

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body);
        print(
          "✅ [ObtenerAprobados] Éxito: Se cargaron ${datos.length} eventos.",
        );
        return datos;
      }

      print(
        "❌ [ObtenerAprobados] Falló. Código HTTP: ${respuesta.statusCode}. Respuesta: ${respuesta.body}",
      );
      return [];
    } catch (e) {
      print("🚨 [ObtenerAprobados] Error de conexión: $e");
      return [];
    }
  }

  Future<List<dynamic>> obtenerEventosPendientesAdmin() async {
    try {
      print(
        "🕵️‍♂️ [ObtenerPendientes] Solicitando eventos pendientes para Admin...",
      );
      final respuesta = await http.get(
        Uri.parse("$baseUrl/api/admin/pendientes"),
      );

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body);
        print(
          "✅ [ObtenerPendientes] Éxito: Se cargaron ${datos.length} eventos pendientes.",
        );
        return datos;
      }

      print(
        "❌ [ObtenerPendientes] Falló. Código HTTP: ${respuesta.statusCode}. Respuesta: ${respuesta.body}",
      );
      return [];
    } catch (e) {
      print("🚨 [ObtenerPendientes] Error de conexión: $e");
      return [];
    }
  }

  Future<bool> aprobarEvento(int idEvento) async {
    try {
      print(
        "⚡ [AprobarEvento] Solicitando aprobación para el evento ID: $idEvento...",
      );
      final respuesta = await http.post(
        Uri.parse("$baseUrl/api/admin/aprobar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": idEvento}),
      );

      if (respuesta.statusCode == 200) {
        print("✅ [AprobarEvento] ¡Evento con ID $idEvento aprobado con éxito!");
        return true;
      }

      print(
        "❌ [AprobarEvento] Falló. Código HTTP: ${respuesta.statusCode}. Respuesta: ${respuesta.body}",
      );
      return false;
    } catch (e) {
      print("🚨 [AprobarEvento] Error de conexión: $e");
      return false;
    }
  }

  Future<bool> eliminarEvento(int idEvento) async {
    try {
      print(
        "[EliminarEvento] Solicitando eliminacion del evento ID: $idEvento...",
      );
      final respuesta = await http.post(
        Uri.parse("$baseUrl/api/admin/eliminar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": idEvento}),
      );

      if (respuesta.statusCode == 200) {
        print("[EliminarEvento] Evento con ID $idEvento eliminado.");
        return true;
      }

      print(
        "[EliminarEvento] Fallo. Codigo HTTP: ${respuesta.statusCode}. Respuesta: ${respuesta.body}",
      );
      return false;
    } catch (e) {
      print("[EliminarEvento] Error de conexion: $e");
      return false;
    }
  }
}

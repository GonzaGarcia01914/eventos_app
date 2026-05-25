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

      // 2. OBTENER URL FIRMADA
      print("[CrearEvento] 2/4 - Solicitando URL firmada a Cloudflare...");
      final respuestaUrls = await http.post(
        Uri.parse("$baseUrl/api/obtener-url-foto"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"nombreArchivo": _safeImageName()}),
      );

      if (respuestaUrls.statusCode != 200) {
        print("[CrearEvento] Error en api/obtener-url-foto.");
        print("   Codigo HTTP: ${respuestaUrls.statusCode}");
        print("   Cuerpo de respuesta: ${respuestaUrls.body}");
        return false;
      }

      final datosUrls = jsonDecode(respuestaUrls.body);
      final String uploadUrl = datosUrls["uploadUrl"];
      final String finalUrl = datosUrls["finalUrl"];

      // 3. SUBIR A R2
      print(
        "[CrearEvento] 3/4 - Subiendo bytes de imagen directamente a R2...",
      );
      final respuestaR2 = await http.put(
        Uri.parse(uploadUrl),
        headers: {"Content-Type": "image/jpeg"},
        body: bytesImagen,
      );

      if (respuestaR2.statusCode != 200) {
        print(
          "[CrearEvento] Error al subir la imagen directamente a Cloudflare R2.",
        );
        print("   Codigo HTTP: ${respuestaR2.statusCode}");
        print("   Cuerpo de respuesta: ${respuestaR2.body}");
        print(
          "   Tip: Verifica que las llaves R2 en tu wrangler.toml sean las S3 Credentials correctas.",
        );
        return false;
      }

      // 4. GUARDAR EN D1
      print(
        "[CrearEvento] 4/4 - Insertando datos del evento en la base de datos D1...",
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

  String _safeImageName() {
    return 'evento_${DateTime.now().millisecondsSinceEpoch}.jpg';
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

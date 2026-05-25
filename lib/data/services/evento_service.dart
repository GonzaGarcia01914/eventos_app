// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:http/http.dart' as http;

// class EventoService {
//   final String baseUrl = "https://backend-eventos.eventospy.workers.dev";

//   Future<File?> comprimirImagen(File archivoOriginal) async {
//     final rutaDestino = "${archivoOriginal.path}_comprimida.jpg";
//     final XFile? archivoComprimido =
//         await FlutterImageCompress.compressAndGetFile(
//           archivoOriginal.path,
//           rutaDestino,
//           quality: 75,
//           minWidth: 1080,
//           minHeight: 1080,
//           format: CompressFormat.jpeg,
//         );
//     return archivoComprimido != null ? File(archivoComprimido.path) : null;
//   }

//   Future<bool> crearEvento({
//     required String nombre,
//     required String descripcion,
//     required double precio,
//     required List<String> categorias,
//     required String ubicacionMaps,
//     required File fotoOriginal,
//     required String fecha,
//     required String hora,
//   }) async {
//     try {
//       File? fotoComprimida = await comprimirImagen(fotoOriginal);
//       if (fotoComprimida == null) return false;

//       final respuestaUrls = await http.post(
//         Uri.parse("$baseUrl/api/obtener-url-foto"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"nombreArchivo": "evento.jpg"}),
//       );

//       if (respuestaUrls.statusCode != 200) return false;
//       final datosUrls = jsonDecode(respuestaUrls.body);
//       final String uploadUrl = datosUrls["uploadUrl"];
//       final String finalUrl = datosUrls["finalUrl"];

//       final bytesImagen = await fotoComprimida.readAsBytes();
//       final respuestaR2 = await http.put(
//         Uri.parse(uploadUrl),
//         headers: {"Content-Type": "image/jpeg"},
//         body: bytesImagen,
//       );
//       if (respuestaR2.statusCode != 200) return false;

//       final respuestaFinal = await http.post(
//         Uri.parse("$baseUrl/api/eventos"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "nombre": nombre,
//           "descripcion": descripcion,
//           "precio": precio,
//           "categorias": categorias,
//           "ubicacion_maps": ubicacionMaps,
//           "imagen_url": finalUrl,
//           "fecha": fecha,
//           "hora": hora,
//         }),
//       );
//       return respuestaFinal.statusCode == 201;
//     } catch (e) {
//       return false;
//     }
//   }

//   Future<List<dynamic>> obtenerEventosAprobados() async {
//     try {
//       final respuesta = await http.get(
//         Uri.parse("$baseUrl/api/eventos/aprobados"),
//       );
//       if (respuesta.statusCode == 200) return jsonDecode(respuesta.body);
//       return [];
//     } catch (e) {
//       return [];
//     }
//   }

//   Future<List<dynamic>> obtenerEventosPendientesAdmin() async {
//     try {
//       final respuesta = await http.get(
//         Uri.parse("$baseUrl/api/admin/pendientes"),
//       );
//       if (respuesta.statusCode == 200) return jsonDecode(respuesta.body);
//       return [];
//     } catch (e) {
//       return [];
//     }
//   }

//   Future<bool> aprobarEvento(int idEvento) async {
//     try {
//       final respuesta = await http.post(
//         Uri.parse("$baseUrl/api/admin/aprobar"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"id": idEvento}),
//       );
//       return respuesta.statusCode == 200;
//     } catch (e) {
//       return false;
//     }
//   }
// }
import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

class EventoService {
  final String baseUrl = "https://backend-eventos.eventospy.workers.dev";

  Future<File?> comprimirImagen(File archivoOriginal) async {
    try {
      final rutaDestino = "${archivoOriginal.path}_comprimida.jpg";
      final XFile? archivoComprimido =
          await FlutterImageCompress.compressAndGetFile(
            archivoOriginal.path,
            rutaDestino,
            quality: 75,
            minWidth: 1080,
            minHeight: 1080,
            format: CompressFormat.jpeg,
          );

      if (archivoComprimido == null) {
        print("⚠️ [Comprimir] La compresión devolvió un archivo nulo.");
        return null;
      }
      return File(archivoComprimido.path);
    } catch (e) {
      print("🚨 [Comprimir] Error crítico comprimiendo la imagen: $e");
      return null;
    }
  }

  Future<bool> crearEvento({
    required String nombre,
    required String descripcion,
    required double precio,
    required List<String> categorias,
    required String ubicacionMaps,
    required File fotoOriginal,
    required String fecha,
    required String hora,
  }) async {
    try {
      // 1. COMPRESIÓN
      print("📸 [CrearEvento] 1/4 - Iniciando compresión de imagen...");
      File? fotoComprimida = await comprimirImagen(fotoOriginal);
      if (fotoComprimida == null) {
        print("❌ [CrearEvento] Cancelado: Falló la compresión de la imagen.");
        return false;
      }

      // 2. OBTENER URL FIRMADA
      print("🌐 [CrearEvento] 2/4 - Solicitando URL firmada a Cloudflare...");
      final respuestaUrls = await http.post(
        Uri.parse("$baseUrl/api/obtener-url-foto"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"nombreArchivo": "evento.jpg"}),
      );

      if (respuestaUrls.statusCode != 200) {
        print("❌ [CrearEvento] Error en api/obtener-url-foto.");
        print("   Código HTTP: ${respuestaUrls.statusCode}");
        print("   Cuerpo de respuesta: ${respuestaUrls.body}");
        return false;
      }

      final datosUrls = jsonDecode(respuestaUrls.body);
      final String uploadUrl = datosUrls["uploadUrl"];
      final String finalUrl = datosUrls["finalUrl"];

      // 3. SUBIR A R2
      print(
        "☁️ [CrearEvento] 3/4 - Subiendo bytes de imagen comprimida directamente a R2...",
      );
      final bytesImagen = await fotoComprimida.readAsBytes();
      final respuestaR2 = await http.put(
        Uri.parse(uploadUrl),
        headers: {"Content-Type": "image/jpeg"},
        body: bytesImagen,
      );

      if (respuestaR2.statusCode != 200) {
        print(
          "❌ [CrearEvento] Error al subir la imagen directamente a Cloudflare R2.",
        );
        print("   Código HTTP: ${respuestaR2.statusCode}");
        print("   Cuerpo de respuesta: ${respuestaR2.body}");
        print(
          "   💡 Tip: Verifica que las llaves R2 en tu wrangler.toml sean las S3 Credentials correctas.",
        );
        return false;
      }

      // 4. GUARDAR EN D1
      print(
        "💾 [CrearEvento] 4/4 - Insertando datos del evento en la base de datos D1...",
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
        print("🎉 [CrearEvento] ¡Éxito rotundo! Evento creado correctamente.");
        return true;
      } else {
        print("❌ [CrearEvento] Error al guardar el registro final en D1.");
        print("   Código HTTP: ${respuestaFinal.statusCode}");
        print("   Cuerpo de respuesta: ${respuestaFinal.body}");
        return false;
      }
    } catch (e, stacktrace) {
      print("🚨 [CrearEvento] Excepción fatal atrapada en el proceso:");
      print("   Error: $e");
      print("   Stacktrace: $stacktrace");
      return false;
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

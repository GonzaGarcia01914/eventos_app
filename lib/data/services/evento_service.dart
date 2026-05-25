import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

class EventoService {
  final String baseUrl = "https://backend-eventos.eventospy.workers.dev";

  Future<File?> comprimirImagen(File archivoOriginal) async {
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
    return archivoComprimido != null ? File(archivoComprimido.path) : null;
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
      File? fotoComprimida = await comprimirImagen(fotoOriginal);
      if (fotoComprimida == null) return false;

      final respuestaUrls = await http.post(
        Uri.parse("$baseUrl/api/obtener-url-foto"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"nombreArchivo": "evento.jpg"}),
      );

      if (respuestaUrls.statusCode != 200) return false;
      final datosUrls = jsonDecode(respuestaUrls.body);
      final String uploadUrl = datosUrls["uploadUrl"];
      final String finalUrl = datosUrls["finalUrl"];

      final bytesImagen = await fotoComprimida.readAsBytes();
      final respuestaR2 = await http.put(
        Uri.parse(uploadUrl),
        headers: {"Content-Type": "image/jpeg"},
        body: bytesImagen,
      );
      if (respuestaR2.statusCode != 200) return false;

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
      return respuestaFinal.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> obtenerEventosAprobados() async {
    try {
      final respuesta = await http.get(
        Uri.parse("$baseUrl/api/eventos/aprobados"),
      );
      if (respuesta.statusCode == 200) return jsonDecode(respuesta.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> obtenerEventosPendientesAdmin() async {
    try {
      final respuesta = await http.get(
        Uri.parse("$baseUrl/api/admin/pendientes"),
      );
      if (respuesta.statusCode == 200) return jsonDecode(respuesta.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> aprobarEvento(int idEvento) async {
    try {
      final respuesta = await http.post(
        Uri.parse("$baseUrl/api/admin/aprobar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": idEvento}),
      );
      return respuesta.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

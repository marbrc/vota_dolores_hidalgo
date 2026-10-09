import '../models/votacion.dart';
import '../models/opcion_votacion.dart';
import '../models/resultado_opcion.dart';
import 'resultado_voto.dart';

class ServicioVotacion {
  final Votacion votacion;
  ServicioVotacion(this.votacion);

  ResultadoVoto registrarVoto({required String idUsuario, required String idOpcion}) {

    // PARA HACE FALLAR LA PRUEBA 7: Comentar este 'if'
    // Explicacion: dejaría registrar votos antes de que empiece la fecha oficial de la votación
    if (votacion.fechaInicio != null && DateTime.now().isBefore(votacion.fechaInicio!)) {
      return ResultadoVoto.votacionExpirada;
    }

    // PARA HACER FALLAR LA PRUEBA 5: Comentar este 'if'
    // Explicación breve: Permitiría votar aunque la fecha límite ya haya pasado
    final yaCerro = DateTime.now().isAfter(votacion.fechaCierre);
    if (yaCerro) return ResultadoVoto.votacionExpirada;

    // PARA HACER FALLAR LAS PRUEBAS 3 Y 6: comentar estos dos renglones
    // Dejaría de checar si el usuario ya votó, dejando que la misma persona vote muchas veces
    final yaVoto = votacion.votantes.contains(idUsuario);
    if (yaVoto) return ResultadoVoto.usuarioYaVoto;

    final opcion = _buscarOpcion(idOpcion);
    
    // PARA HACER FALLAR LA PRUEBA 2: Comentar este 'if'
    // explicacion: no revisaria si la opción existe y fallaría feo si alguien envía una opción inventada
    if (opcion == null) return ResultadoVoto.opcionInvalida;

    //PARA HACER FALLAR LA PRUEBA 1: Comentar este incremento
    // explicacion: Olvidaria sumar el voto (+1) a la opción elegida y se quedaria en 0
    opcion.votos++;
    
    votacion.votantes.add(idUsuario);
    return ResultadoVoto.exitoso;
  }

  OpcionVotacion? _buscarOpcion(String id) {
    for (final o in votacion.opciones) {
      if (o.id == id) return o;
    }
    return null;
  }

  List<ResultadoOpcion> obtenerResultados() {
    final total = votacion.opciones.fold<int>(0, (suma, o) => suma + o.votos);
    return votacion.opciones.map((o) {
      // PARA LA PRUEBA 4: Cambiar la formula por `final porcentaje = 0.0;`
      // explic: no calcularia los porcentajes reales de cada opción y daría 0% a todas
      final porcentaje = total == 0 ? 0.0 : (o.votos / total) * 100;
      return ResultadoOpcion(o, porcentaje);
    }).toList();
  }

  List<OpcionVotacion> determinarGanador() {
    final maxVotos = votacion.opciones.map((o) => o.votos).reduce((a, b) => a > b ? a : b);
    // PARA HACER FALLAR LA PRUEBA 8: VAMOOSA Cambiar el return por `return [];`
    //expñicacion: No devolveria ninguna opción ganadora como si nadie hubiera ganado
    return votacion.opciones.where((o) => o.votos == maxVotos).toList();
  }
}
import 'package:flutter_test/flutter_test.dart';
import 'package:vota_dolores_hidalgo/models/opcion_votacion.dart';
import 'package:vota_dolores_hidalgo/models/votacion.dart';
import 'package:vota_dolores_hidalgo/logic/resultado_voto.dart';
import 'package:vota_dolores_hidalgo/logic/servicio_votacion.dart';

void main() {
  group('Prueba de Integración - Flujo Completo de Votación', () {
    test('permite registrar multiples votos, calcula porcentajes y determina al ganador correctamente', () {
      // 1. Configurar una votación con fechas válidas
      final votacion = Votacion(
        pregunta: 'Pregunta de integración',
        opciones: [
          OpcionVotacion(id: 'op1', texto: 'Opcion 1'),
          OpcionVotacion(id: 'op2', texto: 'Opcion 2'),
        ],
        fechaInicio: DateTime.now().subtract(const Duration(days: 1)), // Ya inició
        fechaCierre: DateTime.now().add(const Duration(days: 5)),    // Cierra en 5 días
      );

      final servicio = ServicioVotacion(votacion);

      // 2. Simular votaciones de diferentes usuarios
      expect(servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op1'), ResultadoVoto.exitoso);
      expect(servicio.registrarVoto(idUsuario: 'user2', idOpcion: 'op1'), ResultadoVoto.exitoso);
      expect(servicio.registrarVoto(idUsuario: 'user3', idOpcion: 'op2'), ResultadoVoto.exitoso);

      // 3. Probar restricciones (usuario duplicado no puede volver a votar)
      expect(servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op2'), ResultadoVoto.usuarioYaVoto);

      // 4. Verificar el cálculo de resultados y porcentajes (Total: 3 votos -> 2 en op1, 1 en op2)
      final resultados = servicio.obtenerResultados();
      final resOp1 = resultados.firstWhere((r) => r.opcion.id == 'op1');
      final resOp2 = resultados.firstWhere((r) => r.opcion.id == 'op2');

      expect(resOp1.porcentaje, closeTo(66.66, 0.1));
      expect(resOp2.porcentaje, closeTo(33.33, 0.1));

      // 5. Verificar que el ganador sea op1
      final ganadores = servicio.determinarGanador();
      expect(ganadores.length, 1);
      expect(ganadores.first.id, 'op1');
    });
  });
}
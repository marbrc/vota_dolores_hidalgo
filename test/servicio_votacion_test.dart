import 'package:flutter_test/flutter_test.dart';
import 'package:vota_dolores_hidalgo/models/opcion_votacion.dart';
import 'package:vota_dolores_hidalgo/models/votacion.dart';
import 'package:vota_dolores_hidalgo/logic/resultado_voto.dart';
import 'package:vota_dolores_hidalgo/logic/servicio_votacion.dart';

Votacion _crearVotacionDePrueba({DateTime? fechaCierre}) {
  return Votacion(
    pregunta: 'Pregunta de prueba',
    opciones: [
      OpcionVotacion(id: 'op1', texto: 'Opcion 1'),
      OpcionVotacion(id: 'op2', texto: 'Opcion 2'),
    ],
    fechaCierre: fechaCierre ?? DateTime.now().add(const Duration(days: 7)),
  );
}

void main() {
  // PRUEBA 1: Comprobar que al votar se sume el voto correctamente.
  test('registrar un voto valido incrementa el contador de esa opcion', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    final resultado = servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op1');
    
    expect(resultado, ResultadoVoto.exitoso);
    expect(votacion.opciones[0].votos, 1); 
  });

  // PRUEBA 2: Comprobar que se rechacen opciones que no existen.
  test('votar por una opcion que no existe regresa opcionInvalida', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    final resultado = servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'no-existe');
    
    expect(resultado, ResultadoVoto.opcionInvalida);
  });

  // PRUEBA 3: Comprobar que un usuario no vote dos veces.
  test('un mismo usuario no puede votar dos veces', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);
    
    servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op1');
    final segundoIntento = servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op2');
    
    expect(segundoIntento, ResultadoVoto.usuarioYaVoto);
    expect(votacion.opciones[1].votos, 0);
  });

  // PRUEBA 4: Comprobar que los porcentajes se calculen bien.
  test('calcula el porcentaje de cada opcion correctamente', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);
    
    servicio.registrarVoto(idUsuario: 'u1', idOpcion: 'op1');
    servicio.registrarVoto(idUsuario: 'u2', idOpcion: 'op1');
    servicio.registrarVoto(idUsuario: 'u3', idOpcion: 'op1');
    servicio.registrarVoto(idUsuario: 'u4', idOpcion: 'op2');
    
    final resultados = servicio.obtenerResultados();
    final op1 = resultados.firstWhere((r) => r.opcion.id == 'op1');
    final op2 = resultados.firstWhere((r) => r.opcion.id == 'op2');
    
    expect(op1.porcentaje, 75.0);
    expect(op2.porcentaje, 25.0);
  });

  test('si no hay ningun voto, todos los porcentajes son 0', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);
    
    final resultados = servicio.obtenerResultados();
    
    expect(resultados.every((r) => r.porcentaje == 0), true);
  });

  // PRUEBA 5: Comprobar que no deje votar si la votación ya cerró.
  test('no se puede registrar un voto si la votacion ya expiro', () {
    final votacionExpirada = _crearVotacionDePrueba(
      fechaCierre: DateTime.now().subtract(const Duration(days: 1)),
    );
    final servicio = ServicioVotacion(votacionExpirada);

    final resultado = servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op1');

    expect(resultado, ResultadoVoto.votacionExpirada);
  });

  // PRUEBA 6: Comprobar que un usuario no pueda cambiar su voto original.
  test('un usuario no puede cambiar su voto una vez registrado', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op1');
    final segundoIntento = servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op2');

    expect(segundoIntento, ResultadoVoto.usuarioYaVoto);
    expect(votacion.opciones[0].votos, 1);
    expect(votacion.opciones[1].votos, 0);
  });

  // PRUEBA 7: Comprobar que no deje votar si la votación no ha iniciado.
  test('no se puede registrar un voto si la votacion aun no ha iniciado', () {
    final votacionFutura = Votacion(
      pregunta: 'Pregunta futura',
      opciones: [
        OpcionVotacion(id: 'op1', texto: 'Opcion 1'),
      ],
      fechaInicio: DateTime.now().add(const Duration(days: 1)),
      fechaCierre: DateTime.now().add(const Duration(days: 7)),
    );
    final servicio = ServicioVotacion(votacionFutura);

    final resultado = servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op1');

    expect(resultado, ResultadoVoto.votacionExpirada);
  });

  // PRUEBA 8: Comprobar que devuelva correctamente a la opción con más votos.
  test('determinarGanador regresa la opcion con mas votos', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op1');
    servicio.registrarVoto(idUsuario: 'user2', idOpcion: 'op1');
    servicio.registrarVoto(idUsuario: 'user3', idOpcion: 'op2');

    final ganadores = servicio.determinarGanador();

    expect(ganadores.length, 1);
    expect(ganadores.first.id, 'op1');
  });
}
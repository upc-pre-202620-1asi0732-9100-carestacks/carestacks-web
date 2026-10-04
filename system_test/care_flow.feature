# language: es
# Especificación de aceptación. Los casos se ejecutan con Flutter Test en
# care_flow_test.dart por ID; este archivo no tiene un parser Cucumber.
Característica: Flujo de cuidado y control del consentimiento de TB1
  Los datos y cuentas de cada escenario son sintéticos y usan una API local con H2.

  @SYS-01
  Escenario: Compartir el perfil, confirmar un evento y registrar una nota
    Dado un paciente y un cuidador registrados en la API
    Y el paciente comparte Agenda, Diario y Documentos con el cuidador
    Cuando el cuidador crea y confirma un evento desde su repositorio Flutter
    Y registra una nota en el diario
    Entonces las consultas posteriores devuelven el evento confirmado y la nota
    Cuando el paciente revoca el consentimiento
    Entonces la consulta de consentimiento devuelve 404

  @SYS-02
  Escenario: Rechazar credenciales incorrectas
    Dado un cuidador registrado
    Cuando inicia sesión con una contraseña incorrecta
    Entonces la API responde 401

  @SYS-03
  Escenario: Mostrar una cuenta sin paciente vinculado
    Dado un cuidador nuevo sin consentimiento
    Cuando carga su dashboard
    Entonces no hay pacientes ni paciente activo

  @SYS-04
  Escenario: Eliminar de la vista el perfil revocado
    Dado un cuidador con un paciente autorizado y guardado en caché
    Cuando el paciente revoca el consentimiento
    Y el cuidador vuelve a cargar su dashboard
    Entonces no reaparece el paciente desde la caché

  @SYS-05
  Escenario: No descargar vistas que no fueron concedidas
    Dado un paciente con una nota privada y consentimiento solo para Agenda
    Cuando el cuidador carga su dashboard
    Entonces el diario del paciente no se descarga

  @SYS-06
  Escenario: Bloquear el acceso directo después de revocar
    Dado un cuidador cuyo consentimiento fue revocado
    Cuando solicita directamente la agenda del paciente con su token
    Entonces la API responde 401 o 403

  @SYS-07
  Escenario: Bloquear la agenda sin sesión
    Dado un paciente con un evento registrado
    Cuando se solicita su agenda sin un token
    Entonces la API responde 401 o 403

  @SYS-08
  Escenario: Iniciar sesión y confirmar desde la interfaz
    Dado un cuidador, un consentimiento y un evento preparados mediante la API
    Cuando introduce sus credenciales en el formulario de inicio de sesión
    Y abre Agenda y pulsa Confirmar
    Entonces se muestra el mensaje Evento confirmado
    Y la consulta posterior a la API devuelve CONFIRMED

  @SYS-09
  Escenario: Registrarse desde la interfaz
    Dado el formulario de creación de cuenta de cuidador
    Cuando introduce nombre, correo y contraseña válidos
    Y pulsa Crear cuenta
    Entonces queda autenticado como cuidador
    Y se muestra el estado sin pacientes activos

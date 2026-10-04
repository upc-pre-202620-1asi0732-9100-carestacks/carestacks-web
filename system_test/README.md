# Pruebas de sistema TB1

Esta suite usa el código real de la aplicación y solicitudes HTTP reales contra
una API local desechable. Solo el almacenamiento de preferencias es simulado y
aislado entre casos. No se permiten hosts de producción.

`care_flow.feature` especifica los escenarios en Gherkin y sus IDs corresponden a
los casos ejecutables de `care_flow_test.dart`. El runner es Flutter Test; el
archivo `.feature` es una especificación, no un archivo ejecutado por Cucumber.

## Ejecución

1. Iniciar el backend del curso con Java 25, H2 temporal y puerto 18080:

```powershell
mvn -B spring-boot:run "-Dspring-boot.run.arguments=--server.port=18080 --spring.datasource.url=jdbc:h2:mem:tb1system;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1 --spring.datasource.driver-class-name=org.h2.Driver --spring.datasource.username=sa --spring.datasource.password= --spring.jpa.hibernate.ddl-auto=create-drop"
```

2. Desde este repositorio:

```powershell
flutter pub get
flutter test --reporter expanded
flutter test system_test/care_flow_test.dart --reporter expanded --dart-define=API_BASE_URL=http://127.0.0.1:18080
flutter analyze
```

Para capturas, agregar `--dart-define=TB1_EVIDENCE_DIR=<directorio-absoluto>`.
Para texto e iconos legibles, agregar `--dart-define=TB1_TEST_FONT=<archivo-ttf>`
y `--dart-define=TB1_ICON_FONT=<MaterialIcons-Regular.otf>`. La fuente de prueba
sustituye también Inter en el harness; no valida la tipografía de producción.
Para ancho móvil, agregar `--dart-define=TB1_VIEWPORT_WIDTH=390`; el ancho por
defecto es 1440. Las capturas son renders de widgets Flutter: no acreditan una
ejecución en Chrome, Android o iOS.

Los escenarios externos están fuera de `test/` para que las pruebas rápidas de
CI no dependan de un servidor activo. Deben ejecutarse explícitamente para
aceptación; que la suite rápida pase no aprueba la suite de sistema.

## Interpretación

Las aserciones de SYS-06 y SYS-07 exigen 401/403. Si la API devuelve 200,
la suite termina con código 1 y el flujo no debe declararse aprobado. No cambiar
las expectativas a 200 ni omitir esos casos para obtener una ejecución exitosa.

SYS-08 prepara las cuentas, el consentimiento y el evento mediante HTTP antes
de interactuar con el login y la agenda. SYS-09 sí registra una cuenta desde
el formulario. La concesión y revocación desde una interfaz de paciente y la
distribución nativa requieren pruebas adicionales en sus respectivos clientes.

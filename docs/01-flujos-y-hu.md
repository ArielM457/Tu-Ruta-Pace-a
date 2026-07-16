# Ayni Ruta — Flujos de usuario e Historias de Usuario (HU)

> Proyecto para la Hackatón "Soluciones para mi Ciudad" — GAMLP
> Reto: Movilidad autónoma y colaborativa — combinar teleférico, PumaKatari y transporte público/privado en una sola recomendación de viaje inteligente.

## Cómo leer este documento

El proyecto se divide en **8 flujos de usuario**. Cada flujo agrupa las Historias de Usuario (HU) que lo componen, de forma que un flujo completo = una experiencia de principio a fin que un usuario vive dentro de la app.

Cada HU tiene una **prioridad** pensada en el demo del 21 de julio:

| Etiqueta | Significado |
|---|---|
| 🟢 MVP | Se construye funcional de verdad para el demo |
| 🟡 DEMO | Se muestra con datos/escenarios preparados de antemano (simulado pero visible en el pitch) |
| ⚪ FUTURO | Queda documentado como visión, no se construye para la hackatón |

Nomenclatura: `HU-<flujo>.<número>` (ej. `HU-2.3` = tercera historia del Flujo 2).

## Actores del sistema

| Actor | Descripción |
|---|---|
| **Ciudadano** | Usuario general que quiere moverse por La Paz |
| **Colaborador Ayni** | Ciudadano que comparte su ubicación durante un viaje y gana puntos |
| **Persona con discapacidad visual** | Usa la app mediante el asistente de voz |
| **Persona con movilidad reducida** | Necesita rutas y transportes accesibles |
| **Usuario en emergencia** | Necesita llegar a un centro de salud cuanto antes |
| **Personal de gobierno** | Consulta la congestión de la ciudad a partir de reportes |
| **Sistema** | Procesos automáticos (verificación de reportes, cálculo de rutas, etc.) |

---

## Flujo 0 — Onboarding, autenticación y perfil

**Objetivo:** el usuario entra a la app, crea su cuenta y configura sus preferencias. Es la puerta de entrada a todos los demás flujos.

**Recorrido:** abrir app → pantallas de bienvenida → registro/login (Supabase Auth) → configurar preferencias (accesibilidad, prioridad costo/tiempo/seguridad) → pantalla principal (mapa).

### Historias de Usuario

**HU-0.1 — Registro de cuenta** 🟢 MVP
> Como ciudadano, quiero registrarme con mi correo y contraseña, para tener una cuenta que guarde mis puntos Ayni y preferencias.
- Criterios de aceptación:
  - El registro se hace contra Supabase Auth.
  - Se validan formato de correo y contraseña mínima de 8 caracteres.
  - Al registrarse se crea automáticamente su perfil con 0 puntos Ayni.

**HU-0.2 — Inicio de sesión** 🟢 MVP
> Como ciudadano registrado, quiero iniciar sesión, para acceder a mi cuenta desde cualquier dispositivo.
- Criterios de aceptación:
  - Login con correo/contraseña vía Supabase Auth.
  - La sesión persiste al cerrar y abrir la app (refresh token).
  - Error claro cuando las credenciales son incorrectas.

**HU-0.3 — Onboarding de preferencias** 🟡 DEMO
> Como usuario nuevo, quiero indicar si tengo alguna necesidad de accesibilidad y qué priorizo al viajar (tiempo, costo o seguridad), para que las recomendaciones se adapten a mí desde el primer uso.
- Criterios de aceptación:
  - Selección de perfil de accesibilidad: ninguno / discapacidad visual / movilidad reducida.
  - Selección de prioridad por defecto: más rápido / más barato / más seguro.
  - Las preferencias se guardan en el perfil y son editables después.

**HU-0.4 — Ver y editar perfil** 🟢 MVP
> Como ciudadano, quiero ver mi perfil con mis puntos Ayni y editar mis datos y preferencias, para mantener mi cuenta al día.
- Criterios de aceptación:
  - Muestra nombre, correo, saldo de puntos Ayni y preferencias.
  - Permite editar nombre, preferencias de viaje y accesibilidad.

**HU-0.5 — Uso sin cuenta (invitado)** ⚪ FUTURO
> Como persona que no quiere registrarse, quiero pedir rutas sin crear cuenta, para usar lo básico de la app sin fricción.
- Criterios de aceptación:
  - Puede pedir rutas pero no acumula ni gasta puntos Ayni.
  - Se le invita a registrarse al intentar usar funciones colaborativas.

---

## Flujo 1 — Planificación de viaje multimodal (flujo núcleo)

**Objetivo:** el usuario pide cómo llegar a un destino y recibe la mejor combinación de teleférico, PumaKatari, transporte público (minibús, micro, trufi), taxi/radiotaxi y caminata. **Este es el corazón del producto y del demo.**

**Recorrido:** pantalla principal con mapa → buscar destino → el sistema calcula opciones multimodales → lista de recomendaciones ordenables (tiempo/costo/seguridad) → ver detalle de una opción (tramos, transbordos, tiempos, costos) → iniciar viaje.

### Historias de Usuario

**HU-1.1 — Buscar destino** 🟢 MVP
> Como ciudadano, quiero buscar mi destino escribiendo una dirección o lugar conocido, o tocando el mapa, para pedir una ruta hacia él.
- Criterios de aceptación:
  - Búsqueda con autocompletado (Google Places) limitada al área de La Paz/El Alto.
  - Alternativa: seleccionar punto directamente en el mapa.
  - El origen por defecto es la ubicación GPS actual, editable.

**HU-1.2 — Recibir recomendación multimodal** 🟢 MVP
> Como ciudadano, quiero recibir la mejor combinación de transportes hacia mi destino (uno solo o varios combinados), para llegar de la forma más conveniente.
- Criterios de aceptación:
  - El motor devuelve 2–4 opciones de viaje, cada una compuesta por tramos (caminar, teleférico, PumaKatari, minibús/micro/trufi, taxi).
  - Cada opción muestra: tiempo total estimado, distancia, costo estimado y transportes usados.
  - Usa datos reales de las 11 líneas de teleférico (horario 05:00–23:00) y datos realistas de PumaKatari y radiotaxis.
  - El cálculo se apoya en Google Directions como base de tiempos y distancias.

**HU-1.3 — Ordenar opciones por prioridad** 🟢 MVP
> Como ciudadano, quiero ordenar las opciones por más rápida, más barata o más segura, para elegir según lo que me importa hoy.
- Criterios de aceptación:
  - Toggle visible: Tiempo / Costo / Seguridad.
  - El orden de la lista cambia sin recalcular la ruta.
  - La prioridad por defecto viene de las preferencias del perfil.

**HU-1.4 — Ver detalle de la ruta** 🟢 MVP
> Como ciudadano, quiero ver el paso a paso de la opción elegida (dónde camino, dónde subo, dónde bajo, dónde transbordo), para saber exactamente qué hacer.
- Criterios de aceptación:
  - Vista de tramos con ícono por tipo de transporte, tiempo y costo de cada tramo.
  - La ruta completa se dibuja en el mapa con un color por tramo.
  - Muestra estaciones/paradas de subida y bajada con nombre.

**HU-1.5 — Rutas que evitan bloqueos y cierres** 🟢 MVP
> Como ciudadano, quiero que la recomendación descarte o penalice tramos afectados por bloqueos, protestas o refacciones activas, para no ser enviado a una vía intransitable.
- Criterios de aceptación:
  - El motor consulta los incidentes activos (Flujo 4) antes de calcular.
  - Los tramos de superficie afectados se descartan o penalizan; el teleférico se prioriza como alternativa que no depende de la vía.
  - La opción indica visualmente cuándo está esquivando un incidente ("evita bloqueo en Av. …").

**HU-1.6 — Opción de solo caminata** 🟡 DEMO
> Como ciudadano, quiero ver también la opción de ir caminando cuando la distancia es razonable, para decidir si necesito transporte.
- Criterios de aceptación:
  - Si el destino está a menos de un umbral (ej. 2 km), aparece la opción caminando con tiempo estimado.

**HU-1.7 — Viajes guardados/frecuentes** ⚪ FUTURO
> Como ciudadano, quiero guardar destinos frecuentes (casa, trabajo), para pedir esas rutas con un toque.

---

## Flujo 2 — Viaje en curso, ubicación colaborativa y puntos Ayni

**Objetivo:** durante el viaje, el usuario recibe guía y colabora compartiendo su ubicación; el sistema convierte esa colaboración en la fuente de datos en tiempo real del transporte, recompensada con puntos Ayni (dar y recibir).

**Recorrido:** iniciar viaje → seguimiento en mapa tramo a tramo → la app invita a compartir ubicación al subir a un transporte → gana puntos al colaborar → otro usuario gasta puntos para preguntar "¿dónde viene mi transporte?" → fin de viaje con resumen.

### Historias de Usuario

**HU-2.1 — Seguimiento del viaje en curso** 🟡 DEMO
> Como ciudadano en viaje, quiero ver mi avance sobre la ruta y qué tramo sigue, para no perderme ni pasarme de parada.
- Criterios de aceptación:
  - El mapa muestra la posición GPS del usuario sobre la ruta activa.
  - Indica el tramo actual y el siguiente paso ("baja en la estación …").
  - Aviso al acercarse al punto de bajada o transbordo.

**HU-2.2 — Compartir ubicación durante el viaje (ganar puntos)** 🟢 MVP
> Como colaborador Ayni, quiero compartir mi ubicación mientras voy dentro de un transporte, para ayudar a otros a saber dónde viene ese transporte y ganar puntos Ayni.
- Criterios de aceptación:
  - Al iniciar un tramo en transporte, la app pregunta si quiere compartir ubicación (opt-in, nunca automático).
  - Mientras comparte, envía posición periódica asociada a la línea/ruta del transporte.
  - Al terminar el tramo se acreditan puntos proporcionales al tiempo compartido.
  - Puede dejar de compartir en cualquier momento.

**HU-2.3 — Consultar dónde viene mi transporte (gastar puntos)** 🟢 MVP
> Como ciudadano esperando, quiero saber a cuántos minutos o a qué distancia está el transporte que espero, para decidir si espero o tomo otra opción.
- Criterios de aceptación:
  - La consulta cuesta puntos Ayni; se descuentan al confirmarla.
  - La posición estimada del transporte se calcula agregando las ubicaciones de los colaboradores dentro de ese transporte (nunca se expone la identidad ni la posición individual de un colaborador).
  - Si no hay colaboradores activos en esa línea, se informa con honestidad y no se cobra.

**HU-2.4 — Ver historial y saldo de puntos Ayni** 🟢 MVP
> Como colaborador Ayni, quiero ver cuántos puntos tengo y cómo los gané o gasté, para entender el sistema de dar y recibir.
- Criterios de aceptación:
  - Saldo visible en el perfil y en la pantalla principal.
  - Historial de movimientos: fecha, motivo (compartió ubicación / consultó transporte), puntos +/-.

**HU-2.5 — Resumen de fin de viaje** ⚪ FUTURO
> Como ciudadano, quiero un resumen al terminar (tiempo real, costo, puntos ganados), para conocer mi aporte y mis gastos.

**HU-2.6 — Compartir experiencia del viaje** ⚪ FUTURO
> Como ciudadano, quiero dejar una nota corta sobre mi viaje (ej. "a esta hora ya no pasan minibuses por aquí"), para alimentar las respuestas del agente IA (Flujo 5).

---

## Flujo 3 — Modo urgencia

**Objetivo:** ante una emergencia de salud, la app cambia a un modo que prioriza llegar cuanto antes al centro de salud más conveniente y deja a mano los números de emergencia de La Paz.

**Recorrido:** botón de urgencia siempre visible → confirmar modo urgencia → la app calcula la ruta más rápida al hospital más cercano/adecuado considerando bloqueos → muestra números de emergencia (911, 165, 160 ambulancias, Red 114 GAMLP) con llamada directa → guía hasta llegar.

### Historias de Usuario

**HU-3.1 — Activar modo urgencia** 🟡 DEMO
> Como usuario en emergencia, quiero activar un modo urgencia con un toque, para que la app deje todo y me ayude a llegar a un hospital ya.
- Criterios de aceptación:
  - Botón visible desde la pantalla principal, con confirmación para evitar activaciones accidentales.
  - La UI cambia a un modo simplificado de alto contraste con información mínima.

**HU-3.2 — Ruta más rápida a un centro de salud** 🟡 DEMO
> Como usuario en emergencia, quiero que el sistema me lleve al hospital al que pueda llegar más rápido ahora mismo (considerando bloqueos y tráfico), para no perder tiempo decidiendo.
- Criterios de aceptación:
  - El sistema elige entre los hospitales cercanos el de menor tiempo real de llegada, no el de menor distancia.
  - Considera bloqueos activos y prioriza teleférico cuando la vía está tomada.
  - Muestra alternativas por si el usuario prefiere otro hospital.

**HU-3.3 — Números de emergencia a mano** 🟢 MVP
> Como usuario en emergencia, quiero ver y llamar con un toque a los números de emergencia de La Paz (911, 165, 160, Red 114 del GAMLP), para pedir ambulancia o reportar el caso mientras me muevo.
- Criterios de aceptación:
  - Lista fija de números oficiales con botón de llamada directa.
  - Visible dentro del modo urgencia sin salir de la navegación.

**HU-3.4 — Hospitales y puntos policiales siempre visibles en ruta** 🟡 DEMO
> Como ciudadano en cualquier viaje, quiero que el mapa marque con un ícono propio los hospitales y centros policiales cercanos a mi ruta, para ubicarlos rápido si los necesito.
- Criterios de aceptación:
  - Capa de íconos diferenciados (salud / policía) sobre el mapa en todo viaje, no solo en urgencia.
  - Tocar un ícono muestra nombre y opción de redirigir la ruta hacia él.

---

## Flujo 4 — Reportes y verificación de vías (bloqueos, cierres, tráfico)

**Objetivo:** mantener viva y confiable la información del estado de las vías, separando tres fuentes según su origen: cierres oficiales (alcaldía), bloqueos/movilizaciones (noticieros + fuentes oficiales + reportes ciudadanos verificados por confirmaciones mínimas) y tráfico normal (Google Maps).

**Recorrido:** usuario ve un bloqueo → lo reporta con ubicación, tipo y foto opcional → otros usuarios cercanos confirman → al superar el umbral de confirmaciones, el incidente se activa y afecta el cálculo de rutas → el incidente expira o se cierra.

### Historias de Usuario

**HU-4.1 — Reportar un bloqueo o movilización** 🟢 MVP
> Como ciudadano, quiero reportar un bloqueo, protesta o refacción que estoy viendo, con su ubicación y una foto opcional, para avisar a los demás y mejorar las rutas de todos.
- Criterios de aceptación:
  - Formulario mínimo: tipo (bloqueo / movilización / refacción), ubicación (mapa, por defecto la actual), descripción corta, foto opcional (Supabase Storage).
  - El reporte nace en estado "pendiente de verificación".
  - Un usuario no puede reportar el mismo incidente dos veces.

**HU-4.2 — Confirmar reportes de otros** 🟢 MVP
> Como ciudadano cerca de un incidente reportado, quiero confirmar si es real, para que el sistema lo valide y evitar reportes falsos.
- Criterios de aceptación:
  - Los reportes pendientes cercanos se muestran con opción "confirmar" / "ya no está".
  - Al superar el umbral mínimo de confirmaciones (configurable, ej. 3), el incidente pasa a "activo" y entra al cálculo de rutas.
  - Con suficientes "ya no está", el incidente se cierra.

**HU-4.3 — Cierres oficiales de vías** 🟡 DEMO
> Como sistema, quiero registrar cierres de vía únicamente desde reportes oficiales de la alcaldía, para que esa capa tenga garantía institucional.
- Criterios de aceptación:
  - Los cierres oficiales entran por un canal separado (carga administrativa / futura API GAMLP), nunca por reporte ciudadano.
  - Se marcan visualmente como "cierre oficial" en el mapa.
  - Para el demo se cargan cierres de ejemplo desde datos preparados.

**HU-4.4 — Ver el mapa de incidentes activos** 🟢 MVP
> Como ciudadano, quiero ver en el mapa los bloqueos, movilizaciones, refacciones y cierres activos, para entender el estado de la ciudad antes de salir.
- Criterios de aceptación:
  - Capa de incidentes con ícono por tipo y color por origen (oficial / verificado ciudadano).
  - Tocar un incidente muestra detalle: tipo, desde cuándo, confirmaciones, foto si tiene.

**HU-4.5 — Tráfico en tiempo real** 🟢 MVP
> Como ciudadano, quiero ver el tráfico normal de la ciudad, para dimensionar mi viaje.
- Criterios de aceptación:
  - Se usa la capa de tráfico de Google Maps tal cual (no se reinventa).

**HU-4.6 — Ingesta desde noticieros y fuentes oficiales** ⚪ FUTURO
> Como sistema, quiero incorporar bloqueos publicados por noticieros y cuentas oficiales, para no depender solo del reporte ciudadano.

---

## Flujo 5 — Accesibilidad y agente de IA

**Objetivo:** el agente IA cumple tres roles: asistente de voz para personas no videntes, recomendador de rutas accesibles para personas con movilidad reducida, y cerebro que llena huecos de información con las experiencias compartidas por la comunidad.

**Recorrido (no vidente):** activa modo voz → pide destino hablando → el agente responde con la recomendación hablada → guía paso a paso por voz durante el viaje → puede pedir ayuda en cualquier momento.

### Historias de Usuario

**HU-5.1 — Pedir ruta por voz** 🟡 DEMO
> Como persona con discapacidad visual, quiero pedir mi destino hablando y escuchar la recomendación, para usar la app sin depender de la pantalla.
- Criterios de aceptación:
  - Entrada por voz (speech-to-text) y respuesta hablada (text-to-speech) en español.
  - El agente confirma el destino entendido antes de calcular.
  - Compatible con el lector de pantalla del sistema (TalkBack/VoiceOver).

**HU-5.2 — Guía por voz durante el viaje** 🟡 DEMO
> Como persona con discapacidad visual, quiero indicaciones habladas paso a paso (qué transporte tomar, cuándo bajar, cómo pedir ayuda), para viajar con autonomía.
- Criterios de aceptación:
  - Anuncios de voz en cada cambio de tramo y al acercarse a la bajada.
  - Comando para repetir la última indicación.
  - Acceso por voz a los números de emergencia.

**HU-5.3 — Rutas accesibles para movilidad reducida** 🟡 DEMO
> Como persona con movilidad reducida, quiero que la recomendación priorice transportes y estaciones con mejores condiciones de acceso, para armar una ruta que pueda hacer.
- Criterios de aceptación:
  - Con el perfil de movilidad reducida activo, el motor pondera accesibilidad (teleférico y PumaKatari con rampa por encima de minibuses).
  - Minimiza tramos de caminata y evita pendientes fuertes cuando hay alternativa.
  - Indica en el detalle por qué esa opción es más accesible.

**HU-5.4 — Respuestas ante huecos de información** 🟡 DEMO
> Como ciudadano en una situación sin datos (ej. no pasa ningún minibús a esta hora), quiero preguntarle al agente qué hago, para recibir una alternativa basada en experiencias de otros usuarios.
- Criterios de aceptación:
  - Chat con el agente disponible desde la pantalla de viaje.
  - El agente responde usando las experiencias compartidas por la comunidad en situaciones parecidas (misma zona/horario) y ofrece alternativas concretas: otro transporte, caminar, bicicleta o taxi.
  - Deja claro cuando su respuesta es estimación comunitaria y no dato oficial.

**HU-5.5 — Aprendizaje continuo del agente** ⚪ FUTURO
> Como sistema, quiero que las experiencias nuevas alimenten al agente, para que sus respuestas mejoren con el uso.

---

## Flujo 6 — Capa de costos

**Objetivo:** que el precio del viaje sea un ciudadano de primera clase en la recomendación: opciones ordenadas de la más barata a la más cara y combinaciones que optimizan costo o seguridad según lo que el usuario elija.

### Historias de Usuario

**HU-6.1 — Costo estimado por opción y por tramo** 🟢 MVP
> Como ciudadano, quiero ver cuánto me costará cada opción de viaje y cada tramo (Bs), para decidir según mi bolsillo.
- Criterios de aceptación:
  - Tarifario base por transporte (teleférico por línea, PumaKatari, minibús/micro/trufi promedio, taxi por distancia/zona).
  - El costo total de la opción es la suma de sus tramos y se muestra en la lista y en el detalle.

**HU-6.2 — Ordenar de más barata a más cara** 🟢 MVP
> Como ciudadano, quiero ordenar las opciones por precio, para encontrar la forma más económica de llegar.
- Criterios de aceptación:
  - Es el modo "Costo" del toggle de HU-1.3.

**HU-6.3 — Combinaciones costo/seguridad** 🟡 DEMO
> Como ciudadano, quiero combinaciones que mezclen tramos priorizando costo o seguridad (ej. caminar hasta el teleférico y de ahí un radiotaxi seguro), para elegir el equilibrio que me sirva.
- Criterios de aceptación:
  - Con prioridad "seguridad", en horarios/zonas de riesgo se reemplazan tramos a pie por taxi/radiotaxi.
  - Con prioridad "costo", se maximizan tramos baratos aunque tarde más, mostrando la diferencia de tiempo.

---

## Flujo 7 — Seguridad ciudadana (zonas de riesgo)

**Objetivo:** avisar en ciertos horarios sobre zonas con mayor riesgo por robos u otros hechos recientes, y ajustar la recomendación (taxi en vez de caminar).

### Historias de Usuario

**HU-7.1 — Aviso de zona de riesgo por horario** 🟡 DEMO
> Como ciudadano, quiero que la app me avise cuando mi ruta cruza una zona con riesgo reciente en el horario actual, para decidir informado.
- Criterios de aceptación:
  - Base de zonas de riesgo con franjas horarias (datos preparados para el demo).
  - Si la ruta activa cruza una zona en su franja de riesgo, aparece un aviso no bloqueante.

**HU-7.2 — Recomendación de taxi en zona de riesgo** 🟡 DEMO
> Como ciudadano, quiero que en zonas de riesgo la app me recomiende tomar taxi o radiotaxi en vez de caminar, para reducir mi exposición.
- Criterios de aceptación:
  - En zona/horario de riesgo, los tramos a pie se reemplazan o acompañan con la alternativa en taxi y su costo.
  - Conecta con la capa de costos (HU-6.3).

**HU-7.3 — Alimentar zonas de riesgo con datos reales** ⚪ FUTURO
> Como sistema, quiero construir las zonas de riesgo desde reportes ciudadanos y datos policiales, para que la capa sea verídica y dinámica.

---

## Flujo 8 — Vista de gobierno (monitoreo de congestión)

**Objetivo:** que el personal de gobierno entienda la congestión de la ciudad a partir de los reportes de la gente y de la policía. Para la hackatón se muestra como una vista dentro de la misma app con rol especial.

### Historias de Usuario

**HU-8.1 — Rol de personal de gobierno** 🟡 DEMO
> Como personal de gobierno, quiero entrar con un rol especial, para acceder a la vista de monitoreo.
- Criterios de aceptación:
  - Rol `gobierno` asignado en la base de datos (para el demo, cuentas pre-creadas).
  - El rol habilita la vista de monitoreo, invisible para ciudadanos.

**HU-8.2 — Mapa de congestión y reportes agregados** 🟡 DEMO
> Como personal de gobierno, quiero ver un mapa con los incidentes activos, su origen (ciudadano verificado / oficial) y las zonas con más reportes, para dimensionar el estado de la ciudad.
- Criterios de aceptación:
  - Mapa de calor o agrupación de incidentes por zona.
  - Filtros por tipo de incidente y rango de tiempo.

**HU-8.3 — Gestión de cierres oficiales** ⚪ FUTURO
> Como personal de gobierno, quiero registrar y cerrar cierres oficiales de vía desde la app, para mantener la capa oficial sin depender de cargas manuales.

---

## Resumen de prioridades para el demo (21 de julio)

### 🟢 MVP funcional (se construye de verdad)
| HU | Qué es |
|---|---|
| HU-0.1, 0.2, 0.4 | Registro, login y perfil (Supabase Auth) |
| HU-1.1 → 1.5 | Flujo completo de pedir ruta y recibir recomendación multimodal evitando bloqueos |
| HU-2.2, 2.3, 2.4 | Compartir ubicación, consultar transporte, saldo/historial de puntos Ayni |
| HU-3.3 | Números de emergencia con llamada directa |
| HU-4.1, 4.2, 4.4, 4.5 | Reportar incidentes, confirmarlos, mapa de incidentes, tráfico Google |
| HU-6.1, 6.2 | Costos por tramo/opción y orden por precio |

### 🟡 Demo con escenarios preparados
Onboarding de preferencias, seguimiento de viaje, modo urgencia completo, íconos de hospitales/policía, cierres oficiales, todo el flujo de accesibilidad/agente IA, combinaciones costo/seguridad, zonas de riesgo y vista de gobierno.

### ⚪ Futuro (visión post-hackatón)
Modo invitado, viajes frecuentes, resumen de viaje, experiencias compartidas, ingesta de noticieros, aprendizaje del agente, zonas de riesgo con datos reales, gestión de cierres desde la app.

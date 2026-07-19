# 07 — Plan de implementación del rediseño Chasqui en mobile

> **Objetivo:** llevar la app Flutter (`mobile/`) al diseño final del uxui (`uxui/src/app/App.tsx`)
> **tal cual se ve, pero con funcionalidad real**, según la brecha y decisiones de `docs/06-brecha-uxui-vs-mobile.md`.
>
> **Cómo usar este documento:** las tareas están dimensionadas para hacerse **de a una**, revisando
> el resultado antes de pasar a la siguiente. Al completar una tarea se marca su checkbox y se
> verifica con la app corriendo (nunca con tests — ver skill `escribir-codigo`).
> Tamaños: **S** = tarea corta, **M** = una sesión de trabajo. No hay tareas L a propósito:
> si una crece, se divide.

## Reglas transversales (aplican a todas las tareas)

1. **Fuente de verdad visual:** `uxui/src/app/App.tsx`. Cada pantalla debe quedar visualmente
   igual al componente correspondiente (paleta, tipografía, radios, jerarquía). Tokens y specs en
   la skill `rediseno-chasqui`.
2. **Naming oficial:** app **Chasqui**, asistente **Chaski**, puntos **Puntos Chass** (skill
   `naming-chasqui`). Cualquier texto visible con nombres viejos que se toque, se corrige.
3. **Nada de funcionalidad se pierde:** lo que existe en mobile y el uxui no dibuja
   (voz en el chat, chips de prioridad, opt-in de compartir, preguntar a la comunidad,
   confirmación de incidentes, accesibilidad, cerrar sesión) **se conserva** integrado al nuevo diseño.
4. **Arquitectura:** se respetan las skills `frontend-flutter` (clean por módulos, Riverpod,
   go_router, repositorios) y `backend-nestjs` para las tareas de API.
5. **Verificación:** cada tarea termina con la app corriendo y el flujo ejercitado de punta a punta
   (y consola del backend cuando aplique).

---

## Fase 0 — Preparación

### [x] T0.1 · Renombrado visible global (S)
- **Qué:** reemplazar en todo texto **visible** del mobile: "Ayni Ruta"/"Tu Ruta Paceña" → **Chasqui**;
  asistente → **Chaski**; "puntos Ayni" → **Puntos Chass**. Incluye título del AppBar, nombre de la
  app en Android (`android:label`) e iOS, textos de pantallas y snackbars. También actualizar los
  nombres en `docs/` y `.claude/skills/` donde aparezcan como nombre del producto.
- **No incluye:** renombrar identificadores internos (`AyniBadge`, `ayniPoints`, endpoint
  `/collaboration/ayni`), package ids ni carpetas.
- **Verificar:** grep de "Ayni"/"paceña" sobre strings visibles queda limpio; la app instalada muestra "Chasqui".

### [x] T0.2 · Quitar panel de gobierno del mobile (S)
- **Qué:** eliminar la ruta `/government`, el ícono condicional del AppBar en el mapa y el módulo
  `mobile/lib/modules/government/` completo. El backend `/government/*` y su documentación **no se tocan**
  (será una app aparte para la gobernación).
- **Verificar:** compila sin referencias colgantes; un usuario con rol `government` ya no ve el acceso.

---

## Fase 1 — Base visual y navegación

### [x] T1.1 · Tema Chasqui (M)
- **Qué:** rehacer `mobile/lib/app/theme.dart` con el design system del uxui: `ColorScheme` desde
  amarillo `#ffd516` (CTA) y naranja `#f15e1f` (alertas/SOS), neutros, tipografía **Nunito Sans**
  (google_fonts), cards blancas radio 16 con borde `#efefef` y sombra suave, botones CTA amarillos
  con texto casi negro y peso black, chips/tags de estado (fondo suave + bold 11px), inputs con fondo
  `#fafafa` y borde `#dcdcdc`, labels de sección en mayúsculas 11px gris con tracking.
- **Además:** crear en `core/widgets/` los equivalentes compartidos de `Card`, `Tag` y `TopBar` del uxui
  para reutilizarlos en todas las fases.
- **Verificar:** la app entera cambia de aspecto sin romper ninguna pantalla existente.

### [x] T1.2 · Shell de navegación: tab bar píldora + botón Chaski (M)
- **Qué:** crear un `StatefulShellRoute` con la **tab bar píldora flotante** del uxui
  (Inicio, Rutas, SOS, Denuncias, Perfil — SOS activo en naranja, resto en amarillo) y el
  **botón central Chaski** sobresaliente que abre el chat. Franja superior con el wordmark "CHASQUI".
  Pantallas placeholder mínimas para los tabs que aún no existen (Home dashboard, Rutas planificador,
  Denuncias). Definir qué rutas viven **fuera** del shell (subpantallas con TopBar + atrás y sin tab bar:
  mapa, detalle de ruta, comunidad, familia, notificaciones, onboarding, auth).
- **Verificar:** navegación entre los 5 tabs + Chaski funciona; las subpantallas ocultan la píldora.

---

## Fase 2 — Home y mapa

### [x] T2.1 · El mapa pasa a pantalla propia (M)
- **Qué:** mover el contenido de `home_map_screen.dart` a una ruta `/map` (subpantalla con TopBar),
  conservando **todo**: tráfico, marcadores de incidentes activos/pendientes por bbox, detalle con
  confirmación (3 votos), FAB de reportar incidente, chip "compartiendo", toque largo para fijar
  destino y panel de prioridad. Quitar el `SosFab` (SOS ya es tab).
- **Verificar:** reportar y confirmar un incidente desde `/map` funciona igual que antes.

### [x] T2.2 · Home dashboard (M)
- **Qué:** construir el Home del uxui (`HomeScreen` de App.tsx): saludo según hora + nombre real del
  perfil + avatar con iniciales; campana con badge (aún sin pantalla, se conecta en T9.1); buscador
  "¿A dónde vas?" que navega a Rutas; **banner de mapa** con contadores reales (incidentes activos de
  `GET /incidents/active`, viaje en curso si existe) que abre `/map`; **tarjeta de alerta activa** con
  el incidente más cercano/relevante; grid de 4 **acciones rápidas** (Planificar → Rutas,
  Denunciar → Denuncias, Comunidad, Familia).
- **Verificar:** con un incidente activo sembrado, el banner y la tarjeta lo muestran; las 4 acciones navegan.

### [x] T2.3 · Viajes recientes en el Home (S)
- **Qué:** conectar `GET /trips` (historial — **ya existe en backend**, `trip-history.controller.ts`):
  método en `trips_repository` + provider + lista en el Home con formato del uxui
  (origen → destino, "Hoy/Ayer HH:MM", costo Bs). Tocar un viaje precarga ese destino en Rutas.
- **Verificar:** tras iniciar/finalizar un viaje, aparece en el Home.

### [x] T2.4 · Restilizar chat Chaski (S)
- **Qué:** llevar `chat_screen.dart` al diseño del uxui (`ChatbotScreen`): header con avatar Chaski y
  estado "En línea", burbujas (usuario amarilla con esquina recta, bot gris con borde), chips de FAQ
  con los textos del uxui. **Se mantienen** el micrófono, la ruta por voz y la respuesta hablada.
- **Verificar:** enviar texto, FAQ y voz siguen funcionando con el nuevo aspecto.

---

## Fase 3 — Rutas (planificador)

### [x] T3.1 · Backend: autocompletar de lugares (M)
- **Qué:** endpoint `GET /routing/places/autocomplete?q=...` (proxy a Google Places, sesgado a La Paz,
  con session token) que devuelve `{ description, placeId, lat, lng }[]`. La app móvil **no** llama a
  Google directo (regla de arquitectura).
- **Verificar:** por consola, "umsa" devuelve resultados en La Paz con coordenadas.

### [x] T3.2 · Pantalla Rutas con búsqueda por texto (M)
- **Qué:** construir la pantalla Rutas del uxui (`RoutesScreen`): card con inputs de texto
  Origen/Destino con autocomplete (T3.1), botón de intercambio, origen = "Mi ubicación" (GPS) por
  defecto, chips de prioridad (tiempo/costo/seguridad — se mantienen), botón "Buscar rutas",
  aviso de bloqueo activo ("rutas ajustadas") cuando la recomendación consideró incidentes.
  **Alternativa conservada:** fijar destino con toque en el mapa (`/map`) sigue llevando a las opciones.
- **Verificar:** buscar por texto y por mapa producen opciones de ruta.

### [x] T3.3 · Opciones de ruta estilo uxui (M)
- **Qué:** en la lista de opciones: **tags comparativos** calculados localmente ("Más rápido" a la de
  menor tiempo, "Más barato" a la de menor costo, "Combinado"/"Recomendado" al resto), **conteo de
  transbordos** (tramos no-caminata − 1, mínimo 0), **nombre compuesto** de la opción
  ("Trufi 12 + Teleférico Rojo"), y el card del uxui (ícono, tag, tiempo bold, costo amarillo,
  transbordos).
- **Verificar:** con 3 opciones, los tags se asignan bien y los transbordos coinciden con los tramos.

### [x] T3.4 · Detalle de ruta + viaje en curso (M)
- **Qué:** detalle según uxui (`RouteDetail`): card resumen (tag, transbordos, tiempo grande, costo
  grande), timeline "Paso a paso" con conector vertical, min y **Bs/"Gratis"** por tramo (costo 0 →
  "Gratis" en verde), botón "Iniciar navegación". Al iniciarla: se registra el trip y el opt-in de
  compartir (**ya existen**), y en vez de volver al Home se abre la **vista de viaje en curso** sobre
  `/map`: ruta pintada por tramos, chip compartiendo, panel con próximo paso y botón "Finalizar viaje"
  (`PATCH /trips/:id/finish`, ya conectado). "Preguntar a la comunidad" por tramo **se conserva**.
- **Verificar:** flujo completo buscar → detalle → iniciar → ver ruta en el mapa → finalizar; el viaje
  aparece luego en "Viajes recientes".

---

## Fase 4 — Denuncias

### [x] T4.1 · Backend: revisar contrato de complaints (S)
- **Qué:** contrastar `CreateComplaintDto` y la tabla contra el formulario del uxui: tipo (enum de 6:
  Conductor agresivo, Cobro excesivo, Ruta no respetada, Vehículo en mal estado, Acoso, Otro),
  placa o nombre del conductor, ruta/línea, descripción, **foto opcional** (Supabase Storage, como
  incidentes) y estados **En revisión / Resuelto / Cerrado** (el estado lo cambia la futura app de
  gobernación; por defecto "En revisión"). Ampliar DTO/tabla/servicio si falta algo.
- **Verificar:** por consola, `POST /complaints` con todos los campos y `GET /complaints/mine` los devuelve.

### [x] T4.2 · Módulo Flutter de denuncias (M)
- **Qué:** crear `mobile/lib/modules/complaints/` completo (domain/data/presentation) consumiendo el
  backend **ya existente**. Tres vistas según uxui (`DenunciasScreen`): lista "Mis denuncias"
  (tipo, línea, fecha, tag de estado) con botón "+ Nueva"; formulario (grid de tipos, placa, línea,
  descripción, foto opcional); pantalla de éxito ("te notificaremos en menos de 24 horas").
  Accesos: tab Denuncias, acción rápida del Home y entrada "Mis denuncias" del Perfil (esta última
  se cablea en T7.3).
- **Verificar:** crear una denuncia con foto desde la app y verla en la lista con estado "En revisión".

---

## Fase 5 — SOS

### [x] T5.1 · Backend: policía y filtro por tipo (S)
- **Qué:** seeds de **puestos policiales** de La Paz (nombre, coordenadas, teléfono) junto a los
  hospitales; parámetro `kind` (`hospital` | `police`) en `GET /emergency/facilities/near`; asegurar
  que las facilities incluyan **teléfono**. Alinear la lista de `GET /emergency/contacts` con la del
  uxui (Policía 110, Bomberos 119, SAMU 165, Defensa Civil, etc.).
- **Verificar:** por consola, `facilities/near?kind=police` devuelve puestos con teléfono.

### [x] T5.2 · Pantalla SOS del uxui (M)
- **Qué:** rehacer la pantalla de emergencias como el uxui (`EmergenciasScreen`), ahora como tab:
  **botón SOS circular** toggle (inactivo blanco / activo naranja con halo) — reemplaza el diálogo de
  confirmación actual; al activar, aparecen las 3 categorías que **filtran** los cercanos:
  **Rescate** → hospitales, **Retención** → policía, **Accidente** → ambos (decisión #6; sin backend
  de despacho — el disclaimer "esta app no despacha ambulancias" se mantiene). Tabs **"Cercanos"**
  (nombre, distancia, botón teléfono con url_launcher) y **"Números de ayuda"** (botón "Llamar").
  Al elegir un hospital cercano se muestra la **ruta más rápida** (reutiliza `POST /emergency/route`
  y el mapa con polilínea ya existentes).
- **Verificar:** activar SOS, filtrar por categoría, llamar (intent de marcado) y ver ruta al hospital.

---

## Fase 6 — Comunidad

### [x] T6.1 · Backend: ranking y feed (M)
- **Qué:** dos endpoints nuevos en `community`:
  `GET /community/ranking?period=week` (suma de movimientos de puntos por usuario en la semana,
  top N + posición y badge del solicitante; badges por umbral: Héroe/Activo/Colaborador/Miembro/Nuevo)
  y `GET /community/feed` (últimos eventos de la comunidad: reportes, verificaciones, respuestas, con
  nombre corto del usuario, acción, hace cuánto y puntos ganados).
- **Verificar:** por consola con datos sembrados, ranking ordenado y feed con eventos recientes.

### [x] T6.2 · Pantalla Comunidad del uxui (M)
- **Qué:** rehacer `community_screen.dart` según `ComunidadScreen`: card de mis **Puntos Chass** con
  posición en el ranking; card "Cómo funciona" (valores reales de la config, ver T6.3); **ranking
  semanal** resaltando al usuario actual; **feed de actividad**; botón "Canjear puntos para pedir
  ayuda" que lleva a los flujos **existentes** (preguntar a la comunidad / dónde viene mi transporte
  — decisión #8). Las secciones actuales (preguntas pendientes, mis preguntas) se conservan
  reubicadas; el historial de movimientos migra al Perfil (T7.3).
- **Verificar:** ranking y feed muestran datos reales; el canje abre el flujo de pregunta.

### [x] T6.3 · Alinear economía de puntos (S)
- **Qué:** ajustar la configuración del backend a los valores del uxui: **+15** reportar bloqueo,
  **+10** verificar reporte, **+5** responder pregunta, **−50** pedir ayuda; y que la card
  "Cómo funciona" los lea de la API (o constante compartida) en vez de hardcodearlos.
- **Verificar:** reportar/confirmar/responder otorgan los valores nuevos en el historial.

---

## Fase 7 — Perfil

### [x] T7.1 · Rutas favoritas (M)
- **Qué:** **backend**: tabla `favorites` (usuario, nombre, lat/lng o par origen-destino) + endpoints
  `GET/POST/DELETE /users/me/favorites`. **Mobile:** gestión en Perfil → Preferencias y accesos
  rápidos en el planificador de Rutas (elegir un favorito rellena el destino). Botón "guardar como
  favorita" en el detalle de ruta o al finalizar viaje.
- **Verificar:** guardar un favorito y usarlo para planificar en dos toques.

### [x] T7.2 · Historial de ayuda (S)
- **Qué:** **backend**: agregado "personas ayudadas" (respuestas dadas + confirmaciones de reportes
  del usuario), expuesto en `GET /users/me` o endpoint propio. **Mobile:** entrada en Perfil
  ("Has ayudado a N personas") con desglose simple.
- **Verificar:** responder una pregunta incrementa el contador.

### [x] T7.3 · Perfil completo del uxui (M)
- **Qué:** rehacer `profile_screen.dart` según `PerfilScreen`: header con avatar, nombre, email y tags
  (**Puntos Chass** + badge de nivel, mismo cálculo que el ranking); sección **Mi cuenta**
  (Información personal —agregar teléfono opcional en `users`—, Preferencias —modo de viaje,
  accesibilidad y favoritas—, **Puntos y recompensas** —el historial de movimientos ya existente,
  `GET /collaboration/ayni`—); sección **Familia y comunidad** (Cuenta familiar → T8, Mis denuncias
  → T4, Historial de ayuda → T7.2); sección **Configuración** con toggles persistidos en el perfil
  (**Alertas de ruta** —controla la campana T9— y **Compartir ubicación con familia** —controla T8—).
  Cerrar sesión se mantiene.
- **Verificar:** cada entrada navega y los toggles persisten tras reiniciar la app.

---

## Fase 8 — Familia (backend parcial, decisión #9)

### [x] T8.1 · Backend: grupos familiares (M)
- **Qué:** tablas `family_groups` y `family_members` + endpoints: crear grupo, **invitar por email o
  código**, aceptar invitación, listar miembros con **estado derivado real**: "En ruta" si el miembro
  tiene un viaje activo (con línea/tramo actual), "última vez" desde su último ping de ubicación;
  solo visible si el miembro tiene activado "Compartir ubicación con familia" (T7.3).
- **Verificar:** por consola, dos usuarios se vinculan y uno ve el estado del otro en viaje.

### [x] T8.2 · Pantalla Familia del uxui (M)
- **Qué:** según `FamiliaScreen`: header del grupo (nombre, "N miembros · M activos"), lista de
  miembros con tag de estado (En ruta / En casa / Desconectada) y ubicación o "última vez",
  botón "Agregar familiar" (flujo de invitación de T8.1), card "Apoyo familiar" para enviar Puntos
  Chass a un miembro (**simulado para la demo**: UI completa con confirmación, sin transferencia real
  salvo que sobre tiempo). Acceso desde acción rápida del Home y Perfil.
- **Verificar:** vincular un familiar real y ver su estado; el envío de puntos muestra su flujo.

---

## Fase 9 — Notificaciones

### [x] T9.1 · Campana funcional básica (M)
- **Qué:** pantalla de notificaciones (subpantalla desde la campana del Home) que **agrega en el
  cliente** tres fuentes ya existentes: bloqueos activos cercanos (`GET /incidents/active`),
  respuestas nuevas a mis preguntas (`GET /community/questions/mine`) y cambios de estado de mis
  denuncias (`GET /complaints/mine`). Badge de la campana = ítems no vistos (persistencia local de
  "visto", p. ej. shared_preferences). Respeta el toggle "Alertas de ruta" (T7.3). Sin push del
  sistema (decisión #11).
- **Verificar:** con un bloqueo activo y una respuesta nueva, la campana marca 2 y la lista los muestra.

---

## Fase 10 — Auth y cierre

### [x] T10.1 · Restilizar auth y onboarding (M)
- **Qué:** llevar bienvenida, login, registro y onboarding de preferencias al tema Chasqui
  (logo/wordmark, CTAs amarillos, inputs del design system). Sin cambios de lógica (Supabase Auth).
- **Verificar:** registro + login + onboarding completos con el nuevo aspecto.

### [x] T10.2 · Barrido final de consistencia (S)
- **Qué:** revisión pantalla por pantalla contra el uxui: naming (grep de nombres viejos), tokens de
  estilo, textos en español con "Bs", accesibilidad (Semantics en botones e íconos), y verificación
  end-to-end de los flujos de la demo del 21 de julio.
- **Verificar:** recorrido completo de la demo sin inconsistencias visuales ni de naming.

---

## Dependencias entre tareas

- **T1.1 y T1.2 van primero** — todo lo demás se construye sobre el tema y el shell.
- T2.2 (Home) necesita T2.1 (mapa como subpantalla). T2.3 es independiente después de T2.2.
- T3.2 necesita T3.1 (autocomplete). T3.3 y T3.4 pueden ir en cualquier orden después de T3.2.
- T4.2 necesita T4.1. T5.2 necesita T5.1. T6.2 necesita T6.1.
- T7.3 referencia T4 (denuncias), T7.1, T7.2 y T8 (puede cablearse con placeholders si aún no están).
- T8.2 necesita T8.1 y el toggle de T7.3. T9.1 necesita T4.2 (denuncias) para su tercera fuente.
- Las fases 4, 5 y 6 son independientes entre sí (paralelizables entre personas).

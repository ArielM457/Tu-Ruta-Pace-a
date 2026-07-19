# 06 — Análisis de brecha: diseño uxui (Chasqui) vs app mobile actual

> **Fuente de verdad del diseño:** `uxui/src/app/App.tsx` (prototipo React exportado de Figma).
> **Fecha del análisis:** 18 de julio de 2026. Demo/pitch: 21 de julio de 2026.
>
> Este documento compara el diseño final de la app (**Chasqui**) con lo que existe hoy en `mobile/`
> (Flutter) y en `backend/` (NestJS), y define **qué ya está, qué falta implementar y qué hay que
> modificar** para que el mobile cumpla con el uxui.

---

## 1. Decisiones de producto confirmadas

Estas decisiones se aclararon directamente con el equipo y **mandan sobre cualquier documento previo**:

| # | Tema | Decisión |
|---|------|----------|
| 1 | **Naming** | La app se llama **Chasqui** en todos lados. La mascota/asistente se llama **Chaski**. Los puntos pasan de "puntos Ayni" a **"Puntos Chass"**. Hay que renombrar toda referencia visible a "Ayni Ruta" / "puntos Ayni". |
| 2 | **Flujo general** | Se respeta el flujo del uxui **tal cual**: Home dashboard + tab bar inferior. Lo que ya funciona en mobile se adapta a ese flujo, no al revés. |
| 3 | **Denuncias vs incidentes** | Son **dos cosas separadas**. "Denuncias" = quejas contra el servicio/conductores (nueva pantalla, tab propio). Los **incidentes viales** (bloqueos, movilizaciones) se siguen reportando **desde el mapa** como hoy. |
| 4 | **Mapa completo** | El banner de mapa del Home **abre el mapa completo** (marcadores de incidentes, reporte y confirmación de bloqueos). El mapa también se muestra **cuando se confirma/inicia una ruta** (vista de viaje). |
| 5 | **Búsqueda de rutas** | Inputs de **texto** para origen/destino (como el uxui) + posibilidad de **fijar el destino tocando el mapa**. Los **chips de prioridad (tiempo/costo/seguridad) se mantienen** aunque el uxui no los muestre. |
| 6 | **SOS** | La activación del SOS habilita las 3 categorías, y **cada categoría filtra la ayuda cercana**: Rescate → hospitales, Retención → policía, Accidente → ambos. |
| 7 | **Comunidad** | El **ranking semanal** y el **feed de actividad** se implementan con **backend real** (nuevos endpoints), no con datos demo. |
| 8 | **Canjear puntos** | "Canjear puntos para pedir ayuda" (−50 pts) **es lo que ya existe**: preguntar a la comunidad / consultar dónde viene mi transporte. El botón lleva a esas funciones (alineando los costos de puntos). |
| 9 | **Familia** | Se implementa con **backend parcial**: real lo esencial (**vincular familiares y ver su estado**); el resto (ubicación en vivo continua, etc.) simulado para la demo. |
| 10 | **Perfil** | "Rutas favoritas", "Puntos y recompensas" e "Historial de ayuda" deben ser **funcionales con datos reales**. |
| 11 | **Notificaciones** | La campana del Home es **funcional básica**: abre una lista de alertas reales (bloqueos activos cercanos, respuestas a mis preguntas, estado de denuncias). Sin push del sistema. |
| 12 | **Vista gobierno** | **Se quita del mobile** (será una app especializada para la gobernación). El módulo backend y la documentación **se mantienen**. |

---

## 2. Qué contiene el uxui (inventario del diseño final)

El prototipo define **8 pantallas** y una estructura de navegación nueva:

### 2.1 Navegación global
- **Tab bar inferior tipo píldora flotante** con 5 tabs: **Inicio, Rutas, SOS, Denuncias, Perfil**.
- **Botón central "Chaski"** (chatbot) que sobresale de la píldora, siempre visible.
- El tab SOS activo se pinta **naranja** (`#f15e1f`); los demás, **amarillo marca** (`#ffd516`).
- **Wordmark "Chasqui"** en una franja amarilla arriba de toda la app.
- Comunidad y Familia **no están en el tab bar**: se accede desde las acciones rápidas del Home y desde Perfil.
- Las subpantallas (p. ej. Familia) ocultan el tab bar y usan `TopBar` con botón atrás.

### 2.2 Sistema visual (aplica a toda la app)
- Tipografía **Nunito Sans** (pesos hasta black).
- Paleta: primario amarillo `#ffd516` (CTA), secundario naranja `#f15e1f` (alertas/SOS), terciario cálido `#e39438`, neutros grises, verde `#38a169`/`#276749` para éxito/gratis.
- Cards blancas con radio 16 px, borde `#efefef`, sombra suave.
- Botones CTA amarillos con texto casi negro, radio 16 px, font-weight black.
- Tags/chips de estado con fondo suave y texto en bold de 11 px.
- Etiquetas de sección en mayúsculas, 11 px, tracking amplio, gris.

### 2.3 Pantallas del uxui

| Pantalla | Contenido del diseño |
|---|---|
| **Home** | Saludo con nombre + avatar con iniciales, campana con badge, buscador "¿A dónde vas?" (lleva a Rutas), banner de mapa con estado ("3 rutas activas", "1 alerta"), tarjeta de alerta activa (bloqueo + desvío recomendado), 4 acciones rápidas (Planificar, Denunciar, Comunidad, Familia), lista de viajes recientes (origen → destino, hora, costo en Bs). |
| **Rutas** | Card con inputs de texto Origen/Destino + botón de intercambio, botón "Buscar rutas", aviso de bloqueo activo ("rutas ajustadas"), lista de opciones de ruta (nombre, tag "Más rápido"/"Combinado"/"Más barato", tiempo, costo, transbordos). **Detalle de ruta:** resumen (tiempo/costo/transbordos), timeline "paso a paso" por tramo (ícono, instrucción, min, Bs o "Gratis"), botón "Iniciar navegación". |
| **Chatbot (Chaski)** | Header "Asistente Chasqui · En línea", chips de preguntas frecuentes (tarifas teleférico, rutas a El Alto, Puma Katari gratis, cómo reportar bloqueo), burbujas usuario/bot, input + botón enviar. |
| **Emergencias (SOS)** | Botón SOS circular grande (toggle activo/inactivo con animación), texto de estado ("Compartiendo ubicación con servicios de emergencia"), al activar: 3 categorías **Rescate / Retención / Accidente**, tabs **"Cercanos"** (hospitales y puestos policiales con distancia y botón de teléfono) y **"Números de ayuda"** (Policía 110, Bomberos 119, SAMU 165, Defensa Civil, etc. con botón "Llamar"). |
| **Denuncias** | Lista "Mis denuncias" (tipo, ruta/línea, fecha, estado: En revisión / Resuelto / Cerrado), botón "+ Nueva". **Formulario:** tipo de incidente (Conductor agresivo, Cobro excesivo, Ruta no respetada, Vehículo en mal estado, Acoso, Otro), placa o nombre del conductor, ruta/línea, descripción, foto opcional. **Pantalla de éxito:** "Denuncia enviada… te notificaremos en menos de 24 horas". |
| **Comunidad** | Card de mis puntos (avatar, posición en ranking, total de puntos), card "Cómo funciona" (+15 reportar bloqueo, +10 verificar reportes, +5 responder preguntas, −50 canjear para pedir ayuda), **ranking semanal** (top usuarios con badge Héroe/Activo/Colaborador/Miembro/Nuevo, resaltando al usuario actual), **feed "Actividad reciente"** (usuario + acción + hace cuánto + puntos ganados), botón "Canjear puntos para pedir ayuda". |
| **Familia** | Header de la familia (foto, nombre, "3 miembros · 1 activo"), lista de miembros con estado (En ruta / En casa / Desconectada) y ubicación/último visto, botón "Agregar familiar", card "Apoyo familiar" para **enviar puntos a un familiar**. |
| **Perfil** | Avatar + nombre + email + tags (puntos, nivel), sección **Mi cuenta** (Información personal, Preferencias —rutas favoritas y modo de viaje—, Puntos y recompensas), sección **Familia y comunidad** (Cuenta familiar, Mis denuncias, Historial de ayuda), sección **Configuración** con toggles (Alertas de ruta, Compartir ubicación con familia). |

### 2.4 Lo que el uxui NO muestra pero se mantiene (funcionalidad existente que no se pierde)

- **Autenticación** (bienvenida, login, registro) y **onboarding de preferencias** (accesibilidad + prioridad): el uxui no las incluye; se conservan las pantallas actuales **restilizadas al design system Chasqui**.
- **Chips de prioridad** tiempo/costo/seguridad en la búsqueda de rutas (decisión #5).
- **Micrófono / voz en el chat** (dictado de destino, respuesta hablada): pilar de accesibilidad del flujo 5; se mantiene aunque el uxui no dibuje el botón de mic.
- **Opt-in de compartir ubicación al iniciar viaje** (ganar Puntos Chass) y chip de "compartiendo".
- **"Preguntar a la comunidad"** desde un tramo del detalle de ruta y **popup de preguntas pendientes**.
- **Confirmación de incidentes** (umbral de 3 confirmaciones) desde el detalle del incidente en el mapa.
- **Preferencia de accesibilidad** en el perfil (el uxui no la muestra explícitamente; entra en "Preferencias").

---

## 3. Estado por funcionalidad

Leyenda: ✅ **Ya está** (existe y cumple) · 🔧 **Modificar/adaptar** (existe pero hay que cambiarla para cumplir el uxui) · ❌ **Falta implementar** (no existe en mobile) · 🔌 **Falta conectar** (el backend ya lo tiene, el mobile no lo consume).

### 3.1 Navegación y estructura

| Funcionalidad | Estado | Detalle |
|---|---|---|
| Tab bar inferior píldora (Inicio/Rutas/SOS/Denuncias/Perfil) | ❌ | Hoy no hay bottom navigation: todo cuelga del AppBar del mapa (`home_map_screen.dart`). Hay que crear un `ShellRoute`/scaffold con la píldora flotante y el botón central Chaski. |
| Botón central Chaski (chatbot siempre accesible) | 🔧 | El chat existe (`chat_screen.dart`) pero se abre desde un ícono del AppBar. Pasa a ser el botón central del tab bar. |
| Wordmark "Chasqui" (franja amarilla superior) | ❌ | No existe. |
| Subpantallas con TopBar + atrás, ocultando tab bar | 🔧 | El patrón de navegación existe con go_router; hay que definir qué rutas viven dentro del shell y cuáles fuera. |
| Renombrar app y textos (Chasqui / Chaski / Puntos Chass) | 🔧 | Hoy la app dice "Ayni Ruta", "Mi Comunidad Ayni", "puntos Ayni", `AyniBadge`, etc. Renombrar todo texto visible (y nombre de la app en Android/iOS). Los identificadores internos de código pueden quedarse. |
| Design system Chasqui (Nunito Sans, paleta amarilla, cards r16, CTAs black) | 🔧 | `app/theme.dart` actual usa Material con índigo. Hay que rehacer el `ThemeData` completo: `colorScheme` desde `#ffd516`/`#f15e1f`, tipografía Nunito Sans (google_fonts), formas, botones, chips y tags según §2.2. **Afecta a todas las pantallas.** |

### 3.2 Home (dashboard)

| Funcionalidad | Estado | Detalle |
|---|---|---|
| Home tipo dashboard | ❌ | El home actual es el mapa completo. Hay que crear la pantalla dashboard nueva; el mapa se mueve a su propia pantalla (ver §3.4). |
| Saludo con nombre real + avatar con iniciales | 🔧 | El nombre existe en el perfil (`displayName`); solo hay que mostrarlo con el saludo según hora del día. |
| Buscador "¿A dónde vas?" que lleva a Rutas | ❌ | Nuevo (navega al planificador). |
| Banner de mapa con estado (rutas activas / alertas) | ❌ | Nuevo. Al tocarlo abre el **mapa completo** (decisión #4). Los contadores salen de `GET /incidents/active` (alertas) y del estado del viaje en curso. |
| Tarjeta de alerta activa (bloqueo + desvío) | 🔌 | Los incidentes activos ya llegan por `GET /incidents/active` (el mapa los pinta); falta la tarjeta resumen en el Home con el incidente más relevante/cercano. |
| Acciones rápidas (Planificar, Denunciar, Comunidad, Familia) | ❌ | Nuevo (grid de 4 accesos). |
| Viajes recientes (origen → destino, hora, costo) | 🔌 | **El backend ya tiene historial** (`GET /trips` en `trip-history.controller.ts`) pero el mobile solo usa `POST /trips` y `PATCH /trips/:id/finish`. Falta repositorio/provider de historial y la lista en el Home. Al tocar un viaje reciente, precarga ese destino en Rutas. |

### 3.3 Rutas (planificador)

| Funcionalidad | Estado | Detalle |
|---|---|---|
| Inputs de texto origen/destino con autocompletar | ❌ | Hoy el destino se fija **solo** con toque largo en el mapa. Falta búsqueda por texto (Google Places autocomplete vía backend, según regla de arquitectura) con origen = GPS por defecto. |
| Botón de intercambiar origen/destino | ❌ | Nuevo. |
| Fijar destino tocando el mapa (alternativa) | ✅ | Ya existe (`onLongPress` en el mapa). Se mantiene como método alternativo (decisión #5). |
| Chips de prioridad (tiempo/costo/seguridad) | ✅ | Ya existen en `home_map_screen.dart` y `route_options_screen.dart`. Se mantienen (decisión #5); mover al layout del planificador. |
| Aviso de bloqueo activo ("rutas ajustadas") | 🔧 | El dato ya viene (`activeIncidentsConsidered` en la respuesta de recomendaciones); hoy se muestra como texto plano. Convertirlo en la tarjeta de aviso del uxui. |
| Lista de opciones con tag (Más rápido / Combinado / Más barato), tiempo, costo, transbordos | 🔧 | `route_option_card.dart` ya muestra opciones ordenables. Falta: calcular/mostrar los **tags comparativos**, el conteo de **transbordos**, y el nombre compuesto de la opción ("Trufi + Teleférico Rojo"). Restilizar al card del uxui. |
| Detalle: resumen tiempo/costo/transbordos | 🔧 | Existe (`route_detail_screen.dart`); agregar transbordos y el tag; restilizar. |
| Detalle: timeline paso a paso con costo por tramo y "Gratis" | 🔧 | El timeline por tramo ya existe (`_LegTile` con ícono, instrucción, min, Bs). Falta el caso "Gratis" (costo 0, p. ej. Puma Katari) y el estilo de timeline del uxui. |
| "Iniciar navegación" → vista de viaje sobre el mapa | 🔧 | Hoy "Iniciar viaje" registra el trip, ofrece compartir ubicación y vuelve al home. Según decisión #4, al confirmar la ruta debe abrirse el **mapa con la ruta activa** (vista de viaje en curso: polilíneas por tramo ya existen en `_RouteMap`). |
| Opt-in Puntos Chass al iniciar viaje | ✅ | Ya existe (`ShareOptInSheet` + `activeShareProvider`). Solo restilizar y renombrar textos. |
| "Preguntar a la comunidad" por tramo | ✅ | Ya existe (`AskQuestionSheet` desde `_LegTile`). Mantener aunque el uxui no lo dibuje. |

### 3.4 Mapa completo (se abre desde el banner del Home)

| Funcionalidad | Estado | Detalle |
|---|---|---|
| Mapa con tráfico + marcadores de incidentes activos y pendientes | ✅ | Es el home actual (`home_map_screen.dart`): tráfico, `GET /incidents/active` por bbox, pendientes cercanos, colores por tipo. Se convierte en pantalla propia accesible desde el banner. |
| Detalle de incidente + confirmar (3 confirmaciones) | ✅ | Ya existe (`incident_detail_sheet.dart`, votos). Restilizar. |
| Reportar incidente vial (tipo, descripción, foto, ubicación) | ✅ | Ya existe (`report_bottom_sheet.dart` con cámara y optimistic update). Se mantiene **en el mapa** (decisión #3). Restilizar. |
| Vista de viaje en curso (ruta activa sobre el mapa) | 🔧 | Las polilíneas por tramo existen en el detalle; falta el estado "viaje en curso" tras iniciar (decisión #4): ruta pintada, chip de compartiendo, acción de finalizar viaje (`PATCH /trips/:id/finish` ya existe y está conectado). |

### 3.5 Chatbot Chaski

| Funcionalidad | Estado | Detalle |
|---|---|---|
| Chat con el asistente (backend Azure AI Foundry) | ✅ | Ya existe (`chat_screen.dart` → `POST /assistant/chat`). |
| Chips de preguntas frecuentes | ✅ | Ya existen (`faq_chips.dart`); alinear los textos a los del uxui (tarifas, El Alto, Puma Katari, reportar bloqueo). |
| Header "En línea" + burbujas estilo uxui | 🔧 | Existe header y burbujas; restilizar (avatar Chaski, burbuja amarilla usuario / gris bot, indicador "En línea"). |
| Entrada de voz + ruta por voz + respuesta hablada | ✅ | Ya existe (`mic_button.dart`, `voice-route`). Se mantiene aunque el uxui no lo muestre (accesibilidad). |
| Renombrar asistente a "Chaski" | 🔧 | Textos y persona del bot. |

### 3.6 Emergencias (SOS)

| Funcionalidad | Estado | Detalle |
|---|---|---|
| Tab SOS en la navegación (en vez de FAB) | 🔧 | Hoy es un FAB rojo en el mapa con diálogo de confirmación. Pasa a ser tab del tab bar. El diálogo de confirmación puede reemplazarse por el toggle del botón grande. |
| Botón SOS circular toggle (activar/desactivar) | ❌ | Nuevo comportamiento: activar muestra las categorías y el estado. |
| Categorías Rescate / Retención / Accidente que filtran ayuda | ❌ | Decisión #6: Rescate → hospitales, Retención → policía, Accidente → ambos. **Backend:** `GET /emergency/facilities/near` existe; hay que verificar/añadir el tipo `police` (seeds de puestos policiales) y el filtro por tipo. |
| Tab "Cercanos" (hospitales + policía con distancia y teléfono) | 🔧 | Hoy la pantalla muestra hospital recomendado + alternativas con ruta. Hay que reorganizar al layout de tabs del uxui, agregando policía y botón de llamada por instalación (los teléfonos deben venir en los datos de facilities). |
| Ruta más rápida al hospital (mapa + polilínea) | ✅ | Ya existe (`POST /emergency/route`, `hospital_card.dart`, mapa con tráfico). Integrarla dentro del nuevo layout (p. ej. al elegir un "cercano"). |
| Tab "Números de ayuda" con botón Llamar | ✅ | Ya existe (`GET /emergency/contacts` + fallback hardcodeado + `emergency_contact_card.dart`). Alinear la lista de números a la del uxui (110, 119, 165, Defensa Civil, etc.) en los seeds del backend. Restilizar. |
| "Compartiendo ubicación con servicios de emergencia" | 🔧 | Según decisión #6 la activación **solo habilita las opciones** (no hay despacho real); el texto de estado se muestra pero sin backend nuevo. Mantener el disclaimer actual ("esta app no despacha ambulancias"). |

### 3.7 Denuncias (quejas de servicio) — pantalla nueva

| Funcionalidad | Estado | Detalle |
|---|---|---|
| Lista "Mis denuncias" con estados | 🔌 | **El backend ya existe**: `GET /complaints/mine`. El mobile **no tiene ningún módulo de complaints** — hay que crear módulo completo (data/domain/presentation). |
| Formulario de nueva denuncia (tipo, placa, línea, descripción, foto) | 🔌 | `POST /complaints` ya existe. Verificar que `CreateComplaintDto` cubra los campos del uxui (tipo de los 6 valores, placa/nombre, ruta/línea, descripción, foto); ampliar DTO/tabla si falta alguno (p. ej. foto vía Supabase Storage como en incidentes). |
| Pantalla de éxito ("te notificaremos en menos de 24 horas") | ❌ | Nueva (solo UI). |
| Estados En revisión / Resuelto / Cerrado | 🔧 | Verificar que el backend maneje esos estados; quien los cambia es la app de la gobernación (fuera de alcance del mobile ciudadano). |
| Acceso desde Home (acción rápida) y Perfil ("Mis denuncias") | ❌ | Nuevas entradas de navegación. |

### 3.8 Comunidad

| Funcionalidad | Estado | Detalle |
|---|---|---|
| Card de mis puntos + posición en ranking | 🔧 | El balance ya existe (perfil → `ayniPoints`). Falta la **posición en el ranking** (requiere el endpoint de ranking). Renombrar a Puntos Chass. |
| Card "Cómo funciona" con valores de puntos | 🔧 | Nueva UI simple; **alinear los valores mostrados con la configuración real del backend** (+15 reportar, +10 verificar, +5 responder, −50 pedir ayuda) o ajustar la config del backend a estos valores. |
| Ranking semanal con badges (Héroe/Activo/…) | ❌ | **Backend real (decisión #7): nuevo endpoint** (p. ej. `GET /community/ranking?period=week`) agregando movimientos de puntos por usuario; definir umbrales de badges. Mobile: lista nueva resaltando al usuario actual. |
| Feed "Actividad reciente" | ❌ | **Backend real: nuevo endpoint** (p. ej. `GET /community/feed`) con eventos anonimizables (reportes, verificaciones, respuestas) y puntos ganados. Mobile: lista nueva. |
| Botón "Canjear puntos para pedir ayuda" | 🔧 | Decisión #8: lleva a las funciones existentes (preguntar a la comunidad / dónde viene mi transporte). Revisar el costo en puntos para que sea coherente con el −50 del uxui. |
| Preguntas pendientes para responder + mis preguntas + historial de puntos | ✅ | Ya existen (`community_screen.dart`, `pending_questions_screen.dart`, `ayniHistoryProvider`). Reorganizar dentro del nuevo layout de Comunidad (el historial encaja en "Puntos y recompensas" del Perfil, ver §3.10). |

### 3.9 Familia — pantalla y backend nuevos

Decisión #9: **backend parcial** — real lo esencial (vincular y ver estado), el resto simulado para la demo.

| Funcionalidad | Estado | Detalle |
|---|---|---|
| Grupo familiar: crear/vincular miembros | ❌ | **Backend nuevo (real):** tablas de grupo/miembros + endpoints para invitar/aceptar por email o código, listar miembros. |
| Estado de cada miembro (En ruta / En casa / Desconectada + ubicación o último visto) | ❌ | **Real básico:** derivar "En ruta" del viaje activo del miembro (trips) y "última vez" del último ping; la ubicación fina en vivo puede ser simulada/gruesa para la demo. Respetar privacidad: solo con consentimiento (toggle "Compartir ubicación con familia" del Perfil). |
| Enviar Puntos Chass a un familiar ("Apoyar a X") | ❌ | **Simulado para la demo** (o transferencia simple sobre la tabla de movimientos si el tiempo alcanza). |
| Header de familia con foto y conteo de activos | ❌ | UI nueva (foto puede ser estática/avatar). |
| Acceso desde Home (acción rápida) y Perfil ("Cuenta familiar") | ❌ | Nuevas entradas de navegación. |

### 3.10 Perfil

| Funcionalidad | Estado | Detalle |
|---|---|---|
| Header con avatar, nombre, email, tags de puntos y nivel | 🔧 | Nombre/email ya están; agregar tags (Puntos Chass + badge de nivel, mismo cálculo que el ranking). |
| Información personal (nombre, teléfono, email) | 🔧 | Editar nombre ya existe; falta teléfono (campo nuevo en `users` si se quiere real). |
| Preferencias: modo de viaje + accesibilidad | ✅ | Ya existen (prioridad y accesibilidad con bottom sheets). Se agrupan bajo "Preferencias". |
| Preferencias: **rutas favoritas** | ❌ | **Real (decisión #10). Backend nuevo:** guardar destinos/rutas favoritas (`favorites`) + endpoints CRUD. Mobile: gestión en Perfil y acceso rápido al planificar. |
| Puntos y recompensas | 🔌 | **Real:** reutiliza el historial de movimientos que ya existe (`GET /collaboration/ayni`); solo falta la entrada en Perfil con el layout del uxui. |
| Historial de ayuda ("Has ayudado a N personas") | ❌ | **Real (decisión #10). Backend:** contar respuestas aceptadas + confirmaciones de reportes del usuario (nuevo endpoint o campo agregado en `/users/me`). |
| Cuenta familiar (entrada) | ❌ | Ver §3.9. |
| Mis denuncias (entrada) | 🔌 | Ver §3.7. |
| Toggle "Alertas de ruta" | ❌ | Preferencia nueva (activa/desactiva las alertas de la campana; persistir en perfil). |
| Toggle "Compartir ubicación" (con familia) | ❌ | Preferencia nueva ligada a Familia (§3.9). |
| Cerrar sesión | ✅ | Ya existe. El uxui no lo dibuja pero se mantiene. |

### 3.11 Notificaciones (campana del Home)

| Funcionalidad | Estado | Detalle |
|---|---|---|
| Campana con badge + lista de alertas | ❌ | **Funcional básica (decisión #11):** pantalla nueva que agrega, del lado del cliente o con un endpoint ligero: bloqueos activos cercanos (ya hay endpoint), respuestas nuevas a mis preguntas (ya hay `questions/mine`), cambios de estado de mis denuncias (`complaints/mine`). Sin push del sistema. |

### 3.12 Auth y onboarding (fuera del uxui, se mantienen)

| Funcionalidad | Estado | Detalle |
|---|---|---|
| Bienvenida / Login / Registro (Supabase Auth) | 🔧 | Ya funcionan; **restilizar** al design system Chasqui y renombrar. |
| Onboarding de preferencias (accesibilidad + prioridad) | 🔧 | Ya funciona; restilizar. |

### 3.13 Vista gobierno

| Funcionalidad | Estado | Detalle |
|---|---|---|
| Panel de gobierno en el mobile | 🗑️ | **Se elimina del mobile** (decisión #12): quitar ruta `/government`, el ícono condicional del AppBar y el módulo `modules/government/` de la app ciudadana. El **backend se mantiene intacto** (`/government/*`, cierres oficiales) para la futura app especializada de la gobernación, y la documentación no se toca. |

---

## 4. Resumen ejecutivo de la brecha

### Ya está y solo necesita restilizado/renombrado (🔧 ligero)
1. Auth + onboarding de preferencias.
2. Mapa con incidentes: reporte, confirmación, detalle (pasa de "home" a pantalla propia).
3. Motor de rutas: opciones ordenables por prioridad, detalle con timeline y mapa por tramos.
4. Iniciar viaje + opt-in de compartir ubicación (Puntos Chass).
5. Chat Chaski con FAQ, voz y ruta por voz.
6. Urgencia: ruta al hospital + contactos de emergencia.
7. Comunidad: preguntas pendientes, mis preguntas, historial de puntos.
8. Perfil: nombre, accesibilidad, prioridad, cerrar sesión.

### Falta conectar (backend listo, mobile no lo consume — 🔌)
1. **Denuncias**: `POST /complaints` y `GET /complaints/mine` → módulo Flutter completo nuevo.
2. **Viajes recientes**: `GET /trips` (historial) → lista en el Home.
3. **Puntos y recompensas** en Perfil: reutilizar `GET /collaboration/ayni`.

### Falta implementar en mobile Y backend (❌)
1. **Tab bar píldora + botón Chaski + Home dashboard** (solo mobile).
2. **Búsqueda de origen/destino por texto** con autocomplete (backend proxy a Places + UI).
3. **SOS con categorías** que filtran hospitales/policía (seeds de policía + filtro por tipo en facilities + UI nueva).
4. **Ranking semanal** y **feed de actividad** de Comunidad (endpoints nuevos + UI).
5. **Familia**: grupo, vínculos y estados (backend parcial real) + envío de puntos (simulado).
6. **Rutas favoritas** (endpoints CRUD + UI).
7. **Historial de ayuda** (agregado en backend + entrada en Perfil).
8. **Notificaciones básicas** (pantalla que agrega alertas de fuentes ya existentes).
9. **Toggles de configuración** (alertas de ruta, compartir con familia).
10. **Vista de viaje en curso** sobre el mapa tras confirmar la ruta.

### Se elimina del mobile (🗑️)
1. Panel de gobierno (queda en backend y docs; será app aparte).

---

## 5. Orden de trabajo sugerido (hacia el 21 de julio)

1. **Base visual y navegación** (desbloquea todo lo demás): tema Chasqui + tab bar píldora + shell de navegación + renombrado global.
2. **Home dashboard** + mapa como pantalla propia + viajes recientes (`GET /trips`).
3. **Rutas**: inputs de texto con autocomplete + tags comparativos + transbordos + "Gratis" + vista de viaje en curso.
4. **Denuncias** (backend ya listo — alto valor/esfuerzo bajo).
5. **SOS por categorías** (seeds policía + filtro + nueva UI).
6. **Comunidad**: ranking + feed (endpoints nuevos) + canje apuntando a lo existente.
7. **Perfil completo**: favoritas, historial de ayuda, puntos y recompensas, toggles.
8. **Familia** (backend parcial) y **notificaciones básicas**.
9. Quitar panel gobierno del mobile.

> Nota de prioridades: los ítems 1–3 tocan el núcleo 🟢 del MVP; 4–7 son diferenciadores visibles en la demo; 8 puede degradarse a datos preparados si el tiempo no alcanza (la decisión de Familia ya contempla parte simulada).

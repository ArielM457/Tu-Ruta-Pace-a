# Avance del Frontend (Flutter) — Ayni Ruta

> Última actualización: 18 de julio de 2026
> Estado: **Flujos 0, 1, 2, 3, 4, 5 y 8 implementados y conectados al backend real (sin mocks).** Falta Flujo 6/7 de superficie visual adicional y pulido final para la demo.

## Qué está construido

Sobre la base de Flujo 0 (auth, onboarding, perfil) y Flujo 1 (mapa y ruta multimodal) ya entregados, se agregaron cinco módulos nuevos siguiendo la misma arquitectura por capas (`domain` → `data` → `presentation/providers` → `presentation/widgets|screens`) con Riverpod manual y Dio:

| Módulo | Flujo que cubre | Estado |
|---|---|---|
| `emergency` | Flujo 3 — modo urgencia | ✅ Completo |
| `incidents` | Flujo 4 — reportes y verificación de vías | ✅ Completo |
| `assistant` | Flujo 5 — asistente IA y voz | ✅ Completo |
| `community` | Flujo 2 — Ayni, colaboración y ubicación en vivo | ✅ Completo |
| `government` | Flujo 8 — vista de monitoreo para gobierno | ✅ Completo |

Todos consumen los endpoints reales del backend NestJS (`http://localhost:3000/api/v1` en Android emulator vía `10.0.2.2`, `localhost` en web/desktop) — no hay datos simulados en el cliente.

## Modo Urgencia (Flujo 3) — `lib/modules/emergency/`

- **Entrada**: FAB rojo pulsante (`SosFab`) siempre visible sobre el mapa principal (`home_map_screen.dart`), con diálogo de confirmación antes de entrar al modo.
- **Pantalla** (`emergency_screen.dart`): tema de alto contraste (rojo oscuro `#B71C1C` / amarillo `#FFEB3B`), obtiene GPS real (con fallback al centro de La Paz si no hay permiso), pide `POST /emergency/route` y pinta el hospital recomendado + 2 alternativas en tarjetas animadas, más el mapa con polyline y marcadores.
- **Contactos**: grid 2×2 desde `GET /emergency/contacts`, con llamada directa vía `url_launcher` (`tel:`) y fallback hardcodeado (911/165/160/114) si el backend no responde — pensado para no dejar al usuario sin números en un corte de red.
- **Disclaimer obligatorio** visible en pantalla: *"Esta app ayuda a navegar; no despacha ambulancias."*

## Reportes de vías (Flujo 4) — `lib/modules/incidents/`

- **FAB de reporte** (`report_fab.dart`) sobre el mapa, abre `report_bottom_sheet.dart`: selector de tipo de incidente, pin en mapa, descripción opcional → `POST /incidents`.
- **Marcadores activos** en el mapa principal desde `GET /incidents/active` filtrados por bbox del viewport visible.
- **Confirmación comunitaria**: `incident_detail_sheet.dart` permite votar confirmar/desmentir un incidente pendiente cercano (`GET /incidents/pending/near`); al cruzar el umbral de confirmaciones el incidente pasa a activo y afecta las rutas de todos.
- Estado optimista en los providers (`incident_providers.dart`): el incidente reportado aparece en el mapa antes de la confirmación del servidor, y los votos actualizan la lista sin esperar un refetch completo.

## Asistente IA (Flujo 5) — `lib/modules/assistant/`

- **Chat** (`chat_screen.dart`) contra `POST /assistant/chat` (Azure AI Foundry / GPT-5 vía backend), con burbujas animadas (`chat_bubble.dart`), indicador de "escribiendo" (`typing_indicator.dart`) y chips de preguntas frecuentes (`faq_chips.dart`).
- **Entrada por voz**: `mic_button.dart` usa `speech_to_text` para dictado y `POST /assistant/voice-route` para resolver rutas habladas; salida hablada con `flutter_tts` — pensado para accesibilidad visual.
- Permisos nativos agregados: `RECORD_AUDIO` (Android), `NSMicrophoneUsageDescription` / `NSSpeechRecognitionUsageDescription` (iOS).

## Comunidad Ayni (Flujo 2) — `lib/modules/community/`

- **Compartir ubicación (opt-in)**: `share_optin_sheet.dart` inicia un `POST /collaboration/shares` solo con consentimiento explícito del usuario; mientras comparte, un chip de estado (`sharing_chip.dart`) lo muestra en pantalla.
- **Preguntar a la comunidad**: `ask_question_sheet.dart` → `POST /community/questions`, con costo en puntos Ayni y reembolso automático si nadie responde a tiempo.
- **Responder preguntas pendientes**: `pending_questions_screen.dart` + `question_answer_card.dart` consumen `GET /community/questions/pending`; al responder, el colaborador recibe los puntos de quien preguntó.
- **Historial y saldo**: `community_screen.dart` combina `GET /community/questions/mine`, `GET /users/me/ayni` (historial de movimientos) y el balance animado (`AyniBadge`, contador `TweenAnimationBuilder`).

## Vista de Gobierno (Flujo 8) — `lib/modules/government/`

- Pantalla gateada por rol `government` del perfil (`government_screen.dart`), con métricas desde `GET /government/congestion/summary` (tarjetas `metric_card.dart`, barras de distribución por tipo `kind_distribution_bars.dart`, serie de 7 días `daily_activity_chart.dart`).
- Listado y filtro de incidentes (`incident_filter_bar.dart`, `government_incident_tile.dart`) contra `GET /government/incidents`.

## Configuración de entorno agregada

- `mobile/dart_define.json` (gitignored): `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL` — plantilla en `dart_define.example.json`.
- `mobile/web/config.js` (gitignored): clave JS de Google Maps para build web — plantilla en `web/config.example.js`, cargada dinámicamente en `web/index.html` para no exponer la key en el HTML versionado.
- Dependencias nuevas en `pubspec.yaml`: `flutter_animate`, `gap`, `lottie`, `shimmer`, `image_picker`, `speech_to_text`, `flutter_tts`.

## Pendiente

- Pulido visual final y pruebas de flujo completo en dispositivo antes de la demo del 21-07-2026.
- Flujos 6 y 7 (superficie visual de zonas de riesgo y costos comparativos) quedan fuera de este avance.

# Chasqui — Prompts para Stitch (diseño mobile)

> Inventario de pantallas derivado de [03-frontend.md](03-frontend.md) y prompts listos para pegar en [Stitch](https://stitch.withgoogle.com) en modo **Mobile**. Stitch rinde mejor con descripciones en inglés, así que los prompts van en inglés pero **todo el copy de la UI se pide en español**.

## Inventario de pantallas

### Pantallas completas (15)

| # | Pantalla | Flujo | Módulo Flutter |
|---|---|---|---|
| 1 | Splash | 0 | `app/` |
| 2 | Onboarding (3 slides) | 0 | `auth` |
| 3 | Login | 0 | `auth` |
| 4 | Registro | 0 | `auth` |
| 5 | Preferencias iniciales (2 pasos) | 0 | `profile` |
| 6 | Perfil | 0 | `profile` |
| 7 | Home con mapa + buscador | 1 | `routing` |
| 8 | Opciones de ruta | 1 | `routing` |
| 9 | Detalle de ruta (timeline + mapa) | 1 | `routing` |
| 10 | Viaje en curso | 2 | `trips` |
| 11 | Historial de Puntos Chass | 2 | `collaboration` |
| 12 | Modo urgencia | 3 | `emergency` |
| 13 | Reportar incidente | 4 | `incidents` |
| 14 | Chat del asistente IA | 5 | `assistant` |
| 15 | Dashboard de gobierno | 8 | `government` |

### Sheets / overlays (6)

| # | Elemento | Flujo |
|---|---|---|
| 16 | Diálogo opt-in "compartir ubicación" | 2 |
| 17 | Sheet resultado "¿dónde viene mi transporte?" | 2 |
| 18 | Bottom sheet confirmación SOS | 3 |
| 19 | Sheet detalle de incidente | 4 |
| 20 | Tarjeta "¿sigue el bloqueo?" (confirmar reporte) | 4 |
| 21 | Overlay modo voz (pedir ruta hablando) | 5 |

**Total: ~21 diseños.** Stitch genera pocas pantallas por generación, así que la estrategia es: pegar primero el **prompt maestro** (contexto + design system) y luego ir pidiendo las pantallas por **lotes** en el mismo proyecto.

---

## Prompt maestro (pegar primero)

```
Design a mobile app called "Chasqui" — a multimodal urban mobility app for La Paz, Bolivia. It combines cable car (Mi Teleférico, 11 color-coded lines), PumaKatari buses, informal public transport (minibús, micro, trufi) and taxis into one smart route recommendation, avoiding street blockades and protests. It also has an "Ayni" points system (share your live location while riding to earn points, spend points to see where your bus is), an emergency mode, citizen incident reports, and an AI accessibility assistant.

ALL UI text must be in Spanish (Bolivia). Currency is always "Bs" (bolivianos).

Design system:
- Modern, clean, map-centric transit app. Rounded cards (16px radius), soft shadows, generous white space.
- Primary color: deep andean blue (#1E3A5F). Background: near-white (#F7F8FA). Dark text (#1A1D21).
- Accent palette = the real Mi Teleférico line colors, used as chips and route-segment colors: Roja #D32F2F, Amarilla #FBC02D, Verde #388E3C, Azul #1976D2, Celeste #29B6F6, Morada #7B1FA2, Naranja #F57C00, Café #6D4C41, Plateada #9E9E9E, Dorada #C9A227, Blanca #ECEFF1.
- Emergency mode uses high contrast: red #C62828 on white, extra-large typography.
- Transport mode icons: cable car gondola, bus, minivan, taxi, walking person.
- Accessibility: touch targets at least 48dp, AA contrast, clear labels.
- Bottom navigation with 4 tabs: "Inicio" (map), "Reportes", "Asistente", "Perfil". A persistent red circular SOS button floats above the bottom bar.

Start with the Home screen: a full-screen Google Map of La Paz with the cable car lines drawn in their colors, a rounded search bar at top with placeholder "¿A dónde vas?", a large microphone button next to it, a chip showing Chass points balance ("120 pts") at top right, a floating "Reportar" button, orange incident markers on the map, and the bottom navigation with the red SOS button.
```

## Lote 1 — Onboarding y auth

```
Add the onboarding and auth screens, same design system, all text in Spanish:

1. Splash: centered app logo concept for "Chasqui" (a stylized cable car cabin over intertwined route lines), deep blue background, tagline "Movilidad colaborativa para La Paz".

2. Onboarding (one screen, slide 1 of 3 with page dots): illustration of the La Paz cable car over the city, headline "Todos tus transportes en una sola ruta", body "Teleférico, PumaKatari, minibús y taxi combinados en la mejor opción", buttons "Siguiente" and "Omitir".

3. Login: email and password fields, primary button "Ingresar", link "¿Olvidaste tu contraseña?", secondary action "Crear cuenta". Show an inline field error state "Correo o contraseña incorrectos".

4. Registro: fields "Nombre", "Correo electrónico", "Contraseña" (helper text "Mínimo 8 caracteres"), primary button "Crear cuenta", legal microcopy line.

5. Preferencias iniciales (step 1 of 2, progress indicator): title "¿Cómo te movés mejor?", three large selectable cards with icons: "Sin preferencias", "Soy persona no vidente" (voice guidance icon), "Movilidad reducida" (wheelchair icon), button "Continuar". Mention step 2 selects default priority with three chips: "Rápido", "Barato", "Seguro".
```

## Lote 2 — Núcleo de rutas (el demo central)

```
Add the core route-planning screens, same design system, Spanish text:

1. Opciones de ruta: header with origin "Mi ubicación" and destination "Estación Central", three toggle chips "Tiempo" (selected), "Costo", "Seguridad". Below, a vertical list of route option cards. Each card shows: a row of transport mode icons connected by dots (walk → cable car red line → minibus), total time "34 min", total cost "Bs 9.50", distance, and a green badge "Evita bloqueo en Av. 6 de Agosto" on the first card. One card has a badge "Tramo en taxi por seguridad (+Bs 12)". Last card is a walking-only option "A pie · 25 min · Gratis".

2. Detalle de ruta: top half is a map with the route drawn as colored polylines (red segment for Línea Roja cable car, gray for walking). Bottom half is a vertical timeline of legs, each with: mode icon in the line's color, line name ("Línea Roja — Teleférico"), boarding stop "Sube en: Estación Central", exit stop "Baja en: Estación Cementerio", duration "12 min" and cost "Bs 3". Total row at bottom: "34 min · Bs 9.50" and a large primary button "Iniciar viaje". Include a small amber banner "Esta zona registra robos en este horario" above the button.

3. Viaje en curso: full-screen map with the active route polyline and a blue location dot mid-route, a top banner "Baja en: Estación Libertador — 2 paradas", a card anchored at bottom with: current leg info, a live toggle "Compartiendo ubicación · +2 pts por minuto" with a stop button "Dejar de compartir", and a secondary button "¿Dónde viene mi minibús? · 5 pts". Emergency numbers icon accessible in the corner.
```

## Lote 3 — Colaboración y Puntos Chass (sheets)

```
Add the points collaboration screens, same design system, Spanish text:

1. Historial de Puntos Chass: header card with big balance "120 Puntos Chass" and subtitle "Das y recibes: así funciona el ayni". Below, a transaction list: "+8 · Compartiste ubicación en Línea Amarilla · hoy 08:32", "-5 · Consultaste minibús Ruta 273 · ayer 19:10", green for earnings, red for spending.

2. Bottom sheet over the map, opt-in dialog: title "¿Compartir tu ubicación en este tramo?", explanation "Otros vecinos sabrán dónde viene el transporte. Ganás 2 puntos por minuto. Podés detenerlo cuando quieras.", primary button "Sí, compartir", text button "Ahora no", small privacy note "Solo mientras dura el tramo".

3. Bottom sheet result of vehicle query, honest empty state: icon of a minibus with a question mark, title "Aún no hay colaboradores en esta línea", body "No se descontaron tus puntos. Intentá de nuevo en unos minutos.", button "Entendido".
```

## Lote 4 — Urgencia y seguridad

```
Add the emergency screens. These use the high-contrast emergency style: red #C62828, white background, extra-large text. Spanish:

1. Bottom sheet SOS confirmation: big red warning icon, title "¿Activar modo urgencia?", body "Te llevaremos al hospital más cercano y verás los números de emergencia", huge red button "SÍ, ES UNA URGENCIA", gray button "Cancelar".

2. Modo urgencia (full screen): minimal high-contrast layout. Map with the fastest route to a hospital, header "Hospital de Clínicas — 8 min", link "Prefiero otro hospital (2 alternativas)". Fixed bottom row of four large call buttons with phone icons: "911 Policía", "165", "160 Ambulancia", "114 GAMLP". Everything oversized, no decorative elements.
```

## Lote 5 — Incidentes

```
Add the citizen incident report screens, same base design system, Spanish:

1. Reportar incidente: segmented selector with three options and icons: "Bloqueo", "Movilización", "Refacción". A small map preview with a draggable pin labeled "Tu ubicación actual", a text field "Descripción corta (opcional)", a photo upload tile "Agregar foto", primary button "Enviar reporte", helper "Tu reporte espera confirmación de otros vecinos".

2. Bottom sheet incident detail: orange banner "Reporte ciudadano verificado" (mention alternative gold banner "Cierre oficial — GAMLP"), incident type "Bloqueo en Av. Buenos Aires", photo thumbnail, description, meta "Reportado hace 25 min · 4 confirmaciones", button "Recalcular mi ruta".

3. Floating confirmation card over the map: "¿Sigue el bloqueo en Av. Buenos Aires?", two buttons side by side: "Sí, sigue" (orange) and "Ya no está" (gray).
```

## Lote 6 — Asistente IA, perfil y gobierno

```
Add the last screens, same design system, Spanish:

1. Chat del asistente: chat bubbles UI. Assistant bubble: "El próximo PumaKatari por Av. Arce pasa aprox. en 9 minutos" with a small gray tag "Estimación de la comunidad". User bubble: "¿Cuánto falta para mi bus?". Input bar with text field "Escribí tu pregunta…" and a prominent microphone button.

2. Voice overlay (over the home map): dimmed background, huge centered microphone with animated sound waves, live transcription text "Llevame al Hospital Obrero…", caption "Escuchando… hablá con confianza", cancel button. Designed for blind users: maximum contrast and size.

3. Perfil: avatar, name "María Quispe", email, a highlighted points balance card "120 puntos" with arrow to history, editable preference rows: "Perfil de accesibilidad: Ninguno", "Prioridad: Rápido", toggle "Modo oscuro", button "Cerrar sesión".

4. Dashboard gobierno (role-restricted screen, more data-dense): header "Monitoreo — GAMLP", a heatmap over the La Paz map showing incident clusters, summary stat cards: "12 bloqueos activos", "Zona más congestionada: Max Paredes", "48 reportes hoy", filter chips by type and a date range selector.
```

---

## Tips de uso en Stitch

- Trabajá todo en **un solo proyecto** de Stitch para que mantenga el design system entre generaciones.
- Si una pantalla sale desviada, pedí el ajuste como refinamiento ("make the SOS button larger and always visible"), no regeneres desde cero.
- Al exportar, Stitch da Figma/código HTML; usalo como referencia visual — la implementación real sigue las convenciones de `frontend-flutter` (Material 3, theme central, sin colores hardcodeados).

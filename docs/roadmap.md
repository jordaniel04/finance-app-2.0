# Roadmap — Finance App 2.0

> Última actualización: 2026-05-03

## Estado actual

La app tiene autenticación Google funcional, dashboard con CRUD completo de transacciones,
sistema de categorías personalizables, reportes con gráficos (mensual, anual, detalle por categoría),
consejo IA diario con Gemini con caché en Firestore, comparador de categorías ingreso/egreso,
y módulo de préstamos completamente funcional (2 tabs, préstamos otorgados/recibidos, pagos parciales,
interés, historial y vinculación automática con transacciones). Pendiente: pantalla de configuración
completa y filtros avanzados.

---

## Completado ✅

- [2026-01-xx] Configuración de entorno Flutter + Firebase (web)
- [2026-01-xx] Estructura Clean Architecture (domain / data / presentation)
- [2026-01-xx] Autenticación Google con `signInWithPopup()` para web (evita error 403)
- [2026-01-xx] Whitelist de correos con variables de entorno en tiempo de compilación
- [2026-01-xx] Entidades: TransactionEntity, CategoryEntity, UserEntity
- [2026-01-xx] Repositorio de transacciones con Firestore (stream en tiempo real)
- [2026-01-xx] Dashboard con balance mensual dinámico (ingresos, egresos, saldo)
- [2026-01-xx] Formulario de registro de transacciones (AddTransactionDialog)
- [2026-01-xx] Categorías con iconos y colores cargadas desde Firestore
- [2026-01-xx] Filtro por mes en el dashboard (sin lecturas extra a Firestore)
- [2026-01-xx] Skeletonizer para estados de carga
- [2026-01-xx] Modo oscuro (tema oscuro por defecto, paleta definida)
- [2026-01-xx] Formato de moneda S/. y fechas en español peruano (es_PE)
- [2026-04-26] Skills de Claude Code: tech-tutor, flutter-best-practices, firebase-patterns, ui-design, roadmap
- [2026-04-26] Hook de seguridad pre-deploy (bloquea `flutter build web` hasta revisar)
- [2026-04-28] Editar y eliminar transacciones (CRUD completo desde la UI)
- [2026-04-29] Correcciones visuales: botón Google, paleta oscura en login, toggle Gasto rojo, SnackBar sin verde
- [2026-04-29] Bottom Navigation Bar con 4 tabs (MainShell): Transacciones, Reportes, Préstamos, Configuración
- [2026-04-29] Categorías reales cargadas (22 egresos + 8 ingresos) con íconos verificados del SDK de Flutter
- [2026-04-29] Selector de ícono y color en CategoryDialog (32 íconos + 24 colores)
- [2026-04-29] `createdBy` y `createdAt` en transacciones — visible al editar junto al `updatedBy`
- [2026-05-02] Pantalla de Reportes completa: tabs Mensual, Anual, Detalle con gráficos donut y barras (fl_chart)
- [2026-05-02] Consejo IA diario con Gemini 2.5 Flash — caché en Firestore (`ai_tips/{userId}/daily/{fecha}`)
- [2026-05-02] Banner de consejo IA dismissible en dashboard + historial paginado en tab Consejos IA
- [2026-05-02] Prompt de IA mejorado: desglose mes a mes por las top 5 categorías históricas (últimos 3 meses → mes actual)
- [2026-05-02] Tab "Comparar" en Reportes: selección múltiple de categorías ingreso/egreso con chips, cálculo de ganancia/déficit en memoria sin guardar en Firestore
- [2026-05-03] Módulo de Préstamos completo: LoanEntity, LoanCubit, FirebaseLoanRepositoryImpl, colección `loans` en Firestore, 2 tabs (me deben / debo), pagos parciales con historial, interés embebido en totalAmount, vinculación automática con `transactions` via `loanId`

---

## En progreso 🔄

_(nada en progreso actualmente)_

---

## Próximos pasos 📋

Features priorizadas, en orden de prioridad:

1. **Pantalla de Configuración** — completar la pantalla actual:
   - Foto, nombre y correo del usuario autenticado
   - Acceso a gestión de categorías (crear, editar, eliminar)
   - Opción de cerrar sesión

3. **Filtros avanzados en Transacciones** — filtrar por categoría, tipo (ingreso/gasto), rango de fechas personalizado

4. **Exportar datos** — desde Reportes: CSV o PDF del período seleccionado

---

## Backlog 💡

Ideas y features futuras sin prioridad definida:

- Metas de ahorro — definir un objetivo mensual y ver el progreso
- Notificaciones / recordatorios (requiere service worker para web)
- Soporte multi-cuenta (hoy está pensado para 2 usuarios compartidos)
- Sincronización offline / PWA completa con manifiesto y service worker
- Modo claro opcional (hoy solo existe modo oscuro)
- Historial de cambios de una transacción (auditoría)
- Dashboard compartido entre los 2 usuarios autorizados (saldos conjuntos)
- Análisis IA bajo demanda en Reportes (más profundo que el consejo diario)
- Consejos IA: mover el historial a pantalla propia para no saturar Reportes

---

## Decisiones de arquitectura 🏗️

- **signInWithPopup() en lugar de signInWithRedirect()**: evita perder el estado de la app en web y errores 403 con la People API de Google.
- **Filtro de mes en memoria, no en Firestore**: `TransactionCubit` guarda `_allTransactions` localmente. Cambiar el mes no hace una nueva lectura — reduce costos de Firestore.
- **UUID para IDs de transacciones**: control explícito del ID del documento en Firestore, en lugar de dejar que Firestore lo genere automáticamente.
- **Whitelist en tiempo de compilación**: los correos autorizados se inyectan via `--dart-define` para no exponerlos en el código fuente del bundle web.
- **Categorías con `.get()` (una sola lectura)**: las categorías casi no cambian, no necesitan stream en tiempo real — ahorra lecturas.
- **Persistencia Firestore deshabilitada**: `persistenceEnabled: false` en `main.dart` — evita inconsistencias en web donde el caché local puede ser problemático.
- **Navegación con 4 tabs (MainShell)**: Transacciones, Reportes, Préstamos, Configuración. Categorías vive dentro de Configuración — no merece tab propio porque no se visita diariamente.
- **Consejo IA diario guardado en Firestore**: ruta `ai_tips/{userId}/daily/{fecha}`. Una sola llamada a Gemini por día por usuario — el resto del día se lee desde Firestore. API key pasada como `--dart-define`, no en Cloud Function (menor complejidad para 2 usuarios).
- **API de IA elegida: Gemini 2.5 Flash**: gratuita (1500 req/día), suficiente para 2 usuarios. No usar Claude API (reservar créditos).
- **Comparador en memoria**: el tab Comparar calcula ingresos − egresos por categoría sin nuevas lecturas a Firestore — usa los datos ya cargados en `TransactionCubit`.
- **Prompt IA con historial por categoría**: en lugar de un solo número promedio, el prompt incluye la evolución mes a mes de las top 5 categorías para que Gemini detecte tendencias específicas.
- **Préstamos como transacciones vinculadas**: al crear un préstamo o registrar un pago, se genera automáticamente una `TransactionEntity` en `transactions/` con el campo `loanId`. El balance del dashboard refleja los préstamos sin lógica adicional.
- **Interés embebido en totalAmount**: no hay cálculo de interés — el usuario ingresa el monto acordado directamente. `interest = totalAmount - originalAmount` se calcula en la entidad para mostrarlo en UI.
- **Pagos como lista en el documento del préstamo**: los pagos parciales se guardan como lista dentro del documento `loans/{id}` (no subcolección) — suficiente para préstamos personales con pocos pagos, y reduce lecturas de Firestore.

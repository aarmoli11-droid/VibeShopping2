// Mapa real con supermercados, posición GPS del usuario, distancias y tiempos
// de traslado (flutter_map + OpenStreetMap).
// Las tiendas se cargan desde Supabase (tabla `supermarkets`); la ubicación
// proviene de LocationProvider (GPS) y los estados se resuelven en
// LocationDemoLogic.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/data/supabase/supabase_product_repository.dart';
import '../../core/location/location_provider.dart';
import '../../core/vibe_constants.dart';
import 'location_demo_data.dart';
import 'location_demo_logic.dart';
import 'location_demo_map_widgets.dart';
import 'location_demo_store.dart';
import 'location_demo_store_details_screen.dart';

class LocationDemoScreen extends StatefulWidget {
  const LocationDemoScreen({super.key, this.isActive = true});

  // El shell mantiene todos los tabs montados (IndexedStack); isActive indica
  // cuándo el tab Ubicación pasa a primer plano para pedir la ubicación.
  final bool isActive;

  @override
  State<LocationDemoScreen> createState() => _LocationDemoScreenState();
}

class _LocationDemoScreenState extends State<LocationDemoScreen>
    with WidgetsBindingObserver {
  final MapController _mapController = MapController();

  List<DemoStore> _stores = const [];
  bool _loading = true;
  bool _hasError = false;
  double _radiusKm = LocationDemoLogic.initialRadiusKm;
  bool _bootstrapped = false;
  bool _mapReady = false;
  bool _rationaleShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) _scheduleBootstrap();
  }

  @override
  void didUpdateWidget(covariant LocationDemoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _scheduleBootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver a la app (p. ej. tras conceder el permiso en Ajustes),
    // se vuelve a comprobar la ubicación.
    if (state == AppLifecycleState.resumed && _bootstrapped) {
      _refreshOnResume();
    }
  }

  void _scheduleBootstrap() {
    if (_bootstrapped) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    await _loadStores();
    if (!mounted) return;
    await _initLocation();
  }

  // Carga las tiendas reales desde Supabase (sin respaldo ficticio).
  Future<void> _loadStores() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final supermarkets =
          await context.read<SupabaseProductRepository>().listSupermarkets();
      if (!mounted) return;
      setState(() {
        _stores = LocationDemoLogic.demoStoresFromModels(supermarkets);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stores = const [];
        _loading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _initLocation() async {
    final location = context.read<LocationProvider>();
    await location.initialize();
    if (!mounted) return;
    if (location.isGranted) {
      await location.refreshPosition();
      if (mounted) _centerOnUser();
    } else if (location.status == LocationStatus.permissionDenied) {
      await _requestLocation();
    }
  }

  // Explica para qué se usa la ubicación y, si se acepta, la solicita.
  Future<void> _requestLocation() async {
    final location = context.read<LocationProvider>();
    if (!_rationaleShown) {
      _rationaleShown = true;
      final accepted = await _showRationaleDialog();
      if (!mounted || accepted != true) return;
    }
    final granted = await location.requestPermissionAndLocate();
    if (mounted && granted) _centerOnUser();
  }

  Future<void> _refreshOnResume() async {
    final location = context.read<LocationProvider>();
    await location.initialize();
    if (!mounted || !location.isGranted) return;
    if (!location.hasPosition) await location.refreshPosition();
    if (mounted) _centerOnUser();
  }

  Future<bool?> _showRationaleDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usar tu ubicación'),
        content: const Text(
          'VibeShopping usa tu ubicación para mostrar los supermercados '
          'cercanos y calcular distancias y tiempos. No guardamos tus '
          'coordenadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: VibeColors.navy),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Permitir'),
          ),
        ],
      ),
    );
  }

  void _handleMapReady() {
    _mapReady = true;
    _centerOnUser();
  }

  // Centra el mapa en la posición actual del usuario (si existe).
  void _centerOnUser() {
    final location = context.read<LocationProvider>();
    if (!_mapReady || !location.hasPosition) return;
    _mapController.move(
      LatLng(location.latitude!, location.longitude!),
      LocationDemoData.initialZoom,
    );
  }

  void _expandRadius() {
    setState(() {
      _radiusKm = LocationDemoLogic.nextRadiusKm(_radiusKm);
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>();
    final hasPosition = location.hasPosition;

    final visibleStores = hasPosition
        ? LocationDemoLogic.storesWithinRadius(
            stores: _stores,
            userLatitude: location.latitude!,
            userLongitude: location.longitude!,
            radiusKm: _radiusKm,
          )
        : const <DemoStore>[];

    final state = LocationDemoLogic.resolveContentState(
      storesLoading: _loading,
      storesError: _hasError,
      locationStatus: location.status,
      hasPosition: hasPosition,
      visibleStoreCount: visibleStores.length,
    );

    return Scaffold(
      backgroundColor: VibeColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Ubicación'),
        backgroundColor: VibeColors.backgroundWhite,
        foregroundColor: VibeColors.navy,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'Consulta la distancia hasta tus supermercados',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildContent(location, visibleStores, state)),
            _buildStatusBar(visibleStores, state),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(LocationProvider location, List<DemoStore> visibleStores,
      MapContentState state) {
    switch (state) {
      case MapContentState.loadingStores:
        return _messageState(
          icon: Icons.storefront_rounded,
          title: 'Cargando supermercados…',
        );
      case MapContentState.acquiringLocation:
        return _messageState(
          icon: Icons.my_location_rounded,
          title: 'Obteniendo tu ubicación…',
        );
      case MapContentState.storesError:
        return _messageState(
          icon: Icons.cloud_off_rounded,
          title: 'No se pudieron cargar los supermercados',
          message: 'Verifica tu conexión e inténtalo de nuevo.',
          actionLabel: 'Reintentar',
          onAction: _loadStores,
        );
      case MapContentState.serviceDisabled:
        return _messageState(
          icon: Icons.location_off_rounded,
          title: 'Los servicios de ubicación están desactivados',
          message: 'Actívalos en los Ajustes del dispositivo para ver los '
              'supermercados cercanos.',
          actionLabel: 'Abrir Ajustes',
          onAction: () => location.openAppSettings(),
        );
      case MapContentState.permissionDenied:
        return _messageState(
          icon: Icons.location_disabled_rounded,
          title: 'Permiso de ubicación denegado',
          message: 'Sin tu ubicación no podemos calcular distancias. Concede '
              'el permiso para ver los supermercados cercanos.',
          actionLabel: 'Permitir ubicación',
          onAction: _requestLocation,
        );
      case MapContentState.permissionDeniedForever:
        return _messageState(
          icon: Icons.location_disabled_rounded,
          title: 'Permiso de ubicación bloqueado',
          message: 'El permiso fue denegado permanentemente. Actívalo en los '
              'Ajustes del dispositivo.',
          actionLabel: 'Abrir Ajustes',
          onAction: () => location.openAppSettings(),
        );
      case MapContentState.locationError:
        return _messageState(
          icon: Icons.location_disabled_rounded,
          title: 'No se pudo obtener tu ubicación',
          message: 'Inténtalo de nuevo.',
          actionLabel: 'Reintentar',
          onAction: _refreshOnResume,
        );
      case MapContentState.noNearby:
      case MapContentState.ready:
        return _buildMap(location, visibleStores);
    }
  }

  Widget _buildMap(LocationProvider location, List<DemoStore> visibleStores) {
    final center = location.hasPosition
        ? LatLng(location.latitude!, location.longitude!)
        : const LatLng(
            LocationDemoData.userLatitude, LocationDemoData.userLongitude);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: LocationDemoData.initialZoom,
                minZoom: LocationDemoData.minZoom,
                maxZoom: LocationDemoData.maxZoom,
                backgroundColor: VibeColors.backgroundMint,
                onMapReady: _handleMapReady,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: LocationDemoData.tileUrlTemplate,
                  userAgentPackageName: LocationDemoData.userAgentPackageName,
                  maxNativeZoom: 19,
                ),
                MarkerLayer(markers: _buildMarkers(location, visibleStores)),
                const SimpleAttributionWidget(
                  source: Text(LocationDemoData.attribution),
                ),
              ],
            ),
            ZoomControls(
              onZoomIn: () => _changeZoom(1),
              onZoomOut: () => _changeZoom(-1),
            ),
          ],
        ),
      ),
    );
  }

  // Marcadores de las tiendas cercanas y de la posición actual del usuario.
  List<Marker> _buildMarkers(
      LocationProvider location, List<DemoStore> visibleStores) {
    final markers = <Marker>[
      for (final store in visibleStores)
        Marker(
          point: LatLng(store.latitude, store.longitude),
          width: 120,
          height: 40,
          alignment: Alignment.topCenter,
          child: StoreMarker(
            store: store,
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => StoreDetailsScreen(store: store),
              ),
            ),
          ),
        ),
    ];
    if (location.hasPosition) {
      markers.add(Marker(
        point: LatLng(location.latitude!, location.longitude!),
        width: 90,
        height: 40,
        alignment: Alignment.topCenter,
        child: const UserMarker(),
      ));
    }
    return markers;
  }

  // Barra inferior: radio en uso, resultado o ampliación de búsqueda.
  Widget _buildStatusBar(List<DemoStore> visibleStores, MapContentState state) {
    if (state != MapContentState.ready && state != MapContentState.noNearby) {
      return const SizedBox(height: 16);
    }

    final radiusLabel = _radiusKm.toStringAsFixed(0);
    final Widget body;
    if (state == MapContentState.ready) {
      body = Text(
        '${visibleStores.length} supermercado(s) en un radio de $radiusLabel km.\n'
        'Selecciona una tienda para ver su distancia y tiempo de viaje.',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      );
    } else {
      final canExpand = LocationDemoLogic.canExpandRadius(_radiusKm);
      body = Column(
        children: [
          Text(
            'No hay supermercados en un radio de $radiusLabel km.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          if (canExpand) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: VibeColors.navy),
              onPressed: _expandRadius,
              icon: const Icon(Icons.zoom_out_map_rounded, size: 18),
              label: Text(
                'Ampliar a ${LocationDemoLogic.nextRadiusKm(_radiusKm).toStringAsFixed(0)} km',
              ),
            ),
          ],
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: body,
    );
  }

  // Mensaje de estado con ícono, texto y acción opcional.
  Widget _messageState({
    required IconData icon,
    required String title,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: VibeColors.navy,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: VibeColors.navy),
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Aplica un cambio de zoom al centro actual del mapa.
  void _changeZoom(double delta) {
    final camera = _mapController.camera;
    final zoom = (camera.zoom + delta)
        .clamp(LocationDemoData.minZoom, LocationDemoData.maxZoom);
    _mapController.move(camera.center, zoom.toDouble());
  }
}
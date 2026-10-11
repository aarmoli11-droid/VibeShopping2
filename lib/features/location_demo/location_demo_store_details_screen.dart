// Pantalla completa y reutilizable con los detalles de una sucursal.
// Recibe cualquier DemoStore (BM, CoopeAgri, Maxi Palí, etc.) y presenta su
// información; no hay pantallas por cadena ni datos codificados.
// Se abre desde el mapa con Navigator.push y, al cerrarla, el mapa conserva su
// estado, su cámara y la ubicación (no se vuelve a pedir permiso GPS).

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/external_links.dart';
import '../../core/location/location_provider.dart';
import '../../core/opening_hours.dart';
import '../../core/vibe_constants.dart';
import 'location_demo_logic.dart';
import 'location_demo_store.dart';

class StoreDetailsScreen extends StatelessWidget {
  const StoreDetailsScreen({super.key, required this.store});

  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>();
    final hasPosition = location.hasPosition;

    return Scaffold(
      backgroundColor: VibeColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: VibeColors.backgroundWhite,
        foregroundColor: VibeColors.navy,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildPhoto(),
            const SizedBox(height: 16),
            _buildOpeningHours(),
            const SizedBox(height: 12),
            _buildContactCard(),
            const SizedBox(height: 12),
            _buildTransportSection(hasPosition, location),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          store.displayTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: VibeColors.navy,
          ),
        ),
        if (store.address.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            store.address,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  Widget _buildPhoto() {
    final url = store.photoUrl;
    final Widget content;
    if (url == null || url.isEmpty) {
      content = const _PhotoPlaceholder();
    } else {
      content = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, _) => const _PhotoPlaceholder(loading: true),
        errorWidget: (context, error, stackTrace) => const _PhotoPlaceholder(),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: content,
      ),
    );
  }

  // Horarios desplegables de la sucursal (lunes a domingo).
  Widget _buildOpeningHours() {
    final hours = store.openingHours;
    final status = hours?.statusLabel(DateTime.now()) ?? 'Horario no disponible';
    return _ExpandableSection(
      icon: Icons.schedule_rounded,
      title: 'Horarios',
      subtitle: status,
      children: [
        for (var dayIndex = 0; dayIndex < OpeningHours.dayKeys.length; dayIndex++)
          _DayScheduleRow(
            label: _dayLabels[dayIndex],
            intervals: hours?.forDay(OpeningHours.dayKeys[dayIndex]),
          ),
      ],
    );
  }

  Widget _buildContactCard() {
    final validCoords = !(store.latitude == 0 && store.longitude == 0);
    final phone = (store.phone == null || store.phone!.isEmpty) ? null : store.phone!;
    final hasAddress = store.address.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VibeColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VibeColors.mint, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dirección y contacto',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: VibeColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          if (hasAddress)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_rounded,
                    size: 20, color: VibeColors.navy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    store.address,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
          if (hasAddress) const SizedBox(height: 12),
          Row(
            children: [
              if (validCoords)
                Expanded(
                  child: FilledButton.icon(
                    style:
                        FilledButton.styleFrom(backgroundColor: VibeColors.navy),
                    onPressed: () => ExternalLinks.openGoogleMaps(
                      latitude: store.latitude,
                      longitude: store.longitude,
                    ),
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text('Abrir en Google Maps'),
                  ),
                ),
              if (validCoords && phone != null) const SizedBox(width: 8),
              if (phone != null)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VibeColors.navy,
                      side: const BorderSide(color: VibeColors.navy),
                    ),
                    onPressed: () => ExternalLinks.openPhone(phone),
                    icon: const Icon(Icons.phone_rounded, size: 18),
                    label: Text(phone),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Transportes desplegables con tiempos y distancia (GPS actual).
  Widget _buildTransportSection(
      bool hasPosition, LocationProvider location) {
    return _ExpandableSection(
      icon: Icons.directions_rounded,
      title: 'Medios de transporte',
      subtitle: hasPosition
          ? 'Estimaciones'
          : 'Activa tu ubicación para consultar las estimaciones',
      children: [
        if (!hasPosition)
          const _NoLocationNotice()
        else ...[
          for (final estimate in LocationDemoLogic.transportEstimates(
            store: store,
            userLatitude: location.latitude!,
            userLongitude: location.longitude!,
          ))
            _TransportRow(estimate: estimate),
          const SizedBox(height: 8),
          const Text(
            'Distancia en línea recta (Haversine) y tiempos estimados de '
            'referencia del prototipo. No son rutas reales ni horarios de bus.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}

// Sección desplegable reutilizada para horarios y transportes.
class _ExpandableSection extends StatelessWidget {
  const _ExpandableSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VibeColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VibeColors.mint, width: 1.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: VibeColors.navy,
          collapsedIconColor: VibeColors.navy,
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Icon(icon, color: VibeColors.navy),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: VibeColors.navy,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          children: children,
        ),
      ),
    );
  }
}

// Fila de un día con su horario (desplegable de horarios).
class _DayScheduleRow extends StatelessWidget {
  const _DayScheduleRow({required this.label, required this.intervals});

  final String label;
  final List<OpeningInterval>? intervals;

  @override
  Widget build(BuildContext context) {
    final String value;
    if (intervals == null) {
      value = 'Sin horario';
    } else if (intervals!.isEmpty) {
      value = 'Cerrado';
    } else {
      value = intervals!
          .map((i) =>
              '${OpeningHours.formatTime12(i.open)} – ${OpeningHours.formatTime12(i.close)}')
          .join('\n');
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: VibeColors.navy,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// Fila de un medio de transporte con tiempo y distancia.
class _TransportRow extends StatelessWidget {
  const _TransportRow({required this.estimate});

  final TransportEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (estimate.mode) {
      TransportMode.car => ('Carro', Icons.directions_car_rounded),
      TransportMode.bus => ('Bus', Icons.directions_bus_rounded),
      TransportMode.moto => ('Motocicleta', Icons.two_wheeler_rounded),
      TransportMode.bike => ('Bicicleta', Icons.directions_bike_rounded),
      TransportMode.walking => ('Caminando', Icons.directions_walk_rounded),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: VibeColors.mint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: VibeColors.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: VibeColors.navy,
                  ),
                ),
                Text(
                  '${estimate.distanceKm.toStringAsFixed(1)} km · línea recta (estimado)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '${estimate.minutes} min',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: VibeColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

// Aviso cuando el usuario no tiene una posición GPS válida (no se calculan
// distancias ni tiempos desde coordenadas fijas).
class _NoLocationNotice extends StatelessWidget {
  const _NoLocationNotice();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.location_off_rounded, size: 20, color: Colors.grey),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Activa tu ubicación para consultar las estimaciones.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder sobrio para la fotografía (carga o ausencia de imagen).
class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: VibeColors.backgroundMint,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              loading ? Icons.hourglass_top_rounded : Icons.storefront_rounded,
              size: 40,
              color: VibeColors.navy.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              loading ? 'Cargando foto…' : 'Sin fotografía',
              style: TextStyle(
                fontSize: 13,
                color: VibeColors.navy.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Etiquetas de los días en español (las claves estables quedan en inglés).
const List<String> _dayLabels = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];
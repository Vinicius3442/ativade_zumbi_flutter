import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/app_theme.dart';
import '../models/horde_alert_model.dart';
import '../models/shelter_model.dart';
import '../providers/game_providers.dart';
import '../widgets/shelter_card.dart';

class MapSheltersScreen extends ConsumerStatefulWidget {
  const MapSheltersScreen({super.key});

  @override
  ConsumerState<MapSheltersScreen> createState() => _MapSheltersScreenState();
}

class _MapSheltersScreenState extends ConsumerState<MapSheltersScreen> {
  final MapController _mapController = MapController();
  LatLng _selectedPoint = const LatLng(-23.5505, -46.6333);
  bool _showListPanel = false;
  String _locationSourceLabel = 'Toque no mapa ou use o GPS';

  Future<void> _fetchDeviceGps() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locationSourceLabel =
              'GPS desativado — usando seleção manual por toque no mapa';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Serviço de GPS desativado. Você pode tocar em qualquer ponto do mapa para escolher a localização manualmente!',
            ),
          ),
        );
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationSourceLabel =
              'Permissão GPS negada — escolha manual ativa no mapa';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permissão de GPS negada. Escolha manual ativa: basta tocar no mapa!',
            ),
          ),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final latLng = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _selectedPoint = latLng;
        _locationSourceLabel =
            'GPS Ativo: (${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)})';
      });
      _mapController.move(latLng, 15.0);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationSourceLabel = 'Modo manual: toque no mapa para posicionar';
      });
    }
  }

  Future<void> _openCreateShelterDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final capCtrl = TextEditingController(text: '20');
    String visibility = 'faction';
    String status = 'seguro';
    Uint8List? photoBytes;
    String? photoExt;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: ProtocoloZColors.cardGray,
          title: const Row(
            children: [
              Icon(
                Icons.add_location_alt_rounded,
                color: ProtocoloZColors.radarGreen,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CADASTRAR ABRIGO (+15 REP)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: ProtocoloZColors.radarGreen,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ProtocoloZColors.bgDarkest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ProtocoloZColors.borderGray),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.my_location_rounded,
                        size: 16,
                        color: ProtocoloZColors.radarGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${_selectedPoint.latitude.toStringAsFixed(4)}, '
                          'Lng: ${_selectedPoint.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: ProtocoloZColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Abrigo',
                    hintText: 'Ex: Bunker Subterrâneo Setor 4',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descrição e Recursos',
                    hintText: 'Ex: Portas blindadas, gerador e água potável.',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: capCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Capacidade de Sobreviventes',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'VISIBILIDADE (PROTEGIDA POR RLS NO SERVIDOR)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ProtocoloZColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'public',
                      label: Text('PÚBLICO'),
                      icon: Icon(Icons.public_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: 'faction',
                      label: Text('SÓ FACÇÃO'),
                      icon: Icon(Icons.lock_rounded, size: 16),
                    ),
                  ],
                  selected: {visibility},
                  onSelectionChanged: (s) =>
                      setModalState(() => visibility = s.first),
                ),
                const SizedBox(height: 12),
                const Text(
                  'STATUS DO PERÍMETRO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ProtocoloZColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'seguro', label: Text('SEGURO')),
                    ButtonSegment(
                      value: 'comprometido',
                      label: Text('COMPROMETIDO'),
                    ),
                  ],
                  selected: {status},
                  onSelectionChanged: (s) =>
                      setModalState(() => status = s.first),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 75,
                          );
                          if (picked != null) {
                            final bytes = await picked.readAsBytes();
                            final ext = picked.name.split('.').last;
                            setModalState(() {
                              photoBytes = bytes;
                              photoExt = ext;
                            });
                          }
                        },
                        icon: const Icon(Icons.photo_library_rounded, size: 16),
                        label: Text(
                          photoBytes != null ? 'FOTO ANEXADA' : 'GALERIA',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 75,
                          );
                          if (picked != null) {
                            final bytes = await picked.readAsBytes();
                            final ext = picked.name.split('.').last;
                            setModalState(() {
                              photoBytes = bytes;
                              photoExt = ext;
                            });
                          }
                        },
                        icon: const Icon(Icons.camera_alt_rounded, size: 16),
                        label: const Text(
                          'CÂMERA',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final desc = descCtrl.text.trim();
                final cap = int.tryParse(capCtrl.text.trim()) ?? 10;
                if (name.length < 3 || desc.length < 4 || cap <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Preencha nome, descrição e capacidade válida (> 0).',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(gameControllerProvider.notifier)
                      .createShelter(
                        name: name,
                        description: desc,
                        capacity: cap,
                        latitude: _selectedPoint.latitude,
                        longitude: _selectedPoint.longitude,
                        visibility: visibility,
                        status: status,
                        photoBytes: photoBytes,
                        photoExtension: photoExt,
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Abrigo registrado no mapa! +15 pontos de reputação concedidos pelo servidor.',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: ProtocoloZColors.crimsonRed,
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('SALVAR ABRIGO'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MAPA TÁTICO & ABRIGOS'),
        actions: [
          IconButton(
            tooltip: 'Usar Minha Localização GPS',
            onPressed: _fetchDeviceGps,
            icon: const Icon(
              Icons.my_location_rounded,
              color: ProtocoloZColors.radarGreen,
            ),
          ),
          IconButton(
            tooltip: _showListPanel ? 'Ver Mapa' : 'Ver Lista de Abrigos',
            onPressed: () => setState(() => _showListPanel = !_showListPanel),
            icon: Icon(
              _showListPanel ? Icons.map_rounded : Icons.list_alt_rounded,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de status de coordenadas e legenda
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: ProtocoloZColors.bgBunker,
            child: Row(
              children: [
                const Icon(
                  Icons.touch_app_rounded,
                  size: 16,
                  color: ProtocoloZColors.radarGreen,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _locationSourceLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: ProtocoloZColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.security_rounded,
                  size: 14,
                  color: ProtocoloZColors.radarGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  '${gs.shelters.length} Abrigos',
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.crisis_alert_rounded,
                  size: 14,
                  color: ProtocoloZColors.hordeRed,
                ),
                const SizedBox(width: 4),
                Text(
                  '${gs.activeAlerts.length} Hordas',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            child: _showListPanel
                ? _buildSheltersList(gs.shelters, gs.profile?.id ?? '')
                : Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _selectedPoint,
                          initialZoom: 13.5,
                          onTap: (_, latLng) {
                            setState(() {
                              _selectedPoint = latLng;
                              _locationSourceLabel =
                                  'Selecionado no mapa: (${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)})';
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'br.com.resistencia.protocolo_z',
                          ),
                          MarkerLayer(
                            markers: [
                              // Marcador do ponto selecionado pelo jogador
                              Marker(
                                point: _selectedPoint,
                                width: 44,
                                height: 44,
                                child: const Icon(
                                  Icons.add_location_rounded,
                                  color: ProtocoloZColors.textPrimary,
                                  size: 36,
                                ),
                              ),
                              // Marcadores de Abrigos (Ícone de Escudo Verde / Cinza)
                              for (final s in gs.shelters)
                                Marker(
                                  point: LatLng(s.latitude, s.longitude),
                                  width: 110,
                                  height: 68,
                                  child: GestureDetector(
                                    onTap: () => context.push('/abrigos/${s.id}'),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: s.isSafe
                                                ? ProtocoloZColors.tacticalGreen
                                                : ProtocoloZColors.cardGray,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: s.isSafe
                                                  ? ProtocoloZColors.radarGreen
                                                  : ProtocoloZColors.hordeRed,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            s.isPublic
                                                ? Icons.security_rounded
                                                : Icons.lock_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ProtocoloZColors.bgDarkest
                                                .withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            s.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: ProtocoloZColors.radarGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              // Marcadores de Alertas de Horda Ativos (Ícone Vermelho Diferente!)
                              for (final a in gs.activeAlerts)
                                Marker(
                                  point: LatLng(a.latitude, a.longitude),
                                  width: 110,
                                  height: 68,
                                  child: GestureDetector(
                                    onTap: () => _showAlertQuickSheet(a),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: ProtocoloZColors.crimsonRed,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.crisis_alert_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ProtocoloZColors.darkRedSurface,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'HORDA ${a.intensity.toUpperCase()}',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ProtocoloZColors.tacticalGreen,
        foregroundColor: Colors.white,
        onPressed: _openCreateShelterDialog,
        icon: const Icon(Icons.add_home_work_rounded),
        label: const Text(
          'NOVO ABRIGO (+15 REP)',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  void _showAlertQuickSheet(HordeAlertModel alert) {
    final uid = ref.read(gameControllerProvider).profile?.id ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: ProtocoloZColors.cardGray,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HORDA AVISTADA • INTENSIDADE ${alert.intensity.toUpperCase()}',
              style: const TextStyle(
                color: ProtocoloZColors.hordeRed,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(alert.description),
            const SizedBox(height: 8),
            Text(
              'Autor: ${alert.authorNickname ?? 'Sobrevivente'} • Confirmações: ${alert.confirmationsCount}/2',
              style: const TextStyle(
                fontSize: 12,
                color: ProtocoloZColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            if (alert.authorId != uid && !alert.isConfirmedBy(uid))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProtocoloZColors.crimsonRed,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(gameControllerProvider.notifier)
                        .confirmHordeAlert(alert.id);
                  },
                  icon: const Icon(Icons.verified_rounded),
                  label: const Text('CONFIRMAR AVISTAMENTO'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheltersList(List<ShelterModel> shelters, String currentUid) {
    if (shelters.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum abrigo visível registrado no setor.',
          style: TextStyle(color: ProtocoloZColors.textMuted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: shelters.length,
      itemBuilder: (_, idx) {
        final s = shelters[idx];
        return ShelterCard(
          shelter: s,
          isOwner: s.authorId == currentUid,
          onTap: () => context.push('/abrigos/${s.id}'),
        );
      },
    );
  }
}

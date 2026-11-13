import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/horde_alert_model.dart';
import '../models/shelter_model.dart';

/// 1. Logotipo 2D Vetorial Animado do Protocolo Z (Verde, Cinza e Vermelho)
class ProtocoloZLogo2D extends StatefulWidget {
  final double size;
  const ProtocoloZLogo2D({super.key, this.size = 140});

  @override
  State<ProtocoloZLogo2D> createState() => _ProtocoloZLogo2DState();
}

class _ProtocoloZLogo2DState extends State<ProtocoloZLogo2D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _Logo2DPainter(progress: _ctrl.value),
        );
      },
    );
  }
}

class _Logo2DPainter extends CustomPainter {
  final double progress;
  _Logo2DPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;

    // Fundo Hexagonal / Escudo Cinza Blindado
    final shieldPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final pt = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        shieldPath.moveTo(pt.dx, pt.dy);
      } else {
        shieldPath.lineTo(pt.dx, pt.dy);
      }
    }
    shieldPath.close();

    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = ProtocoloZColors.cardGray
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = ProtocoloZColors.steelGray
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // Anéis concêntricos de radar (Verde Tático)
    final ringPaint = Paint()
      ..color = ProtocoloZColors.radarGreen.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius * 0.78, ringPaint);
    canvas.drawCircle(center, radius * 0.52, ringPaint);

    // Feixe de varredura do radar 2D girando
    final sweepAngle = progress * 2 * math.pi;
    final sweepRect = Rect.fromCircle(center: center, radius: radius * 0.78);
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 0.65,
        colors: [
          ProtocoloZColors.radarGreen.withValues(alpha: 0.0),
          ProtocoloZColors.radarGreen.withValues(alpha: 0.45),
        ],
        transform: GradientRotation(sweepAngle),
      ).createShader(sweepRect);

    canvas.drawArc(
      sweepRect,
      sweepAngle,
      math.pi * 0.65,
      true,
      sweepPaint,
    );

    // Retícula cruzada cinza/verde
    final crossPaint = Paint()
      ..color = ProtocoloZColors.borderGray
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(center.dx - radius * 0.78, center.dy),
      Offset(center.dx + radius * 0.78, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.78),
      Offset(center.dx, center.dy + radius * 0.78),
      crossPaint,
    );

    // Alerta Biohazard / Z estilizado em Vermelho Escarlate + Verde Neon
    final pulse = 0.85 + 0.15 * math.sin(progress * 2 * math.pi);
    final zSize = radius * 0.44 * pulse;

    final zPath = Path()
      ..moveTo(center.dx - zSize, center.dy - zSize)
      ..lineTo(center.dx + zSize, center.dy - zSize)
      ..lineTo(center.dx - zSize, center.dy + zSize)
      ..lineTo(center.dx + zSize, center.dy + zSize);

    // Sombra vermelha de alerta
    canvas.drawPath(
      zPath.shift(const Offset(2.5, 2.5)),
      Paint()
        ..color = ProtocoloZColors.hordeRed
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = size.width * 0.065,
    );

    // Traço principal verde radar
    canvas.drawPath(
      zPath,
      Paint()
        ..color = ProtocoloZColors.radarGreen
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = size.width * 0.055,
    );

    // Blips vermelhos pulsantes (horda no radar)
    final blipOffset = Offset(
      center.dx + radius * 0.48 * math.cos(progress * 2 * math.pi + 1.1),
      center.dy + radius * 0.48 * math.sin(progress * 2 * math.pi + 1.1),
    );
    canvas.drawCircle(
      blipOffset,
      4.5,
      Paint()..color = ProtocoloZColors.hordeRed,
    );
  }

  @override
  bool shouldRepaint(covariant _Logo2DPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// 2. Cena 2D Animada de Expedição (Sobrevivente, Ruínas Cinzas, Radar Verde e Zumbis Vermelhos)
class ExpeditionScene2D extends StatefulWidget {
  final String riskLevel; // 'baixo', 'medio', 'alto'
  final String placeName;
  final bool isActive;
  final double progress;

  const ExpeditionScene2D({
    super.key,
    required this.riskLevel,
    required this.placeName,
    required this.isActive,
    this.progress = 0.0,
  });

  @override
  State<ExpeditionScene2D> createState() => _ExpeditionScene2DState();
}

class _ExpeditionScene2DState extends State<ExpeditionScene2D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            return CustomPaint(
              painter: _ExpeditionScenePainter(
                tick: _anim.value,
                riskLevel: widget.riskLevel,
                isActive: widget.isActive,
                progress: widget.progress,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ProtocoloZColors.bgDarkest.withValues(
                              alpha: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: widget.isActive
                                  ? ProtocoloZColors.radarGreen
                                  : ProtocoloZColors.borderGray,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.isActive
                                    ? Icons.directions_run_rounded
                                    : Icons.radar_rounded,
                                size: 14,
                                color: widget.isActive
                                    ? ProtocoloZColors.radarGreen
                                    : ProtocoloZColors.steelGray,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.isActive
                                    ? 'EM CAMPO: ${widget.placeName.toUpperCase()}'
                                    : 'ZONA DE COLETA 2D: ${widget.placeName.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: ProtocoloZColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.riskLevel == 'alto'
                                ? ProtocoloZColors.crimsonRed.withValues(
                                    alpha: 0.85,
                                  )
                                : widget.riskLevel == 'medio'
                                ? ProtocoloZColors.cardGray.withValues(
                                    alpha: 0.9,
                                  )
                                : ProtocoloZColors.tacticalGreen.withValues(
                                    alpha: 0.85,
                                  ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'RISCO ${widget.riskLevel.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.isActive)
                      LinearProgressIndicator(
                        value: widget.progress.clamp(0.05, 1.0),
                        backgroundColor: ProtocoloZColors.bgDarkest,
                        color: ProtocoloZColors.radarGreen,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ExpeditionScenePainter extends CustomPainter {
  final double tick;
  final String riskLevel;
  final bool isActive;
  final double progress;

  _ExpeditionScenePainter({
    required this.tick,
    required this.riskLevel,
    required this.isActive,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Céu noturno cinza/esverdeado ou avermelhado conforme risco
    final skyTop = riskLevel == 'alto'
        ? const Color(0xFF2A1013)
        : const Color(0xFF101915);
    final skyBottom = const Color(0xFF1A2420);

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skyTop, skyBottom],
        ).createShader(Offset.zero & size),
    );

    // Lua / Sol contaminado ao fundo
    final moonColor = riskLevel == 'alto'
        ? ProtocoloZColors.hordeRed.withValues(alpha: 0.25)
        : ProtocoloZColors.radarGreen.withValues(alpha: 0.18);
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.32),
      22,
      Paint()..color = moonColor,
    );

    // Silhuetas de prédios em ruínas 2D (Cinza Escuro)
    final buildingPaint = Paint()..color = const Color(0xFF141B18);
    final windowPaint = Paint()
      ..color = ProtocoloZColors.radarGreen.withValues(alpha: 0.22);

    final buildings = [
      Rect.fromLTWH(size.width * 0.04, size.height * 0.35, 42, size.height),
      Rect.fromLTWH(size.width * 0.18, size.height * 0.48, 50, size.height),
      Rect.fromLTWH(size.width * 0.38, size.height * 0.28, 56, size.height),
      Rect.fromLTWH(size.width * 0.62, size.height * 0.42, 48, size.height),
      Rect.fromLTWH(size.width * 0.80, size.height * 0.36, 52, size.height),
    ];

    for (final b in buildings) {
      canvas.drawRect(b, buildingPaint);
      // Janelas acesas em verde
      for (double wy = b.top + 8; wy < size.height - 32; wy += 14) {
        for (double wx = b.left + 6; wx < b.right - 10; wx += 12) {
          if (((wx + wy).toInt() % 3) == 0) {
            canvas.drawRect(Rect.fromLTWH(wx, wy, 5, 7), windowPaint);
          }
        }
      }
    }

    // Solo / Estrada Cinza
    final groundY = size.height - 26;
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, 26),
      Paint()..color = const Color(0xFF0C100E),
    );
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.width, groundY),
      Paint()
        ..color = ProtocoloZColors.borderGray
        ..strokeWidth = 1.5,
    );

    // Sobrevivente 2D (Verde Tático) caminhando
    final survivorX = isActive
        ? (size.width * 0.15) + (size.width * 0.55 * progress.clamp(0.0, 1.0))
        : size.width * 0.25;
    final bounce = isActive ? math.sin(tick * 2 * math.pi * 2) * 2.5 : 0.0;
    final sy = groundY - 14 + bounce;

    // Lanterna tática (cone de luz verde)
    final beamPath = Path()
      ..moveTo(survivorX + 4, sy - 2)
      ..lineTo(survivorX + 68, sy - 20)
      ..lineTo(survivorX + 68, sy + 12)
      ..close();
    canvas.drawPath(
      beamPath,
      Paint()
        ..color = ProtocoloZColors.radarGreen.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );

    // Corpo 2D do sobrevivente
    final survPaint = Paint()
      ..color = ProtocoloZColors.radarGreen
      ..style = PaintingStyle.fill;
    // Cabeça
    canvas.drawCircle(Offset(survivorX, sy - 10), 4.5, survPaint);
    // Mochila tática
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(survivorX - 7, sy - 5, 5, 10),
        const Radius.circular(2),
      ),
      Paint()..color = ProtocoloZColors.steelGray,
    );
    // Tronco
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(survivorX - 3, sy - 5, 6, 11),
        const Radius.circular(2),
      ),
      survPaint,
    );
    // Pernas animadas
    final legSwing = isActive ? math.sin(tick * 2 * math.pi * 2) * 4 : 1.5;
    final legPaint = Paint()
      ..color = ProtocoloZColors.radarGreen
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(survivorX, sy + 5),
      Offset(survivorX - legSwing, groundY),
      legPaint,
    );
    canvas.drawLine(
      Offset(survivorX, sy + 5),
      Offset(survivorX + legSwing, groundY),
      legPaint,
    );

    // Silhuetas 2D de Zumbis (Vermelho Alerta) à direita
    final zombieCount = riskLevel == 'alto'
        ? 3
        : riskLevel == 'medio'
        ? 2
        : 1;
    for (int z = 0; z < zombieCount; z++) {
      final zx =
          size.width * 0.88 -
          (z * 18) -
          (math.sin((tick + z * 0.3) * 2 * math.pi) * 4);
      final zy = groundY - 12;
      final zPaint = Paint()
        ..color = ProtocoloZColors.hordeRed.withValues(alpha: 0.85);
      // Cabeça inclinada do zumbi
      canvas.drawCircle(Offset(zx - 1.5, zy - 9), 4.0, zPaint);
      // Tronco
      canvas.drawLine(
        Offset(zx, zy - 5),
        Offset(zx + 2, zy + 5),
        Paint()
          ..color = ProtocoloZColors.crimsonRed
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
      // Braços estendidos para frente
      canvas.drawLine(
        Offset(zx, zy - 4),
        Offset(zx - 8, zy - 2),
        Paint()
          ..color = ProtocoloZColors.hordeRed
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
      // Pernas
      canvas.drawLine(
        Offset(zx + 2, zy + 5),
        Offset(zx - 1, groundY),
        Paint()
          ..color = ProtocoloZColors.crimsonRed
          ..strokeWidth = 2.2,
      );
      canvas.drawLine(
        Offset(zx + 2, zy + 5),
        Offset(zx + 5, groundY),
        Paint()
          ..color = ProtocoloZColors.crimsonRed
          ..strokeWidth = 2.2,
      );
    }

    // Partículas de esporos/cinzas flutuando
    for (int p = 0; p < 10; p++) {
      final px = ((p * 37 + tick * 80) % size.width);
      final py = ((p * 19 + math.sin(tick * 2 * math.pi + p) * 10) % groundY);
      canvas.drawCircle(
        Offset(px, py),
        1.4,
        Paint()
          ..color = (p.isEven
                  ? ProtocoloZColors.radarGreen
                  : ProtocoloZColors.steelGray)
              .withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ExpeditionScenePainter oldDelegate) => true;
}

/// 3. Radar Tático 2D Interativo na Home mostrando Abrigos (Verde) e Hordas (Vermelho)
class TacticalRadar2D extends StatefulWidget {
  final List<ShelterModel> shelters;
  final List<HordeAlertModel> alerts;
  final VoidCallback? onTap;

  const TacticalRadar2D({
    super.key,
    required this.shelters,
    required this.alerts,
    this.onTap,
  });

  @override
  State<TacticalRadar2D> createState() => _TacticalRadar2DState();
}

class _TacticalRadar2DState extends State<TacticalRadar2D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            size: const Size(86, 86),
            painter: _Radar2DPainter(
              angle: _ctrl.value * 2 * math.pi,
              sheltersCount: widget.shelters.length,
              alertsCount: widget.alerts.length,
            ),
          );
        },
      ),
    );
  }
}

class _Radar2DPainter extends CustomPainter {
  final double angle;
  final int sheltersCount;
  final int alertsCount;

  _Radar2DPainter({
    required this.angle,
    required this.sheltersCount,
    required this.alertsCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;

    canvas.drawCircle(
      center,
      r,
      Paint()..color = ProtocoloZColors.bgDarkest,
    );

    final gridPaint = Paint()
      ..color = ProtocoloZColors.radarGreen.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, r, gridPaint);
    canvas.drawCircle(center, r * 0.65, gridPaint);
    canvas.drawCircle(center, r * 0.32, gridPaint);
    canvas.drawLine(
      Offset(center.dx - r, center.dy),
      Offset(center.dx + r, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - r),
      Offset(center.dx, center.dy + r),
      gridPaint,
    );

    // Feixe verde
    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawArc(
      rect,
      angle,
      math.pi / 2.2,
      true,
      Paint()
        ..shader = SweepGradient(
          colors: [
            ProtocoloZColors.radarGreen.withValues(alpha: 0.0),
            ProtocoloZColors.radarGreen.withValues(alpha: 0.45),
          ],
          startAngle: 0,
          endAngle: math.pi / 2.2,
          transform: GradientRotation(angle),
        ).createShader(rect),
    );

    // Pontos verdes (abrigos)
    for (int i = 0; i < math.min(sheltersCount, 5); i++) {
      final a = (i * 1.3) + 0.4;
      final d = r * (0.35 + (i % 3) * 0.18);
      canvas.drawCircle(
        Offset(center.dx + d * math.cos(a), center.dy + d * math.sin(a)),
        3.2,
        Paint()..color = ProtocoloZColors.radarGreen,
      );
    }

    // Pontos vermelhos (hordas)
    for (int i = 0; i < math.min(alertsCount, 5); i++) {
      final a = (i * 1.7) + 2.1;
      final d = r * (0.45 + (i % 2) * 0.25);
      canvas.drawCircle(
        Offset(center.dx + d * math.cos(a), center.dy + d * math.sin(a)),
        4.0,
        Paint()..color = ProtocoloZColors.hordeRed,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Radar2DPainter oldDelegate) => true;
}

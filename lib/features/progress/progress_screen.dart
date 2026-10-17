import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../app/theme.dart';
import '../../models/assessment.dart';
import '../../models/records.dart';
import '../../services/storage_service.dart';
import '../../widgets/common.dart';
import '../../widgets/plan_widgets.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final log = List<PainLogEntry>.of(c.painLog)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final recent = log.length > 30 ? log.sublist(log.length - 30) : log;
    final records = c.records.reversed.toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text('Progress',
            style: text.headlineSmall?.copyWith(
                color: AppColors.deepBlue, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        const SectionTitle('Today'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const HydrationTracker(),
              const SizedBox(height: 4),
              Text('Exercises marked done today: '
                  '${c.completions[c.todayKey]?.length ?? 0}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionTitle('Log your pain today'),
        AppCard(child: _PainLogger(controller: c)),
        const SizedBox(height: 16),
        const SectionTitle('Pain trend'),
        AppCard(
          child: recent.length < 2
              ? const Text('Log your pain on at least two occasions to see a '
                  'trend. Scores are self-reported.')
              : SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _TrendPainter(
                      recent.map((e) => e.score).toList(),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        const SectionTitle('Previous assessments'),
        if (records.isEmpty)
          const AppCard(child: Text('No assessments saved yet.'))
        else
          for (final r in records) _RecordTile(record: r, controller: c),
        const SizedBox(height: 20),
        const DisclaimerBanner(),
      ],
    );
  }
}

class _PainLogger extends StatefulWidget {
  const _PainLogger({required this.controller});
  final AppController controller;

  @override
  State<_PainLogger> createState() => _PainLoggerState();
}

class _PainLoggerState extends State<_PainLogger> {
  int? _score;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SingleChoiceChips<int>(
          options: <int>[
            for (var i = kMinPainIntensity; i <= kMaxPainIntensity; i++) i,
          ],
          value: _score,
          labelOf: (i) => '$i',
          onChanged: (v) => setState(() => _score = v),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _score == null
              ? null
              : () async {
                  await widget.controller.logPain(_score!);
                  if (!mounted) return;
                  setState(() => _score = null);
                },
          child: const Text('Save score'),
        ),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record, required this.controller});

  final AssessmentRecord record;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final region = record.assessment.regionId == null
        ? null
        : controller.anatomy.byId(record.assessment.regionId!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(region?.label ?? 'Unknown area',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${dateKey(record.createdAt)} · pain '
                      '${record.assessment.painIntensity ?? '-'} · '
                      '${record.safetyStateId.replaceAll('_', ' ')}'),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Delete this assessment',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => controller.deleteRecord(record.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.scores);
  final List<int> scores;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axis);
    canvas.drawLine(Offset.zero, Offset(0, size.height), axis);
    if (scores.length < 2) return;
    final line = Paint()
      ..color = AppColors.teal
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = AppColors.deepBlue;
    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i < scores.length; i++) {
      final x = size.width * i / (scores.length - 1);
      final y = size.height * (1 - scores[i] / kMaxPainIntensity);
      final p = Offset(x, y);
      points.add(p);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, line);
    for (final p in points) {
      canvas.drawCircle(p, 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.scores != scores;
}

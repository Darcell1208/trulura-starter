import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/services/reporting_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/trulura_glass_app_bar.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';

class ReportScreen extends StatefulWidget {
  final TruSafetyTargetType targetType;
  final String targetId;

  const ReportScreen({super.key, required this.targetType, required this.targetId});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  TruReportReason _reason = TruReportReason.harassment;
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final now = DateTime.now();
      final report = TruSafetyReport(
        id: 'r_${now.microsecondsSinceEpoch}',
        targetType: widget.targetType,
        targetId: widget.targetId,
        reason: _reason,
        details: _controller.text.trim().isEmpty ? null : _controller.text.trim(),
        createdAt: now,
      );
      await ReportingService().submitReport(report);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted. Thank you.')));
      context.pop();
    } catch (e) {
      debugPrint('ReportScreen._submit failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Couldn\'t submit report. Try again.')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TruLuraGlassAppBar(
        mode: TruLuraMode.aura,
        showBack: true,
        title: 'Report',
      ),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        mode: TruLuraMode.aura,
        padding: const EdgeInsets.only(top: 86),
        child: ListView(
          padding: AppSpacing.paddingMd,
          children: [
            Text('Your report is confidential. We\'ll use it to protect you and others.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.4)),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: 22,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reason', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<TruReportReason>(
                      value: _reason,
                      isExpanded: true,
                      items: TruReportReason.values.map((v) => DropdownMenuItem(value: v, child: Text(v.label))).toList(),
                      onChanged: (v) => setState(() => _reason = v ?? _reason),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Details (optional)', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(hintText: 'What happened? Include context if helpful.'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: Text(_submitting ? 'Submitting…' : 'Submit report'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common.dart';

final speechInputProvider = Provider<SpeechInput>((ref) => SpeechInput());

/// Cihazın konuşma tanıma motoru (speech_to_text) üzerinde ince bir katman.
class SpeechInput {
  final _stt = SpeechToText();
  bool? _available;

  Future<bool> ensureReady() async {
    _available ??= await _stt.initialize(onError: (_) {}, onStatus: (_) {});
    return _available!;
  }

  bool get isListening => _stt.isListening;

  Future<bool> start({required String localeId, required void Function(String text, bool isFinal) onResult}) async {
    if (!await ensureReady()) return false;
    await _stt.listen(
      listenOptions: SpeechListenOptions(localeId: localeId, partialResults: true, cancelOnError: true),
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
    );
    return true;
  }

  Future<void> stop() => _stt.stop();

  /// Dinleme sayfasını açar, konuşma bitince tanınan metni döner.
  Future<String?> listenOnce(BuildContext context, {required String localeId}) async {
    if (!await ensureReady()) {
      if (context.mounted) showMessage(context, 'Bu cihazda konuşma tanıma kullanılamıyor.');
      return null;
    }
    if (!context.mounted) return null;
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLg))),
      builder: (_) => _ListeningSheet(input: this, localeId: localeId),
    );
  }
}

class _ListeningSheet extends StatefulWidget {
  const _ListeningSheet({required this.input, required this.localeId});
  final SpeechInput input;
  final String localeId;

  @override
  State<_ListeningSheet> createState() => _ListeningSheetState();
}

class _ListeningSheetState extends State<_ListeningSheet> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  String _text = '';

  @override
  void initState() {
    super.initState();
    widget.input.start(
      localeId: widget.localeId,
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() => _text = text);
        if (isFinal) Navigator.pop(context, text);
      },
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    widget.input.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, _) => Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80 + 60 * _pulse.value,
                      height: 80 + 60 * _pulse.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryContainer.withValues(alpha: 0.25 * (1 - _pulse.value)),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        boxShadow: AppShadows.button(),
                      ),
                      child: const Icon(Symbols.mic, size: 36, color: AppColors.tertiaryFixed),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Dinliyor...', style: AppTextStyles.headlineSm),
            const SizedBox(height: AppSpacing.xs),
            Text(_text.isEmpty ? 'Konuşmaya başla' : _text, textAlign: TextAlign.center, style: AppTextStyles.bodyLg.variant),
            const SizedBox(height: AppSpacing.lg),
            SoftButton(label: 'Bitir', icon: Symbols.stop, onPressed: () => Navigator.pop(context, _text)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../test_templates/domain/test_template_models.dart';

class KoreanActivityView extends StatefulWidget {
  const KoreanActivityView(
      {required this.question,
      required this.currentQuestion,
      required this.totalQuestions,
      required this.onAnswered,
      this.onDraft,
      this.savedAnswer,
      super.key});
  final TemplateQuestion question;
  final int currentQuestion;
  final int totalQuestions;
  final ValueChanged<Map<String, dynamic>> onAnswered;
  final ValueChanged<Map<String, dynamic>>? onDraft;
  final Map<String, dynamic>? savedAnswer;
  @override
  State<KoreanActivityView> createState() => _KoreanActivityViewState();
}

class _KoreanActivityViewState extends State<KoreanActivityView> {
  static const _speech =
      MethodChannel('com.balebelajar.bale_belajar_app/korean_speech');
  final _text = TextEditingController();
  String? _selected;
  String? _error;
  bool _heard = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    final saved = widget.savedAnswer ?? widget.question.savedAnswer;
    _text.text = saved?['text'] as String? ?? '';
    _selected = saved?['selectedOptionId'] as String?;
    _heard = _selected != null;
  }

  Future<void> _play() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      await _speech.invokeMethod<bool>(
          'speak', {'text': widget.question.media?.transcript ?? ''});
      if (mounted) setState(() => _heard = true);
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _error = error.message ??
            'Suara Korea belum tersedia. Instal voice pack Korea di pengaturan Text-to-speech Android.');
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() => _error =
            'Listening ini tersedia di aplikasi Android dengan voice pack Korea.');
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _stop() async {
    try {
      await _speech.invokeMethod<void>('stop');
    } catch (_) {/* Platform may not provide Korean speech. */}
  }

  @override
  void dispose() {
    _stop();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listening = widget.question.questionType == QuestionType.audioChoice;
    final choosing =
        listening || widget.question.questionType == QuestionType.singleChoice;
    final minMatch =
        RegExp(r'Tulis (\d+)').firstMatch(widget.question.instruction ?? '');
    final min = int.tryParse(minMatch?.group(1) ?? '') ?? 1;
    final max = widget.question.responseConfig?.maxLength ?? 700;
    final length = _text.text.trim().runes.length;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3C6),
      appBar: AppBar(
          title: Text(
              '${listening ? 'Listening' : choosing ? 'Reading' : 'Writing'} · ${widget.currentQuestion}/${widget.totalQuestions}')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(widget.question.prompt,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(widget.question.instruction ?? ''),
        const SizedBox(height: 20),
        if (choosing) ...[
          if (listening) ...[
            const Text(
                'Suara sintetis Korea dari perangkat. Dengarkan sebelum memilih jawaban.'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: FilledButton.icon(
                      onPressed: _starting ? null : _play,
                      icon: const Icon(Icons.volume_up),
                      label: Text(
                          _starting ? 'Menyiapkan suara…' : 'Putar / ulangi'))),
              IconButton(
                  onPressed: _stop,
                  icon: const Icon(Icons.stop),
                  tooltip: 'Hentikan suara'),
            ]),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          ...widget.question.options.map((option) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: OutlinedButton(
                    onPressed: !listening || _heard
                        ? () {
                            setState(() => _selected = option.id);
                            widget.onDraft
                                ?.call({'selectedOptionId': option.id});
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                        backgroundColor: _selected == option.id
                            ? Colors.amber.shade200
                            : Colors.white),
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(option.label))),
              )),
        ] else ...[
          TextField(
              controller: _text,
              minLines: 8,
              maxLines: 18,
              maxLength: max,
              onChanged: (_) {
                setState(() {});
                widget.onDraft?.call({'text': _text.text.trim()});
              },
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  hintText: 'Tulis jawaban dalam bahasa Korea…')),
          Text('$length karakter termasuk spasi · minimal $min'),
          const SizedBox(height: 8),
          const Text(
              'Jawaban dinilai dengan rubrik oleh reviewer. Lesson belum lulus sampai penilaian selesai.'),
        ],
        const SizedBox(height: 20),
        FilledButton(
            onPressed: choosing
                ? (_selected == null
                    ? null
                    : () {
                        _stop();
                        widget.onAnswered({'selectedOptionId': _selected});
                      })
                : (length < min || length > max
                    ? null
                    : () => widget.onAnswered({'text': _text.text.trim()})),
            child: const Text('Simpan jawaban')),
      ]),
    );
  }
}

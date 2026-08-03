import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class PebbleHarraPage extends StatefulWidget {
  const PebbleHarraPage({super.key});

  @override
  State<PebbleHarraPage> createState() => _PebbleHarraPageState();
}

class _PebbleHarraPageState extends State<PebbleHarraPage> {
  final Random _random = Random();
  final List<int> _pits = List<int>.filled(14, 7);
  final List<int> _scores = <int>[0, 0];
  bool _againstBot = true;
  bool _busy = false;
  int _player = 0;
  int? _activePit;
  String _message = 'اختر جورة من صفك';

  bool _isPlayerPit(int index, int player) => player == 0 ? index >= 0 && index < 7 : index >= 7;
  String get _playerName => _againstBot && _player == 1 ? 'الروبوت' : 'اللاعب ${_player + 1}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showInstructions();
    });
  }

  void _reset() {
    setState(() {
      for (var i = 0; i < 14; i++) {
        _pits[i] = 7;
      }
      _scores[0] = 0;
      _scores[1] = 0;
      _player = 0;
      _busy = false;
      _activePit = null;
      _message = 'اختر جورة من صفك';
    });
    SoundService.instance.play('click.wav');
  }

  void _setMode(bool againstBot) {
    if (_againstBot == againstBot) return;
    _againstBot = againstBot;
    _reset();
  }

  void _showInstructions() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _HarraInstructions(),
    );
  }

  Future<void> _choosePit(int pit) async {
    if (_busy || !_isPlayerPit(pit, _player) || _pits[pit] == 0) {
      if (!_busy) SoundService.instance.play('wrong.wav');
      return;
    }
    setState(() {
      _busy = true;
      _activePit = pit;
      _message = 'يتم توزيع الجلول عكس عقارب الساعة';
    });

    var current = pit;
    var hand = _pits[current];
    setState(() => _pits[current] = 0);

    while (true) {
      while (hand > 0) {
        current = (current + 1) % 14;
        await Future<void>.delayed(const Duration(milliseconds: 115));
        if (!mounted) return;
        setState(() {
          _pits[current]++;
          _activePit = current;
        });
        SoundService.instance.play('tap.wav');
        hand--;
      }

      final landed = _pits[current];
      if (landed >= 3) {
        await Future<void>.delayed(const Duration(milliseconds: 230));
        if (!mounted) return;
        hand = landed;
        setState(() {
          _pits[current] = 0;
          _message = 'الجورة فيها $landed جلول — تابع التوزيع';
        });
        continue;
      }
      if (landed == 2) {
        setState(() {
          _scores[_player] += 2;
          _pits[current] = 0;
          _message = 'زوج! جمعت جلّين';
        });
        await SoundService.instance.play('pop.wav');
      } else {
        setState(() => _message = 'قرعة — انتهى الدور');
      }
      break;
    }

    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    if (_pits.every((value) => value == 0) || _pits.where((value) => value > 0).length == 1) {
      await _finishGame();
      return;
    }
    setState(() {
      _player = 1 - _player;
      _busy = false;
      _activePit = null;
      _message = 'دور $_playerName: اختر جورة من صفك';
    });
    if (_againstBot && _player == 1) _playBot();
  }

  void _playBot() {
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || !_againstBot || _player != 1 || _busy) return;
      final choices = <int>[for (var i = 7; i < 14; i++) if (_pits[i] > 0) i];
      if (choices.isEmpty) {
        _finishGame();
        return;
      }
      choices.sort((a, b) => _pits[b].compareTo(_pits[a]));
      final limit = min(3, choices.length);
      _choosePit(choices[_random.nextInt(limit)]);
    });
  }

  Future<void> _finishGame() async {
    for (var i = 0; i < 14; i++) {
      if (_pits[i] > 0) {
        _scores[i < 7 ? 0 : 1] += _pits[i];
        _pits[i] = 0;
      }
    }
    final winner = _scores[0] == _scores[1] ? -1 : (_scores[0] > _scores[1] ? 0 : 1);
    setState(() {
      _busy = true;
      _activePit = null;
      _message = winner == -1 ? 'تعادل!' : 'فاز ${winner == 1 && _againstBot ? 'الروبوت' : 'اللاعب ${winner + 1}'}';
    });
    if (winner == 0) await ScoreService.instance.addStars(3);
    await SoundService.instance.play(winner == 0 ? 'win.wav' : 'pop.wav');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحُرّة: الجور والجلول'),
        actions: <Widget>[
          IconButton(tooltip: 'طريقة اللعب', onPressed: _showInstructions, icon: const Icon(Icons.help_outline_rounded)),
          IconButton(onPressed: _reset, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(children: <Widget>[
          _HarraHeader(playerName: _playerName, player: _player, message: _message, scores: _scores),
          const SizedBox(height: 8),
          Row(children: <Widget>[
            Expanded(child: ChoiceChip(label: const Text('ضد الروبوت'), selected: _againstBot, onSelected: (_) => _setMode(true))),
            const SizedBox(width: 8),
            Expanded(child: ChoiceChip(label: const Text('مع صديق'), selected: !_againstBot, onSelected: (_) => _setMode(false))),
          ]),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 18, 10, 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: <Color>[Color(0xFFD6A15A), Color(0xFF8B5A2B)]),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF6B3F1D), width: 4),
                  boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x55000000), blurRadius: 16, offset: Offset(0, 9))],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  const _SideLabel(text: 'صف اللاعب 2 / الروبوت', color: Color(0xFF2563EB)),
                  const SizedBox(height: 7),
                  _PitRow(indices: const <int>[13, 12, 11, 10, 9, 8, 7], pits: _pits, activePit: _activePit, enabled: !_busy && _player == 1, color: const Color(0xFF2563EB), onTap: _choosePit),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Divider(color: Color(0x99FFF7ED), thickness: 2)),
                  _PitRow(indices: const <int>[0, 1, 2, 3, 4, 5, 6], pits: _pits, activePit: _activePit, enabled: !_busy && _player == 0, color: const Color(0xFFDC2626), onTap: _choosePit),
                  const SizedBox(height: 7),
                  const _SideLabel(text: 'صف اللاعب 1', color: Color(0xFFDC2626)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 9),
          const _RuleBanner(),
        ]),
      ),
    );
  }
}

class _PitRow extends StatelessWidget {
  const _PitRow({required this.indices, required this.pits, required this.activePit, required this.enabled, required this.color, required this.onTap});
  final List<int> indices;
  final List<int> pits;
  final int? activePit;
  final bool enabled;
  final Color color;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      for (final index in indices)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: enabled ? () => onTap(index) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B371D),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: activePit == index ? const Color(0xFFFFD54F) : enabled ? color : const Color(0xFF3F2717), width: activePit == index ? 4 : 2),
                  boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x66000000), blurRadius: 5, offset: Offset(0, 3), blurStyle: BlurStyle.inner)],
                ),
                child: Center(child: _Marbles(count: pits[index], color: color)),
              ),
            ),
          ),
        ),
    ]);
  }
}

class _Marbles extends StatelessWidget {
  const _Marbles({required this.count, required this.color});
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const Text('فارغة', style: TextStyle(color: Colors.white54, fontSize: 8));
    return Stack(alignment: Alignment.center, children: <Widget>[
      for (var i = 0; i < min(count, 9); i++)
        Transform.translate(
          offset: Offset(((i % 3) - 1) * 9.0, ((i ~/ 3) - 1) * 9.0),
          child: Container(width: 13, height: 13, decoration: BoxDecoration(shape: BoxShape.circle, color: Color.lerp(color, Colors.white, (i % 3) * .13), border: Border.all(color: Colors.white70), boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black38, blurRadius: 2, offset: Offset(0, 1))])),
        ),
      if (count > 9) Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(9)), child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
    ]);
  }
}

class _HarraHeader extends StatelessWidget {
  const _HarraHeader({required this.playerName, required this.player, required this.message, required this.scores});
  final String playerName;
  final int player;
  final String message;
  final List<int> scores;

  @override
  Widget build(BuildContext context) {
    final color = player == 0 ? const Color(0xFFDC2626) : const Color(0xFF2563EB);
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: <Color>[Color(0xFF78350F), Color(0xFFD97706)])),
      child: Row(children: <Widget>[
        CircleAvatar(radius: 24, backgroundColor: Colors.white, child: Icon(Icons.circle, color: color, size: 30)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text('دور $playerName', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.w900, fontSize: 20)),
          Text(message, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFFFF7D6), fontWeight: FontWeight.w700, fontSize: 12)),
          Text('المجموع: اللاعب 1  ${scores[0]}  •  اللاعب 2  ${scores[1]}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ])),
      ]),
    );
  }
}

class _SideLabel extends StatelessWidget {
  const _SideLabel({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[Icon(Icons.circle, color: color, size: 12), const SizedBox(width: 5), Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12))]);
}

class _RuleBanner extends StatelessWidget {
  const _RuleBanner();
  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFF59E0B))),
    child: const Row(children: <Widget>[Icon(Icons.touch_app_rounded, color: Color(0xFFB45309)), SizedBox(width: 8), Expanded(child: Text('اضغط جورة من صفك، وسيتم توزيع الجلول واحدةً واحدة عكس عقارب الساعة.', maxLines: 2, style: TextStyle(color: Color(0xFF78350F), fontWeight: FontWeight.w800, fontSize: 12)))]),
  );
}

class _HarraInstructions extends StatelessWidget {
  const _HarraInstructions();
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        const Text('كيف تلعب الجور والجلول؟', style: TextStyle(fontFamily: 'Changa', fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        const _Instruction(number: '1', title: '14 جورة و98 جلّاً', text: 'لكل لاعب صف من 7 جور، وتبدأ كل جورة وفيها 7 جلول.'),
        const _Instruction(number: '2', title: 'اختر جورة من صفك', text: 'تُرفع كل الجلول منها وتوزّع واحدةً واحدة عكس عقارب الساعة.'),
        const _Instruction(number: '3', title: 'تابع أو توقف', text: 'إذا انتهيت في جورة فيها 3 جلول أو أكثر، تحملها وتتابع. الجلّ المنفرد هو القرعة وينهي الدور.'),
        const _Instruction(number: '4', title: 'اجمع الأزواج', text: 'إذا انتهى التوزيع بجلّين في الجورة تجمعهما. الفائز من يجمع جلولاً أكثر.'),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.play_arrow_rounded), label: const Text('فهمت — ابدأ اللعب'))),
      ]),
    ),
  );
}

class _Instruction extends StatelessWidget {
  const _Instruction({required this.number, required this.title, required this.text});
  final String number;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      CircleAvatar(radius: 18, backgroundColor: const Color(0xFFD97706), child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(text, style: const TextStyle(color: Color(0xFF57534E), fontSize: 12, height: 1.4))])),
    ]),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'games/letter_bubbles_page.dart';
import 'games/sliding_puzzle_page.dart';
import 'games/tic_tac_toe_page.dart';
import 'screens/developer_page.dart';
import 'screens/home_page.dart';
import 'services/sound_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoundService.instance.init();
  runApp(const KidsGamesArenaApp());
}

class KidsGamesArenaApp extends StatelessWidget {
  const KidsGamesArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ملعب الأطفال',
      locale: const Locale('ar'),
      supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: GamesHome(),
      ),
    );
  }
}

class GamesHome extends StatefulWidget {
  const GamesHome({super.key});

  @override
  State<GamesHome> createState() => _GamesHomeState();
}

class _GamesHomeState extends State<GamesHome> {
  int tab = 0;

  void _selectTab(int index) {
    SoundService.instance.play('click.wav');
    setState(() => tab = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      HomeGamesPage(onSelectGame: _selectTab),
      const TicTacToePage(),
      const SlidingPuzzlePage(),
      const BubbleLettersPage(),
      const DeveloperPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ملعب الأطفال'),
        actions: <Widget>[
          ValueListenableBuilder<bool>(
            valueListenable: SoundService.instance.mutedNotifier,
            builder: (BuildContext context, bool muted, Widget? child) {
              return IconButton(
                tooltip: muted ? 'تشغيل الصوت' : 'كتم الصوت',
                icon: Icon(muted ? Icons.volume_off_rounded : Icons.volume_up_rounded),
                onPressed: () => SoundService.instance.toggleMute(),
              );
            },
          ),
        ],
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: _selectTab,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_3x3_outlined),
            selectedIcon: Icon(Icons.grid_3x3_rounded),
            label: 'إكس أو',
          ),
          NavigationDestination(
            icon: Icon(Icons.extension_outlined),
            selectedIcon: Icon(Icons.extension_rounded),
            label: 'البزل',
          ),
          NavigationDestination(
            icon: Icon(Icons.bubble_chart_outlined),
            selectedIcon: Icon(Icons.bubble_chart_rounded),
            label: 'الحروف',
          ),
          NavigationDestination(
            icon: Icon(Icons.mail_outline_rounded),
            selectedIcon: Icon(Icons.mail_rounded),
            label: 'المطور',
          ),
        ],
      ),
    );
  }
}

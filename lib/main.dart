import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'status.dart';
import 'card.dart';
import 'settings.dart';
import 'mcl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final seedColor = await AccentColorFetcher.getAccentColor();
  runApp(MyApp(seedColor));
}

class MyApp extends StatefulWidget {
  final Color seedColor;
  const MyApp(this.seedColor, {super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Brightness _platformBrightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  ColorScheme _getColorScheme(Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: widget.seedColor,
      brightness: brightness,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {
      _platformBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightColorScheme = _getColorScheme(Brightness.light);
    final darkColorScheme = _getColorScheme(Brightness.dark);
    final useDark = _platformBrightness == Brightness.dark;


    return MaterialApp(
      title: 'FMAC',
      theme: ThemeData(
        colorScheme: lightColorScheme,
        useMaterial3: true,
        pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: SharedAxisPageTransitionsBuilder(
          transitionType: SharedAxisTransitionType.scaled,
        ),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
        appBarTheme: AppBarTheme(
          backgroundColor: lightColorScheme.surface,
          foregroundColor: lightColorScheme.onSurface,
          systemOverlayStyle: SystemUiOverlayStyle(
            systemNavigationBarColor: lightColorScheme.surfaceVariant,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.surface,
          foregroundColor: darkColorScheme.onSurface,
          systemOverlayStyle: SystemUiOverlayStyle(
            systemNavigationBarColor: darkColorScheme.surfaceVariant,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
        ),
      ),
      themeMode: useDark ? ThemeMode.dark : ThemeMode.light,
      home: const MyHomePage(title: 'FMAC'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  final List<Widget Function()> _pageBuilders = [
    () => const KernelSUHomePageContent(key: PageStorageKey('home')),
    () => const SettingsPage(key: PageStorageKey('settings')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.restart_alt),
            tooltip: '重启选项',
            onSelected: (String value) {
              switch (value) {
                case 'reboot':
                  break;
                case 'recovery':
                  break;
                case 'bootloader':
                  break;
                case 'edl':
                  break;
              }
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(value: 'reboot', child: Text('重启')),
              PopupMenuItem(value: 'recovery', child: Text('重启到 Recovery')),
              PopupMenuItem(value: 'bootloader', child: Text('重启到 BootLoader')),
              PopupMenuItem(value: 'edl', child: Text('重启到 EDL')),
            ],
          ),
        ],
      ),
      body: PageStorage(
        bucket: PageStorageBucket(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 125),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_selectedIndex),
            child: _pageBuilders[_selectedIndex](),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: colorScheme.surfaceVariant,
        indicatorColor: colorScheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '主页',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

class KernelSUHomePageContent extends StatefulWidget {
  const KernelSUHomePageContent({super.key});

  @override
  State<KernelSUHomePageContent> createState() =>
      _KernelSUHomePageContentState();
}

class _KernelSUHomePageContentState extends State<KernelSUHomePageContent>
    with AutomaticKeepAliveClientMixin {
  String _kernelVersion = '加载中...';
  String _SELinuxStatus = 'Loading';
  String _Fingerprint = 'Loading';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadKernelVersion();
    _getSELinuxStatusFallback();
    _getBuildFingerprint();
  }

  Future<void> _loadKernelVersion() async {
    final version = await getKernelVersion();
    if (mounted) {
      setState(() {
        _kernelVersion = version;
      });
    }
  }

  Future<void> _getBuildFingerprint() async {
    final version = await getBuildFingerprint();
    if (mounted) {
      setState(() {
        _Fingerprint = version;
      });
    }
  }

  Future<void> _getSELinuxStatusFallback() async {
    final version = await getSELinuxStatusFallback();
    if (mounted) {
      setState(() {
        _SELinuxStatus = version;
      });
    }
  }

  Future<void> launchWebUrl(String url) async {
    try {
      final uri = Uri.parse(url.trim());
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw '无法打开链接';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('无法打开链接: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      key: const PageStorageKey('home_scroll'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: colorScheme.errorContainer,
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '未安装',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '点击安装',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          InfoCard(
            title: '内核版本',
            children: [
              Text(_kernelVersion),
              const SizedBox(height: 16),
              Text('系统指纹', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_Fingerprint),
              const SizedBox(height: 16),
              Text(
                'SELinux 状态',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_SELinuxStatus),
            ],
          ),
          InfoCard(
            title: '支持开发',
            children: [Text('FMAC 将保持免费开源，向开发者捐赠以表示支持。')],
          ),
          InfoCard(
            title: '了解 FMAC',
            children: [Text('了解如何使用 FMAC')],
            onTap: () {
              launchWebUrl('https://github.com/aqnya/fmanager');
            },
          ),
        ],
      ),
    );
  }
}

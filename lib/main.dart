import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dynamic_color/dynamic_color.dart';   // 新增

// 以下为你原来的本地文件，保持不动
import 'status.dart';
import 'card.dart';
import 'settings.dart';
import 'mcl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

/* ==========================
 * 1. 用 DynamicColorBuilder 包裹
 * ========================== */
class App extends StatelessWidget {
  const App({super.key});

  // 备用色：取不到动态色就用它
  static const Color _fallbackSeed = Colors.indigo;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(                       // 官方插件提供
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightScheme = lightDynamic ?? ColorScheme.fromSeed(
              seedColor: _fallbackSeed,
              brightness: Brightness.light);
        final darkScheme = darkDynamic ?? ColorScheme.fromSeed(
              seedColor: _fallbackSeed,
              brightness: Brightness.dark);

        return ValueListenableBuilder<Brightness>(
          // 让下方 MyApp 继续监听系统亮度变化
          valueListenable: MyApp.brightnessListenable,
          builder: (_, brightness, __) {
            final useDark = brightness == Brightness.dark;
            return MaterialApp(
              title: 'FMAC',
              themeMode: useDark ? ThemeMode.dark : ThemeMode.light,
              theme: ThemeData(
                colorScheme: lightScheme,
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
                  backgroundColor: lightScheme.surface,
                  foregroundColor: lightScheme.onSurface,
                  systemOverlayStyle: SystemUiOverlayStyle(
                    systemNavigationBarColor: lightScheme.surfaceVariant,
                    systemNavigationBarIconBrightness: Brightness.dark,
                  ),
                ),
              ),
              darkTheme: ThemeData(
                colorScheme: darkScheme,
                useMaterial3: true,
                appBarTheme: AppBarTheme(
                  backgroundColor: darkScheme.surface,
                  foregroundColor: darkScheme.onSurface,
                  systemOverlayStyle: SystemUiOverlayStyle(
                    systemNavigationBarColor: darkScheme.surfaceVariant,
                    systemNavigationBarIconBrightness: Brightness.light,
                  ),
                ),
              ),
              home: const MyHomePage(title: 'FMAC'),
            );
          },
        );
      },
    );
  }
}

/* ==========================
 * 2. 原 MyApp 改名为 MyHomePage 壳子，只保留亮度监听
 * ========================== */
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // 暴露 Listenable 供 App 使用
  static final ValueNotifier<Brightness> brightnessListenable =
      ValueNotifier(WidgetsBinding.instance.platformDispatcher.platformBrightness);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
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
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    MyApp.brightnessListenable.value = brightness;   // 通知外层
  }

  @override
  Widget build(BuildContext context) {
    // 已经由外层 MaterialApp 处理主题，这里不需要再 build
    throw UnimplementedError('MyApp 仅作为亮度监听容器');
  }
}

/* ==========================
 * 3. 下方代码完全保持你原来逻辑
 * ========================== */
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
  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

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
            onSelected: (String value) {/* todo */},
            itemBuilder: (_) => const [
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
          layoutBuilder: (current, previous) => Stack(
            fit: StackFit.expand,
            children: [...previous, if (current != null) current],
          ),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0)
                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
          ),
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

/* ==========================
 * 4. KernelSUHomePageContent 原封不动
 * ========================== */
class KernelSUHomePageContent extends StatefulWidget {
  const KernelSUHomePageContent({super.key});
  @override
  State<KernelSUHomePageContent> createState() => _KernelSUHomePageContentState();
}

class _KernelSUHomePageContentState extends State<KernelSUHomePageContent>
    with AutomaticKeepAliveClientMixin {
  String _kernelVersion = '加载中...';
  String _selinuxStatus = 'Loading';
  String _fingerprint = 'Loading';

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
    final v = await getKernelVersion();
    if (mounted) setState(() => _kernelVersion = v);
  }

  Future<void> _getBuildFingerprint() async {
    final v = await getBuildFingerprint();
    if (mounted) setState(() => _fingerprint = v);
  }

  Future<void> _getSELinuxStatusFallback() async {
    final v = await getSELinuxStatusFallback();
    if (mounted) setState(() => _selinuxStatus = v);
  }

  Future<void> launchWebUrl(String url) async {
    try {
      if (!await launchUrl(Uri.parse(url.trim()),
          mode: LaunchMode.externalApplication)) throw '无法打开链接';
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('无法打开链接: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      key: const PageStorageKey('home_scroll'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: cs.errorContainer,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: cs.onErrorContainer),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('未安装',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: cs.onErrorContainer)),
                      const SizedBox(height: 4),
                      Text('点击安装',
                          style: TextStyle(
                              fontSize: 14, color: cs.onErrorContainer)),
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
              Text(_fingerprint),
              const SizedBox(height: 16),
              Text('SELinux 状态', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_selinuxStatus),
            ],
          ),
          InfoCard(
            title: '支持开发',
            children: [const Text('FMAC 将保持免费开源，向开发者捐赠以表示支持。')],
          ),
          InfoCard(
            title: '了解 FMAC',
            children: [const Text('了解如何使用 FMAC')],
            onTap: () => launchWebUrl('https://github.com/aqnya/nekosu'),
          ),
        ],
      ),
    );
  }
}

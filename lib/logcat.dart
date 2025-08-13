import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class LogcatPage extends StatefulWidget {
  const LogcatPage({super.key});

  @override
  State<LogcatPage> createState() => _LogcatPageState();
}

class _LogcatPageState extends State<LogcatPage> {
  final List<String> _logLines = [];
  final ScrollController _scrollController = ScrollController();
  Process? _logcatProcess;
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _startLogcat();
  }

  @override
  void dispose() {
    _logcatProcess?.kill();
    _scrollController.dispose();
    super.dispose();
  }

  void _startLogcat() async {
    setState(() => _isLoading = true);
    try {
      _logLines.clear();
      _logcatProcess = await Process.start(
        'logcat',
        ['-d', '-v', 'threadtime'],
        runInShell: true,
      );

      _logcatProcess!.stdout.transform(SystemEncoding().decoder).listen((data) {
        setState(() {
          _logLines.addAll(data.split('\n').where((line) => line.trim().isNotEmpty));
        });

        // 自动平滑滚动到底部
        if (_scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          });
        }
      });

      await _logcatProcess!.exitCode;
    } catch (e) {
      setState(() {
        _logLines.add('日志获取失败: $e');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _refresh() {
    _logcatProcess?.kill();
    _startLogcat();
  }

  Future<void> _exportLogs() async {
    if (_logLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有日志可导出')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      // 获取公共 Downloads 目录
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (!downloadDir.existsSync()) {
        await downloadDir.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
      final file = File(p.join(downloadDir.path, 'logcat_$timestamp.txt'));

      await file.writeAsString(_logLines.join('\n'));

      await _showExportOptions(file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _showExportOptions(File file) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出日志'),
        content: Text('日志已保存到:\n${file.path}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logcat 日志'),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            onPressed: _isExporting ? null : _exportLogs,
            tooltip: '导出日志',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: '刷新日志',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logLines.isEmpty
              ? const Center(child: Text('暂无日志输出'))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _logLines.length,
                  itemBuilder: (context, index) {
                    final line = _logLines[index];
                    Color textColor = colorScheme.onBackground;

                    if (line.contains(' E ')) {
                      textColor = Colors.red;
                    } else if (line.contains(' W ')) {
                      textColor = Colors.orange;
                    } else if (line.contains(' I ')) {
                      textColor = Colors.blue;
                    }

                    return Container(
                      color: index.isEven
                          ? colorScheme.surfaceVariant.withOpacity(0.1)
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      child: SelectableText(
                        line,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: textColor,
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: _logLines.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colorScheme.surfaceVariant,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '共 ${_logLines.length} 条日志',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _logLines.length > 1000
                            ? () {
                                setState(() {
                                  _logLines.removeRange(0, _logLines.length - 1000);
                                });
                              }
                            : null,
                        child: const Text('保留最近1000条'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _logLines.clear()),
                        child: const Text('清空日志'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
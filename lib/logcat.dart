import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

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
  bool _autoScroll = true;

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

    _logcatProcess!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (line.trim().isEmpty) return;

      setState(() {
        _logLines.add(line);
      });

      // 自动滚动到底部
      if (_autoScroll) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
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
      final exportDir = await getExternalStorageDirectory();
      if (exportDir == null) return;

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(RegExp(r'[:.]'), '-');
      final file = File('${exportDir.path}/logcat_$timestamp.txt');

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
            child: const Text('关闭'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: file.path));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('路径已复制')),
              );
            },
            child: const Text('复制路径'),
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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'error') {
                setState(() =>
                    _logLines.retainWhere((l) => l.contains(' E ')));
              } else if (value == 'all') {
                _refresh();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'error',
                child: Text('仅显示错误'),
              ),
              const PopupMenuItem(
                value: 'all',
                child: Text('显示全部'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logLines.isEmpty
              ? const Center(child: Text('暂无日志输出'))
              : ListView.separated(
                  controller: _scrollController,
                  itemCount: _logLines.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 0.5, color: colorScheme.outlineVariant),
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

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2),
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
          ? BottomAppBar(
              color: colorScheme.surfaceVariant,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      '共 ${_logLines.length} 条日志',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _autoScroll
                              ? Icons.arrow_downward
                              : Icons.arrow_downward_outlined,
                        ),
                        tooltip: _autoScroll ? '关闭自动滚动' : '开启自动滚动',
                        onPressed: () =>
                            setState(() => _autoScroll = !_autoScroll),
                      ),
                      IconButton(
                        icon: const Icon(Icons.filter_alt),
                        tooltip: '保留最近1000条',
                        onPressed: _logLines.length > 1000
                            ? () {
                                setState(() {
                                  _logLines.removeRange(
                                      0, _logLines.length - 1000);
                                });
                              }
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: '清空日志',
                        onPressed: () => setState(() => _logLines.clear()),
                      ),
                    ],
                  )
                ],
              ),
            )
          : null,
    );
  }
}
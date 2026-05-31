import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/book_api.dart';
import '../../api/bookshelf_api.dart';
import '../../api/reading_progress_api.dart';
import '../../config/application.dart';
import '../../helpers/graphql_helper.dart';
import '../../models/book.dart';
import '../../models/reading_progress.dart';

const _fontSizes = [14.0, 16.0, 18.0, 20.0, 22.0, 26.0];

class ReaderPage extends StatefulWidget {
  final String bookId;

  const ReaderPage({super.key, required this.bookId});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  Book? _book;
  bool _isLoading = true;
  bool _showControls = false;
  bool _isOnShelf = false;
  double _fontSize = 18;
  int _themeIndex = 0;
  int _brightnessLevel = 10; // 0-10

  final List<String> _allLines = [];
  final List<String> _pages = [];
  final List<String> _chapters = []; // Chapter titles
  int _currentPage = 1;
  late PageController _pageController;

  static const _themes = [
    _ReaderTheme(name: '默认', bg: Color(0xFFF5F0EB), fg: Color(0xFF3E3232)),
    _ReaderTheme(name: '护眼', bg: Color(0xFFC7B198), fg: Color(0xFF3E3232)),
    _ReaderTheme(name: '夜间', bg: Color(0xFF1A1A2E), fg: Color(0xFFCCCCCC)),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      BookApi.getBook(widget.bookId),
      ReadingProgressApi.getProgress(widget.bookId),
      BookshelfApi.getMyBookshelf(),
    ]);

    if (!mounted) return;

    final book = GraphQLHelper.getItemFromResult(
      results[0], Book.fromJson, ['book'],
    );
    final progress = GraphQLHelper.getItemFromResult(
      results[1], ReadingProgress.fromJson, ['readingProgress'],
    );

    if (!mounted || book == null) return;

    // Check if in bookshelf
    final shelfItems = GraphQLHelper.getItemsFromResult(
      results[2],
      (m) => m['book']['id'] as String,
      ['myBookshelf'],
    );

    setState(() {
      _book = book;
      _isOnShelf = shelfItems.contains(widget.bookId);
    });

    // Load text content
    if (book.fileType == 'TXT' || book.fileType == 'EPUB') {
      await _loadTextContent(book.fileUrl, book.fileType);
    }

    // Load TOC for EPUB
    if (book.fileType == 'EPUB') {
      await _loadToc(book.fileUrl);
    }

    if (!mounted) return;

    _recalculatePages();

    setState(() {
      if (progress != null && _pages.isNotEmpty) {
        _currentPage = (progress.percentage * _pages.length).round().clamp(1, _pages.length);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _pageController.jumpToPage(_currentPage - 1);
        });
      }
      _isLoading = false;
    });
  }

  Future<void> _loadTextContent(String fileUrl, String fileType) async {
    try {
      final textUrl = fileType == 'TXT' ? fileUrl : '$fileUrl/text';
      final dio = Dio(BaseOptions(
        baseUrl: Application.apiBaseURL,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ));
      final response = await dio.get<String>(textUrl);
      if (response.data != null) {
        var text = response.data!;
        // Split by newlines first
        for (var line in text.split('\n')) {
          line = line.trim();
          if (line.isEmpty) continue;
          // Break very long lines at sentence boundaries or max 200 chars
          while (line.length > 200) {
            // Try to break at Chinese/English sentence ending
            int breakAt = -1;
            for (var sep in ['。', '！', '？', '…', '. ', '! ', '? ', '\n']) {
              int idx = line.indexOf(sep, 100);
              if (idx != -1 && idx < 250) {
                breakAt = idx + sep.length;
                break;
              }
            }
            if (breakAt == -1) breakAt = 200;
            _allLines.add(line.substring(0, breakAt).trim());
            line = line.substring(breakAt).trim();
          }
          if (line.isNotEmpty) _allLines.add(line);
        }
      }
    } catch (_) {
      _allLines.add('（内容加载失败）');
    }
  }

  Future<void> _loadToc(String fileUrl) async {
    try {
      final tocUrl = '$fileUrl/toc';
      final dio = Dio(BaseOptions(
        baseUrl: Application.apiBaseURL,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ));
      final response = await dio.get<Map<String, dynamic>>(tocUrl);
      final chapters = response.data?['chapters'] as List<dynamic>?;
      if (chapters != null) {
        _chapters.addAll(chapters.map((c) {
          if (c is Map) return (c['title'] as String?) ?? '';
          return c.toString();
        }).where((t) => t.isNotEmpty));
      }
    } catch (_) {
      // TOC is optional
    }
  }

  void _jumpToChapter(int chapterIndex) {
    if (_chapters.isEmpty || _pages.isEmpty) return;
    final estimatedPage = ((chapterIndex / _chapters.length) * _pages.length).round().clamp(1, _pages.length);
    setState(() => _currentPage = estimatedPage);
    _pageController.jumpToPage(_currentPage - 1);
    _saveProgress();
  }

  void _showTocSheet() {
    if (_chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无目录信息')),
      );
      return;
    }

    final theme = _themes[_themeIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.fg.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Text('目录', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: theme.fg)),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Chapter list
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _chapters.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: theme.fg.withValues(alpha: 0.08),
                  ),
                  itemBuilder: (context, index) {
                    final isCurrent = _currentPage ==
                        ((index / _chapters.length) * _pages.length).round().clamp(1, _pages.length);
                    return ListTile(
                      dense: true,
                      title: Text(
                        _chapters[index],
                        style: TextStyle(
                          fontSize: 15,
                          color: isCurrent ? const Color(0xFF07C160) : theme.fg,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isCurrent
                          ? const Icon(Icons.chevron_right, size: 18, color: Color(0xFF07C160))
                          : null,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _jumpToChapter(index);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showFontSheet() {
    final theme = _themes[_themeIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: theme.fg.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Text('字体大小', style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: theme.fg)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Preview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.fg.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '小时候，每到夜晚，我总会坐在院子里，仰着脑袋，天真地问妈妈...',
                      style: TextStyle(fontSize: _fontSize, height: 1.6, color: theme.fg),
                    ),
                  ),
                ),
                // Font size options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('A', style: TextStyle(
                        fontSize: 14, color: theme.fg.withValues(alpha: 0.6))),
                      ..._fontSizes.map((size) {
                        final selected = _fontSize == size;
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _onFontSizeChanged(size);
                          },
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF07C160).withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${size.toInt()}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                color: selected ? const Color(0xFF07C160) : theme.fg,
                              ),
                            ),
                          ),
                        );
                      }),
                      Text('A', style: TextStyle(
                        fontSize: 22, color: theme.fg.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _recalculatePages() {
    final linesPerPage = _estimateLinesPerPage();
    _pages.clear();
    for (var i = 0; i < _allLines.length; i += linesPerPage) {
      final end = (i + linesPerPage).clamp(0, _allLines.length);
      _pages.add(_allLines.sublist(i, end).join('\n'));
    }
    if (_pages.isEmpty && _allLines.isNotEmpty) {
      _pages.add(_allLines.join('\n'));
    }
  }

  int _estimateLinesPerPage() {
    // Base lines at font size 16, adjusted for actual font size
    const baseLines = 18;
    final ratio = 16 / _fontSize;
    return (baseLines * ratio).round().clamp(3, 50);
  }

  void _onFontSizeChanged(double size) {
    setState(() {
      _fontSize = size;
      final oldPage = _currentPage;
      _recalculatePages();
      final newPage = oldPage.clamp(1, _pages.length);
      _currentPage = newPage;
      _pageController.jumpToPage(newPage - 1);
    });
  }

  Future<void> _saveProgress() async {
    if (_pages.isEmpty) return;
    final percentage = _currentPage / _pages.length;
    await ReadingProgressApi.saveProgress(
      bookId: widget.bookId,
      percentage: percentage,
    );
  }

  void _goNextPage() {
    if (_currentPage < _pages.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goPrevPage() {
    if (_currentPage > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _toggleShelf() async {
    if (_isOnShelf) {
      await BookshelfApi.removeFromBookshelf(widget.bookId);
    } else {
      await BookshelfApi.addToBookshelf(widget.bookId);
    }
    if (!mounted) return;
    setState(() => _isOnShelf = !_isOnShelf);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isOnShelf ? '已加入书架' : '已从书架移除')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themes[_themeIndex];
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.bg,
        body: Center(
          child: CircularProgressIndicator(color: theme.fg.withValues(alpha: 0.5)),
        ),
      );
    }

    final book = _book;
    if (book == null) {
      return Scaffold(
        backgroundColor: theme.bg,
        body: const Center(child: Text('图书不存在')),
      );
    }

    final totalPages = _pages.isEmpty ? 1 : _pages.length;
    final progressPercent = (_currentPage / totalPages * 100).round();

    return Scaffold(
      backgroundColor: theme.bg,
      body: Stack(
        children: [
          // ---- Page content ----
          Positioned.fill(
            top: 0,
            bottom: 0,
            child: _pages.isNotEmpty
                ? PageView.builder(
                    controller: _pageController,
                    physics: const ClampingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentPage = index + 1);
                      _saveProgress();
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.07,
                          vertical: 40,
                        ),
                        child: Text(
                          _pages[index],
                          style: TextStyle(
                            fontSize: _fontSize,
                            height: 1.8,
                            color: theme.fg,
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(book.title, style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: theme.fg)),
                        const SizedBox(height: 8),
                        Text(book.author, style: TextStyle(
                          fontSize: 15, color: theme.fg.withValues(alpha: 0.6))),
                        if (book.fileType != 'TXT' && book.fileType != 'EPUB') ...[
                          const SizedBox(height: 24),
                          Text('${book.fileType} 格式暂不支持预览', style: TextStyle(
                            fontSize: 14, color: theme.fg.withValues(alpha: 0.4))),
                        ],
                      ],
                    ),
                  ),
          ),

          // ---- Tap zones ----
          if (!_showControls)
            Row(
              children: [
                Expanded(child: GestureDetector(
                  onTap: _goPrevPage, behavior: HitTestBehavior.translucent)),
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _showControls = true),
                  behavior: HitTestBehavior.translucent)),
                Expanded(child: GestureDetector(
                  onTap: _goNextPage, behavior: HitTestBehavior.translucent)),
              ],
            )
          else
            GestureDetector(
              onTap: () => setState(() => _showControls = false),
              behavior: HitTestBehavior.translucent,
            ),

          // ---- Top bar ----
          if (_showControls)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                color: theme.bg.withValues(alpha: 0.97),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: theme.fg),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: Text(
                            book.title,
                            style: TextStyle(color: theme.fg, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!_isOnShelf)
                          TextButton(
                            onPressed: _toggleShelf,
                            child: Text('加入书架', style: TextStyle(
                              color: theme.fg, fontSize: 14)),
                          ),
                        IconButton(
                          icon: Icon(Icons.more_horiz, color: theme.fg),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ---- Bottom bar ----
          if (_showControls)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                color: theme.bg.withValues(alpha: 0.97),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress bar
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Text('$progressPercent%', style: TextStyle(
                                fontSize: 12, color: theme.fg.withValues(alpha: 0.5))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {}, // will implement progress tap
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      trackHeight: 2,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                      activeTrackColor: theme.fg.withValues(alpha: 0.6),
                                      inactiveTrackColor: theme.fg.withValues(alpha: 0.15),
                                      thumbColor: theme.fg,
                                    ),
                                    child: Slider(
                                      value: _currentPage.toDouble(),
                                      min: 1,
                                      max: totalPages.toDouble(),
                                      onChanged: (v) {
                                        setState(() => _currentPage = v.round());
                                        _pageController.jumpToPage(_currentPage - 1);
                                      },
                                      onChangeEnd: (_) => _saveProgress(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('$_currentPage / $totalPages', style: TextStyle(
                                fontSize: 12, color: theme.fg.withValues(alpha: 0.5))),
                            ],
                          ),
                        ),

                        // Control icons row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Brightness
                            _BottomIcon(
                              icon: Icons.brightness_6_outlined,
                              label: '亮度',
                              color: theme.fg,
                              onTap: () => setState(() {
                                _brightnessLevel = _brightnessLevel == 10 ? 5 : 10;
                              }),
                            ),
                            // Font size
                            _BottomIcon(
                              icon: Icons.text_fields,
                              label: '字体',
                              color: theme.fg,
                              onTap: () => _showFontSheet(),
                            ),
                            // Table of contents
                            _BottomIcon(
                              icon: Icons.list_alt_outlined,
                              label: '目录',
                              color: theme.fg,
                              onTap: _showTocSheet,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BottomIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ReaderTheme {
  final String name;
  final Color bg;
  final Color fg;

  const _ReaderTheme({
    required this.name,
    required this.bg,
    required this.fg,
  });
}

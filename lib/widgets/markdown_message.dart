import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../i18n/strings.dart';
import '../theme/app_theme.dart';

/// Markdown 渲染 + 代码块高亮 + 一键复制。
///
/// 代码块通过自定义 builder 替换成带「语言标签 + 复制按钮」的卡片。
class MarkdownMessage extends StatelessWidget {
  const MarkdownMessage({
    super.key,
    required this.text,
    this.selectable = true,
    this.textColor,
    this.fontSize = 15,
  });

  final String text;
  final bool selectable;
  final Color? textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final baseColor = textColor ?? scheme.onSurface;

    return MarkdownBody(
      data: text,
      selectable: selectable,
      softLineBreak: true,
      builders: {
        'code': _CodeElementBuilder(
          isDark: theme.brightness == Brightness.dark,
          scheme: scheme,
        ),
      },
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        <md.InlineSyntax>[
          md.EmojiSyntax(),
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
        ],
      ),
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(fontSize: fontSize, height: 1.55, color: baseColor),
        h1: TextStyle(
          fontSize: fontSize + 8,
          fontWeight: FontWeight.w700,
          color: baseColor,
          height: 1.4,
        ),
        h2: TextStyle(
          fontSize: fontSize + 5,
          fontWeight: FontWeight.w700,
          color: baseColor,
          height: 1.4,
        ),
        h3: TextStyle(
          fontSize: fontSize + 2,
          fontWeight: FontWeight.w600,
          color: baseColor,
          height: 1.4,
        ),
        h4: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: baseColor,
        ),
        strong: TextStyle(fontWeight: FontWeight.w700, color: baseColor),
        em: TextStyle(fontStyle: FontStyle.italic, color: baseColor),
        listBullet: TextStyle(fontSize: fontSize, color: baseColor),
        a: TextStyle(
          color: scheme.primary,
          decoration: TextDecoration.underline,
          decorationColor: scheme.primary.withValues(alpha: 0.5),
        ),
        // 行内代码
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize - 1.5,
          backgroundColor: scheme.primary.withValues(alpha: 0.12),
          color: scheme.primary,
        ),
        codeblockDecoration: const BoxDecoration(),
        codeblockPadding: EdgeInsets.zero,
        blockquote: TextStyle(
          fontSize: fontSize,
          color: baseColor.withValues(alpha: 0.75),
          height: 1.5,
        ),
        blockquoteDecoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppTheme.rSm),
          border: Border(
            left: BorderSide(color: scheme.primary, width: 3),
          ),
        ),
        blockquotePadding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        tableHead: TextStyle(fontWeight: FontWeight.w600, color: baseColor),
        tableBody: TextStyle(fontSize: fontSize - 1, color: baseColor),
        tableBorder: TableBorder.all(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
          width: 0.7,
          borderRadius: BorderRadius.circular(8),
        ),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.7),
              width: 1,
            ),
          ),
        ),
        blockSpacing: 10,
      ),
      onTapLink: (text, href, title) {
        // 复制链接到剪贴板，避免引入 url_launcher 依赖
        if (href == null) return;
        Clipboard.setData(ClipboardData(text: href));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l.text('链接已复制：$href', 'Link copied: $href'))),
        );
      },
    );
  }
}

/// 把 ``` 代码块渲染成带工具条的卡片
class _CodeElementBuilder extends MarkdownElementBuilder {
  _CodeElementBuilder({required this.isDark, required this.scheme});

  final bool isDark;
  final ColorScheme scheme;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // 只处理块级代码（class 形如 language-dart）
    var language = '';
    final cls = element.attributes['class'];
    if (cls != null && cls.startsWith('language-')) {
      language = cls.substring(9);
    }

    final code = element.textContent.trimRight();

    // 行内代码交给 styleSheet 处理
    if (cls == null && !code.contains('\n')) return null;

    return _CodeBlock(
      code: code,
      language: language,
      isDark: isDark,
      scheme: scheme,
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({
    required this.code,
    required this.language,
    required this.isDark,
    required this.scheme,
  });

  final String code;
  final String language;
  final bool isDark;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF15181C) : const Color(0xFFF3F5F7);
    final lang = language.isEmpty ? 'text' : language;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.6),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 工具条：语言 + 复制
          Container(
            padding: const EdgeInsets.only(left: 14, right: 6),
            height: 36,
            color: scheme.primary.withValues(alpha: isDark ? 0.10 : 0.08),
            child: Row(
              children: [
                Text(
                  lang,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: scheme.primary,
                  ),
                ),
                const Spacer(),
                _CopyButton(code: code),
              ],
            ),
          ),
          // 代码本体：横向可滚动，避免长行挤压
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: HighlightView(
              code,
              language: _safeLanguage(lang),
              theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// flutter_highlight 遇到未知语言会抛错，这里做兜底
  String _safeLanguage(String lang) {
    const supported = {
      'dart', 'python', 'javascript', 'js', 'typescript', 'ts', 'java',
      'kotlin', 'swift', 'c', 'cpp', 'csharp', 'cs', 'go', 'rust', 'ruby',
      'php', 'html', 'xml', 'css', 'scss', 'json', 'yaml', 'sql', 'bash',
      'shell', 'sh', 'markdown', 'md', 'ini', 'lua', 'r', 'scala', 'perl',
      'objectivec', 'matlab', 'dockerfile', 'makefile', 'diff', 'graphql',
      'plaintext', 'text',
    };
    final l = lang.toLowerCase();
    if (supported.contains(l)) {
      // 别名映射
      return switch (l) {
        'js' => 'javascript',
        'ts' => 'typescript',
        'cs' => 'csharp',
        'sh' => 'bash',
        'md' => 'markdown',
        'text' => 'plaintext',
        _ => l,
      };
    }
    return 'plaintext';
  }
}

/// 复制按钮：点击后短暂显示对勾
class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.code});

  final String code;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton.icon(
      onPressed: _copy,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        foregroundColor: scheme.primary,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: AnimatedSwitcher(
        duration: AppTheme.fast,
        child: Icon(
          _copied ? Icons.check_rounded : Icons.copy_rounded,
          key: ValueKey(_copied),
          size: 15,
        ),
      ),
      label: Text(
        _copied ? context.l.copied : context.l.copy,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
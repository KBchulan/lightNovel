// ****************************************************************************
//
// @file       search_box.dart
// @brief      自定义搜索框组件
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchBoxFocusProvider = StateProvider<bool>((ref) => false);

class SearchBox extends ConsumerStatefulWidget {
  final void Function(String) onSubmitted;
  final String? hintText;
  final bool autofocus;

  const SearchBox({
    super.key,
    required this.onSubmitted,
    this.hintText,
    this.autofocus = false,
  });

  @override
  ConsumerState<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends ConsumerState<SearchBox> {
  final _focusNode = FocusNode();
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    if (widget.autofocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    ref.read(searchBoxFocusProvider.notifier).state = _focusNode.hasFocus;
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = ref.watch(searchBoxFocusProvider);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        _focusNode.requestFocus();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        decoration: BoxDecoration(
          color: isFocused
              ? theme.colorScheme.surface.withAlpha(204)
              : theme.colorScheme.surface.withAlpha(51),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFocused
                ? theme.colorScheme.primary.withAlpha(179)
                : theme.colorScheme.onSurface.withAlpha(13),
            width: isFocused ? 1.5 : 0.5,
          ),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(isFocused ? 255 : 179),
          ),
          decoration: InputDecoration(
            hintText: widget.hintText ?? '搜索小说...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(77),
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: isFocused
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withAlpha(77),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          onSubmitted: (value) {
            widget.onSubmitted(value);
            _focusNode.unfocus(); // 提交后取消焦点
          },
          onEditingComplete: () {
            _focusNode.unfocus(); // 点击完成按钮时取消焦点
          },
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';

/// Include animations of text
enum OverFlowTextAnimations {
  /// scrolls in an infinite loop
  infiniteLoop,

  /// scroll from top to end and vice versa
  scrollOpposite
}

class OverflowTextAnimated extends StatefulWidget {
  const OverflowTextAnimated({
    required this.text,
    Key? key,
    this.animation = OverFlowTextAnimations.infiniteLoop,
    required this.style,
    this.delay = const Duration(milliseconds: 1500),
    this.animateDuration = const Duration(milliseconds: 150),
    this.curve = Curves.easeInOut,
    this.loopSpace = 0,
    this.scrollSpace = 5,
  }) : super(key: key);

  /// required properties
  final String text;

  /// style of text
  final TextStyle? style;

  /// [delay] is the break time between 2 animations
  final Duration delay;

  /// [animateDuration] is the duration of the animation
  final Duration animateDuration;

  /// motion curves of animation effects
  final Curve curve;

  /// animation type
  final OverFlowTextAnimations animation;

  /// space of 2 loop contents
  final int loopSpace;

  /// space of scroll
  final int scrollSpace;

  @override
  State<OverflowTextAnimated> createState() => _OverflowTextAnimatedState();
}

class _OverflowTextAnimatedState extends State<OverflowTextAnimated> {
  /// Scroll controller of SingleChildScrollView wrap text
  final ScrollController _scrollController = ScrollController();

  /// [_exceeded] save value overflow or not
  bool _exceeded = false;

  /// max lines of text. Now, only support 1 line
  final int _maxLines = 1;

  /// content of text
  late String _text;

  /// [infiniteLoop] - space characters, init based  [loopSpace]
  String _spaces = '';

  /// [infiniteLoop] - save position of scroll
  double _scrollPosition = 0.0;

  /// Timer for periodic scrolling animation
  Timer? _scrollTimer;

  /// Flag to stop async operations
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _text = widget.text;

    /// initial text

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check if still mounted before starting animations
      if (!mounted || _isDisposed) return;

      if (_exceeded) {
        /// if text is overflow
        switch (widget.animation) {
          case OverFlowTextAnimations.scrollOpposite:
            await _handlerScrollOpposite();
            break;
          default:
            await _handlerInfiniteLoop();
        }
      }
    });
  }

  Future _handlerScrollOpposite() async {
    /// scroll to end and wait delay
    /// then scroll to top
    while (mounted && !_isDisposed) {
      await Future.delayed(widget.delay);

      // Check mounted after delay
      if (!mounted || _isDisposed) break;

      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: widget.animateDuration,
          curve: widget.curve,
        );

        // Check mounted after animation
        if (!mounted || _isDisposed) break;

        await Future.delayed(widget.delay);

        // Check mounted after delay
        if (!mounted || _isDisposed) break;

        if (_scrollController.hasClients) {
          await _scrollController.animateTo(
            _scrollController.position.minScrollExtent,
            duration: widget.animateDuration,
            curve: widget.curve,
          );
        }
      }
    }
  }

  Future _handlerInfiniteLoop() async {
    for (int i = 0; i < widget.loopSpace; i++) {
      _spaces += ' ';
    }

    _scrollController.addListener(_scrollListener);

    /// Auto scroll with periodic
    _scrollTimer = Timer.periodic(widget.animateDuration, (Timer timer) {
      // Check if disposed before calling _autoScroll
      if (!mounted || _isDisposed) {
        timer.cancel();
        return;
      }
      _autoScroll();
    });
  }

  /// Auto scroll
  void _autoScroll() {
    if (mounted && !_isDisposed) {
      setState(() {
        _scrollPosition += widget.scrollSpace;
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollPosition,
            duration: widget.animateDuration,
            curve: Curves.linear,
          );
        }
      });
    }
  }

  /// Function listens for scroll event and checks scroll position
  void _scrollListener() {
    // Check mounted before accessing controller and calling setState
    if (!mounted || _isDisposed || !_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent) {
      if (mounted && !_isDisposed) {
        setState(() {
          /// If the scroll position is near the end, add new text
          _text += '$_spaces${widget.text}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, size) {
      final span = TextSpan(
        text: _text,
        style: widget.style,
      );

      final tp = TextPainter(
          maxLines: _maxLines,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
          text: span,
          strutStyle: StrutStyle(
            fontSize: widget.style?.fontSize,
            fontWeight: widget.style?.fontWeight,
            height: widget.style?.fontSize,
            fontStyle: widget.style?.fontStyle,
            fontFamily: widget.style?.fontFamily,
          ));

      tp.layout(maxWidth: size.maxWidth);

      /// check overflow
      _exceeded = tp.didExceedMaxLines;

      return SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Text.rich(
          span,
          maxLines: _maxLines,
          style: widget.style,
        ),
      );
    });
  }

  @override
  void dispose() {
    /// Mark as disposed to stop all async operations
    _isDisposed = true;

    /// Cancel timer if it exists
    _scrollTimer?.cancel();
    _scrollTimer = null;

    /// Remove scroll listener
    _scrollController.removeListener(_scrollListener);

    /// dispose controller
    _scrollController.dispose();
    super.dispose();
  }
}

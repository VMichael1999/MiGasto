import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/mg_colors.dart';

/// Video tutorial dentro de la app (sin internet): cómo crear la automatización de Apple Pay.
/// Toca el video para pausar o reanudar; al terminar ofrece volver a verlo.
class TutorialVideoScreen extends StatefulWidget {
  const TutorialVideoScreen({super.key, this.asset = defaultAsset});

  static const defaultAsset = 'assets/tutorial/apple_pay.mp4';

  final String asset;

  @override
  State<TutorialVideoScreen> createState() => _TutorialVideoScreenState();
}

class _TutorialVideoScreenState extends State<TutorialVideoScreen> {
  late final VideoPlayerController _controller = VideoPlayerController.asset(widget.asset);
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _controller.play();
    }).catchError((Object _) {
      if (mounted) setState(() => _failed = true);
    });
    _controller.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  bool get _finished =>
      _ready &&
      _controller.value.duration > Duration.zero &&
      _controller.value.position >= _controller.value.duration;

  Future<void> _toggle() async {
    if (!_ready) return;
    if (_finished) {
      await _controller.seekTo(Duration.zero);
      await _controller.play();
    } else if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final playing = _ready && _controller.value.isPlaying;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _failed
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No se pudo reproducir el video. Sigue los pasos de la guía.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: MgColors.ink2, fontSize: 15),
                      ),
                    )
                  : !_ready
                      ? const CircularProgressIndicator(color: MgColors.acc2)
                      : GestureDetector(
                          onTap: _toggle,
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                VideoPlayer(_controller),
                                AnimatedOpacity(
                                  opacity: playing ? 0 : 1,
                                  duration: const Duration(milliseconds: 180),
                                  child: Container(
                                    width: 76,
                                    height: 76,
                                    decoration: const BoxDecoration(
                                      color: Color(0x99000000),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _finished ? Icons.replay_rounded : Icons.play_arrow_rounded,
                                      size: 44,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
            Positioned(
              left: 12,
              top: 8,
              child: IconButton(
                onPressed: _close,
                tooltip: 'Cerrar',
                style: IconButton.styleFrom(backgroundColor: const Color(0x99000000)),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            if (_ready)
              Positioned(
                left: 24,
                right: 24,
                bottom: 14,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: MgColors.acc2,
                    bufferedColor: Color(0x33FFFFFF),
                    backgroundColor: Color(0x22FFFFFF),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

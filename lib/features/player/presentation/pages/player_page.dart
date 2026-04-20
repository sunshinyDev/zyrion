import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../../../core/theme/app_theme.dart';

class PlayerPage extends StatefulWidget {
  final String title;
  final String url;
  final bool isLive;

  const PlayerPage({
    super.key,
    required this.title,
    required this.url,
    this.isLive = false,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _error;
  Timer? _liveEdgeTimer;
  bool _showLiveSynced = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (widget.url.isEmpty) {
      setState(() => _error = 'URL de stream não disponível.');
      return;
    }

    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        httpHeaders: widget.isLive
            ? {
                'Connection': 'keep-alive',
                'Cache-Control': 'no-cache',
              }
            : {},
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: false,
          mixWithOthers: false,
        ),
      );

      await _videoController!.initialize();

      // For live: jump to the furthest buffered position (live edge)
      if (widget.isLive) {
        final dur = _videoController!.value.duration;
        if (dur.inSeconds > 2) {
          await _videoController!.seekTo(dur);
        }
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: widget.isLive,
        isLive: widget.isLive,
        allowFullScreen: false, // we handle orientation ourselves
        allowMuting: true,
        showControls: true,
        showControlsOnInitialize: false,
        placeholder: Container(color: Colors.black),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: AppColors.surfaceVariant,
          bufferedColor: AppColors.primary.withOpacity(0.3),
        ),
      );

      if (mounted) setState(() => _isInitialized = true);

      if (widget.isLive) _startLiveEdgeSync();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Erro ao carregar o stream.\n$e');
      }
    }
  }

  void _startLiveEdgeSync() {
    _liveEdgeTimer =
        Timer.periodic(const Duration(seconds: 25), (_) async {
      if (_videoController == null || !mounted) return;
      final val = _videoController!.value;
      if (!val.isPlaying) return;
      final dur = val.duration;
      final pos = val.position;
      final behind = dur - pos;
      if (behind.inSeconds > 8) {
        debugPrint('[Player] Drift ${behind.inSeconds}s — syncing');
        await _videoController!.seekTo(dur);
      }
    });
  }

  Future<void> _syncToLiveEdge() async {
    if (_videoController == null) return;
    final dur = _videoController!.value.duration;
    if (dur.inSeconds > 0) await _videoController!.seekTo(dur);
    setState(() => _showLiveSynced = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showLiveSynced = false);
    });
  }

  @override
  void dispose() {
    _liveEdgeTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Video ──────────────────────────────────────────────
          Center(
            child: _error != null
                ? _buildError()
                : !_isInitialized
                    ? _buildLoading()
                    : Chewie(controller: _chewieController!),
          ),

          // ── Back button ────────────────────────────────────────
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ),

          // ── Title + Live badge ─────────────────────────────────
          Positioned(
            top: 16,
            left: 72,
            right: 16,
            child: SafeArea(
              child: Row(
                children: [
                  if (widget.isLive)
                    GestureDetector(
                      onTap: _syncToLiveEdge,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _showLiveSynced
                              ? AppColors.success
                              : AppColors.live,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.circle,
                                color: Colors.white, size: 6),
                            const SizedBox(width: 4),
                            Text(
                              _showLiveSynced
                                  ? 'AO VIVO ✓'
                                  : 'AO VIVO',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 8),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.isLive ? 'Conectando ao canal...' : 'Carregando...',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded,
            color: AppColors.error, size: 48),
        const SizedBox(height: 16),
        Text(
          _error!,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _error = null;
              _isInitialized = false;
            });
            _initPlayer();
          },
          child: const Text('Tentar novamente'),
        ),
      ],
    );
  }
}

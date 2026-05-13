// lib/screens/ai/listen_screen.dart
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';
import '../../widgets/ai/listen/waveform_visualizer.dart';
import '../../widgets/ai/listen/speed_selector.dart';
import '../../services/tts_service.dart';

class ListenScreen extends StatefulWidget {
  const ListenScreen({Key? key}) : super(key: key);

  @override
  State<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends State<ListenScreen>
    with SingleTickerProviderStateMixin {
  String _content =
      "Your AI-generated explanation will appear here. "
      "This is a sample of the detailed breakdown of your uploaded material. "
      "The AI has analyzed the content and extracted key concepts, definitions, and examples. "
      "You can scroll through this text while listening to the audio. "
      "This is additional placeholder text to make the card longer and demonstrate scrolling. "
      "Keep reading to ensure the card is visible on all devices. "
      "More content can be added here…";

  bool _isPlaying = false;
  bool _isLoading = false;
  double _progress = 0.0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  late AnimationController _waveController;
  double _speed = 0.5;

  List<String> _words = [];
  int _currentWordIndex = -1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _waveController.repeat(reverse: true);
    _initializeTTS();
  }

  Future<void> _initializeTTS() async {
    await TTSService.init();
    if (!mounted) return;
    TTSService.onProgress = _onProgress;
    TTSService.onComplete = _onComplete;
  }

  void _onProgress(String text, int start, int end, String word) {
    if (!mounted) return;
    final totalLength = _content.length;
    final newProgress = totalLength > 0 ? start / totalLength : 0.0;

    int wordIndex = -1;
    if (word.isNotEmpty && _words.isNotEmpty) {
      wordIndex = _words.indexWhere(
            (w) => w.trim().toLowerCase() == word.trim().toLowerCase(),
        _currentWordIndex < 0 ? 0 : _currentWordIndex,
      );
      if (wordIndex < 0) {
        wordIndex = _words.indexWhere(
              (w) => w.trim().toLowerCase() == word.trim().toLowerCase(),
        );
      }
    }

    setState(() {
      _progress = newProgress;
      if (wordIndex >= 0) _currentWordIndex = wordIndex;
      if (_duration.inMilliseconds > 0) {
        _position = Duration(
          milliseconds: (newProgress * _duration.inMilliseconds).round(),
        );
      }
    });
    _scrollToCurrentWord();
  }

  void _scrollToCurrentWord() {
    if (_scrollController.hasClients && _currentWordIndex >= 0) {
      final estimatedOffset = _currentWordIndex * 12.0;
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        estimatedOffset > maxScroll ? maxScroll : estimatedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onComplete() {
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _progress = 1.0;
        _position = _duration;
        _currentWordIndex = -1;
        _waveController.stop();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments
    as Map<String, dynamic>?;
    if (args != null && args.containsKey('text')) {
      final newContent = args['text'] as String;
      if (newContent != _content) {
        _content = newContent;
        _words = _content
            .split(RegExp(r'[\s]+'))
            .where((w) => w.isNotEmpty)
            .toList();
        _duration = TTSService.getEstimatedDuration(_content, _speed);
      }
    }
  }

  @override
  void dispose() {
    TTSService.stop();
    TTSService.onProgress = null;
    TTSService.onComplete = null;
    _waveController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await TTSService.pause();
      _waveController.stop();
      setState(() => _isPlaying = false);
    } else {
      setState(() {
        _isPlaying = true;
        _isLoading = true;
      });
      _waveController.repeat(reverse: true);
      try {
        if (_progress >= 1.0) {
          setState(() {
            _progress = 0.0;
            _position = Duration.zero;
            _currentWordIndex = -1;
          });
        }
        await TTSService.speak(_content);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Speech error: $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rewind() async {
    await TTSService.stop();
    if (mounted) {
      setState(() {
        _progress = 0.0;
        _position = Duration.zero;
        _currentWordIndex = -1;
        _isPlaying = false;
        _waveController.stop();
      });
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _forward() async {
    await TTSService.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _progress = 1.0;
        _position = _duration;
        _currentWordIndex = -1;
        _waveController.stop();
      });
    }
  }

  Future<void> _changeSpeed(double speed) async {
    final wasPlaying = _isPlaying;
    if (wasPlaying) await TTSService.stop();
    await TTSService.setSpeed(speed);
    setState(() {
      _speed = speed;
      _duration = TTSService.getEstimatedDuration(_content, speed);
    });
    if (wasPlaying) {
      await TTSService.speak(_content);
      setState(() => _isPlaying = true);
      _waveController.repeat(reverse: true);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Listen with AI Tutor',
            style: AppTextStyles.heading3.copyWith(color: AppColors.primary)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              child: WaveformVisualizer(
                progress: _progress,
                isPlaying: _isPlaying,
                animation: _waveController,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text(_formatDuration(_position), style: AppTextStyles.caption),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      thumbColor: AppColors.primary,
                      inactiveTrackColor: AppColors.primary.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _progress,
                      onChanged: (v) => setState(() => _progress = v),
                    ),
                  ),
                ),
                Text(_formatDuration(_duration), style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.replay_5,
                      color: AppColors.primary.withOpacity(0.7)),
                  iconSize: 32,
                  onPressed: _rewind,
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: AppColors.primary),
                  child: _isLoading
                      ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(
                      color: AppColors.surface,
                      strokeWidth: 3,
                    ),
                  )
                      : IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: AppColors.surface,
                    ),
                    iconSize: 40,
                    onPressed: _togglePlayback,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton(
                  icon: Icon(Icons.forward_5,
                      color: AppColors.primary.withOpacity(0.7)),
                  iconSize: 32,
                  onPressed: _forward,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Speed selector
            Center(
              child: SpeedSelector(
                selectedSpeed: _speed,
                onSpeedChanged: _changeSpeed,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 300),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: _words.isEmpty
                  ? Text(
                _content,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.8,
                ),
              )
                  : SingleChildScrollView(
                controller: _scrollController,
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.8,
                    ),
                    children: _words.asMap().entries.map((entry) {
                      final isActive = entry.key == _currentWordIndex &&
                          _isPlaying;
                      return TextSpan(
                        text: '${entry.value} ',
                        style: TextStyle(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          backgroundColor: isActive
                              ? AppColors.primary.withOpacity(0.15)
                              : Colors.transparent,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
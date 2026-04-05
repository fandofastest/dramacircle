import 'dart:ui';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:dramacircle/src/data/models/drama_models.dart';
import 'package:dramacircle/src/features/library/providers/library_controller.dart';
import 'package:dramacircle/src/features/fyp/providers/fyp_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

class FypVideoPage extends ConsumerStatefulWidget {
  const FypVideoPage({
    super.key,
    required this.episode,
    required this.userPremium,
    required this.isLocked,
    required this.lockTitle,
    required this.lockButtonText,
    required this.onGoPremium,
    required this.onPlaybackStarted,
    required this.onSaveProgress,
    this.initialPositionMs = 0,
    this.showSeekBar = false,
    this.onWatchFull,
  });

  final EpisodeItem episode;
  final bool userPremium;
  final bool isLocked;
  final String lockTitle;
  final String lockButtonText;
  final VoidCallback onGoPremium;
  final VoidCallback onPlaybackStarted;
  final Future<void> Function(int positionMs) onSaveProgress;
  final int initialPositionMs;
  final bool showSeekBar;
  final VoidCallback? onWatchFull;

  @override
  ConsumerState<FypVideoPage> createState() => _FypVideoPageState();
}

class _FypVideoPageState extends ConsumerState<FypVideoPage> {
  static final ValueNotifier<String?> _activePlaybackOwner = ValueNotifier<String?>(null);

  BetterPlayerController? _controller;
  bool _reportedPlaybackStart = false;
  bool _pausedByUser = false;
  bool _isVisible = false;
  bool _isInitializing = false;
  bool _hasLoadError = false;
  bool _isTabletLayout = false;
  bool _showDetailActions = true;
  bool _isDisposed = false;
  bool _playTracked = false;
  bool _showLikeBurst = false;
  late final String _ownerId;
  EpisodeEngagement? _engagement;
  Future<void>? _initializingTask;
  Timer? _actionsHideTimer;
  Timer? _likeBurstTimer;

  @override
  void initState() {
    super.initState();
    _ownerId = '${widget.episode.episodeId}-${identityHashCode(this)}';
    _activePlaybackOwner.addListener(_onActivePlaybackChanged);
    unawaited(_loadEngagement());
    if (widget.showSeekBar) {
      _scheduleActionsAutoHide();
    }
  }

  @override
  void didUpdateWidget(covariant FypVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.episode.videoUrl != widget.episode.videoUrl ||
        oldWidget.userPremium != widget.userPremium ||
        oldWidget.isLocked != widget.isLocked) {
      _controller?.dispose();
      _controller = null;
      _reportedPlaybackStart = false;
      _pausedByUser = false;
      _hasLoadError = false;
      _isInitializing = false;
      _initializingTask = null;
    }
    if (oldWidget.episode.episodeId != widget.episode.episodeId || oldWidget.episode.bookId != widget.episode.bookId) {
      _playTracked = false;
      _engagement = null;
      unawaited(_loadEngagement());
    }
    if (oldWidget.showSeekBar != widget.showSeekBar) {
      _showDetailActions = true;
      if (widget.showSeekBar) {
        _scheduleActionsAutoHide();
      } else {
        _actionsHideTimer?.cancel();
      }
    }
  }

  Future<void> _createPlayer() async {
    if (_isDisposed || _isInitializing || _controller != null || widget.episode.videoUrl.isEmpty || widget.isLocked) {
      return;
    }
    setState(() {
      _isInitializing = true;
      _hasLoadError = false;
    });

    final config = BetterPlayerConfiguration(
      autoPlay: !widget.isLocked,
      looping: true,
      fit: BoxFit.cover,
      expandToFill: true,
      aspectRatio: _isTabletLayout ? (9 / 16) : null,
      controlsConfiguration: BetterPlayerControlsConfiguration(showControls: widget.showSeekBar),
      placeholder: const Center(child: CircularProgressIndicator()),
    );
    final controller = BetterPlayerController(config);
    try {
      await controller
          .setupDataSource(BetterPlayerDataSource(BetterPlayerDataSourceType.network, widget.episode.videoUrl))
          .timeout(const Duration(seconds: 15));
      if (!mounted || _isDisposed) {
        controller.dispose();
        return;
      }
      _controller = controller;
      _hasLoadError = false;
      if (widget.initialPositionMs > 0) {
        await _controller?.seekTo(Duration(milliseconds: widget.initialPositionMs));
      }
      if (_canAutoPlay()) {
        _requestPlay();
        if (!_reportedPlaybackStart) {
          _reportedPlaybackStart = true;
          widget.onPlaybackStarted();
        }
      }
    } catch (_) {
      controller.dispose();
      if (mounted) {
        _hasLoadError = true;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _ensurePlayerInitialized() {
    _initializingTask ??= _createPlayer().whenComplete(() {
      _initializingTask = null;
    });
  }

  void _scheduleActionsAutoHide() {
    _actionsHideTimer?.cancel();
    _actionsHideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || !widget.showSeekBar) {
        return;
      }
      setState(() {
        _showDetailActions = false;
      });
    });
  }

  void _onScreenInteraction() {
    if (!widget.showSeekBar) {
      return;
    }
    if (!_showDetailActions) {
      setState(() {
        _showDetailActions = true;
      });
    }
    _scheduleActionsAutoHide();
  }

  void _togglePausePlay() {
    if (widget.isLocked || _isDisposed) {
      return;
    }
    _ensurePlayerInitialized();
    final controller = _controller?.videoPlayerController;
    final isPlaying = controller?.value.isPlaying ?? false;
    if (isPlaying) {
      _controller?.pause();
      setState(() {
        _pausedByUser = true;
      });
    } else {
      _requestPlay();
      if (!_reportedPlaybackStart) {
        _reportedPlaybackStart = true;
        widget.onPlaybackStarted();
      }
      setState(() {
        _pausedByUser = false;
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _actionsHideTimer?.cancel();
    _likeBurstTimer?.cancel();
    _activePlaybackOwner.removeListener(_onActivePlaybackChanged);
    if (_activePlaybackOwner.value == _ownerId) {
      _activePlaybackOwner.value = null;
    }
    final currentController = _controller;
    _controller = null;
    if (currentController != null) {
      final videoController = currentController.videoPlayerController;
      final currentPositionMs = videoController == null ? 0 : videoController.value.position.inMilliseconds;
      unawaited(widget.onSaveProgress(currentPositionMs));
      currentController.dispose();
    }
    super.dispose();
  }

  bool _canAutoPlay() {
    final routeCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    return _isVisible && routeCurrent && !_pausedByUser && !widget.isLocked;
  }

  void _requestPlay() {
    if (_isDisposed) {
      return;
    }
    if (_activePlaybackOwner.value != _ownerId) {
      _activePlaybackOwner.value = _ownerId;
    }
    _controller?.play();
    if (!_playTracked && widget.episode.bookId.isNotEmpty && widget.episode.episodeId.isNotEmpty) {
      _playTracked = true;
      unawaited(_trackPlay());
    }
  }

  void _onActivePlaybackChanged() {
    if (_isDisposed) {
      return;
    }
    if (_activePlaybackOwner.value != _ownerId) {
      _controller?.pause();
    }
  }

  Future<void> _loadEngagement() async {
    if (widget.episode.bookId.isEmpty || widget.episode.episodeId.isEmpty) {
      return;
    }
    try {
      final data = await ref.read(dramaRepositoryProvider).getEngagement(
            bookId: widget.episode.bookId,
            episodeId: widget.episode.episodeId,
          );
      if (!mounted || _isDisposed) {
        return;
      }
      setState(() {
        _engagement = data;
      });
    } catch (_) {}
  }

  Future<void> _trackPlay() async {
    try {
      await ref.read(dramaRepositoryProvider).trackPlay(
            bookId: widget.episode.bookId,
            episodeId: widget.episode.episodeId,
          );
      if (!mounted || _isDisposed) {
        return;
      }
      setState(() {
        final current = _engagement;
        if (current != null) {
          _engagement = EpisodeEngagement(
            likeCount: current.likeCount,
            commentCount: current.commentCount,
            playCount: current.playCount + 1,
            likedByMe: current.likedByMe,
            comments: current.comments,
          );
        }
      });
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    if (widget.episode.bookId.isEmpty || widget.episode.episodeId.isEmpty) {
      return;
    }
    try {
      final data = await ref.read(dramaRepositoryProvider).toggleLike(
            bookId: widget.episode.bookId,
            episodeId: widget.episode.episodeId,
          );
      if (!mounted || _isDisposed) {
        return;
      }
      setState(() {
        _engagement = data;
      });
      if (data.likedByMe) {
        _triggerLikeBurst();
      }
    } on DioException catch (error) {
      if (!mounted) return;
      final message = error.response?.statusCode == 401 ? 'Login dulu untuk like' : 'Gagal update like';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal update like')));
    }
  }

  void _triggerLikeBurst() {
    _likeBurstTimer?.cancel();
    setState(() {
      _showLikeBurst = true;
    });
    _likeBurstTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted || _isDisposed) {
        return;
      }
      setState(() {
        _showLikeBurst = false;
      });
    });
  }

  Future<void> _handleDoubleTapLike() async {
    final current = _engagement;
    if (current != null && current.likedByMe) {
      _triggerLikeBurst();
      return;
    }
    await _toggleLike();
  }

  Future<void> _openComments() async {
    if (widget.episode.bookId.isEmpty || widget.episode.episodeId.isEmpty || !mounted) {
      return;
    }
    final repo = ref.read(dramaRepositoryProvider);
    final firstPage = await repo.getCommentsPage(
      bookId: widget.episode.bookId,
      episodeId: widget.episode.episodeId,
      page: 1,
      limit: 20,
    );
    if (!mounted) {
      return;
    }
    var currentPage = firstPage.page;
    var total = firstPage.total;
    final comments = <EpisodeComment>[...firstPage.items];
    final pendingComments = <EpisodeComment>{};
    var isSending = false;
    var isLoadingMore = false;
    final inputController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hasMore = comments.length < total;
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 220,
                    child: comments.isEmpty
                        ? const Center(child: Text('Belum ada komentar'))
                        : ListView.separated(
                            itemCount: comments.length + (hasMore ? 1 : 0),
                            separatorBuilder: (_, __) => const Divider(height: 12),
                            itemBuilder: (_, index) {
                              if (index == comments.length) {
                                return TextButton(
                                  onPressed: isLoadingMore
                                      ? null
                                      : () async {
                                          setModalState(() {
                                            isLoadingMore = true;
                                          });
                                          try {
                                            final nextPage = currentPage + 1;
                                            final pageData = await repo.getCommentsPage(
                                              bookId: widget.episode.bookId,
                                              episodeId: widget.episode.episodeId,
                                              page: nextPage,
                                              limit: 20,
                                            );
                                            setModalState(() {
                                              currentPage = pageData.page;
                                              total = pageData.total;
                                              comments.addAll(pageData.items);
                                            });
                                          } finally {
                                            setModalState(() {
                                              isLoadingMore = false;
                                            });
                                          }
                                        },
                                  child: isLoadingMore
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text('Load more'),
                                );
                              }
                              final item = comments[index];
                              final pending = pendingComments.contains(item);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(item.memberName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      if (pending)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Text(
                                            'sending...',
                                            style: TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(item.content),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: inputController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Tulis komentar...'),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSending
                          ? null
                          : () async {
                              final text = inputController.text.trim();
                              if (text.isEmpty) {
                                return;
                              }
                              final optimisticComment = EpisodeComment(
                                memberId: 'me',
                                memberName: 'You',
                                content: text,
                                createdAt: DateTime.now(),
                              );
                              setModalState(() {
                                isSending = true;
                                comments.insert(0, optimisticComment);
                                pendingComments.add(optimisticComment);
                                total += 1;
                              });
                              final prevEngagement = _engagement;
                              setState(() {
                                if (prevEngagement != null) {
                                  _engagement = EpisodeEngagement(
                                    likeCount: prevEngagement.likeCount,
                                    commentCount: prevEngagement.commentCount + 1,
                                    playCount: prevEngagement.playCount,
                                    likedByMe: prevEngagement.likedByMe,
                                    comments: <EpisodeComment>[optimisticComment, ...prevEngagement.comments],
                                  );
                                }
                              });
                              inputController.clear();
                              FocusManager.instance.primaryFocus?.unfocus();
                              try {
                                final data = await repo.addComment(
                                  bookId: widget.episode.bookId,
                                  episodeId: widget.episode.episodeId,
                                  content: text,
                                );
                                if (!mounted) return;
                                setState(() {
                                  _engagement = data;
                                });
                                setModalState(() {
                                  pendingComments.remove(optimisticComment);
                                });
                              } on DioException catch (error) {
                                if (!mounted) return;
                                setModalState(() {
                                  comments.remove(optimisticComment);
                                  pendingComments.remove(optimisticComment);
                                  total = total > 0 ? total - 1 : 0;
                                });
                                setState(() {
                                  _engagement = prevEngagement;
                                });
                                final message = (error.response?.data is Map<String, dynamic>)
                                    ? ((error.response?.data['message'] ?? '').toString())
                                    : '';
                                if (message.isNotEmpty) {
                                  messenger.showSnackBar(SnackBar(content: Text(message)));
                                  return;
                                }
                                final fallback = error.response?.statusCode == 401 ? 'Login dulu untuk comment' : 'Gagal kirim komentar';
                                messenger.showSnackBar(SnackBar(content: Text(fallback)));
                              } catch (_) {
                                if (!mounted) return;
                                setModalState(() {
                                  comments.remove(optimisticComment);
                                  pendingComments.remove(optimisticComment);
                                  total = total > 0 ? total - 1 : 0;
                                });
                                setState(() {
                                  _engagement = prevEngagement;
                                });
                                messenger.showSnackBar(const SnackBar(content: Text('Gagal kirim komentar')));
                              } finally {
                                if (mounted) {
                                  setModalState(() {
                                    isSending = false;
                                  });
                                }
                              }
                            },
                      child: isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Kirim'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    inputController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.shortestSide >= 600;
    _isTabletLayout = isTablet;
    final showRightActions = !widget.showSeekBar || _showDetailActions;
    final showBottomInfo = !widget.showSeekBar;
    final showGradient = !widget.showSeekBar;

    final videoStack = Stack(
      fit: StackFit.expand,
      children: [
      if (_controller != null)
        _buildVideoSurface(isTablet, _controller!)
      else
        Container(color: Colors.black),
      if (_controller == null && widget.episode.videoUrl.isEmpty)
        const Center(child: CircularProgressIndicator()),
      if (_isInitializing)
        const Center(child: CircularProgressIndicator()),
      if (_hasLoadError)
        Center(
          child: FilledButton.tonal(
            onPressed: () {
              setState(() {
                _hasLoadError = false;
              });
              _ensurePlayerInitialized();
            },
            child: const Text('Retry Video'),
          ),
        ),
      if (showGradient)
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.15), Colors.black.withValues(alpha: 0.65)],
              ),
            ),
          ),
        ),
      if (showRightActions)
        Positioned(
          right: 12,
          bottom: 120,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text('Ep ${widget.episode.episodeNumber}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 14),
              _ActionCircle(
                icon: (_engagement?.likedByMe ?? false) ? Icons.favorite : Icons.favorite_border,
                label: _engagement == null ? 'Like' : '${_engagement!.likeCount}',
                onTap: () async {
                  await _toggleLike();
                  ref.read(favoritesProvider.notifier).toggleFavorite(widget.episode.episodeId);
                },
              ),
              const SizedBox(height: 14),
              _ActionCircle(
                icon: Icons.chat_bubble_outline,
                label: _engagement == null ? 'Comment' : '${_engagement!.commentCount}',
                onTap: _openComments,
              ),
              const SizedBox(height: 14),
              _ActionCircle(
                icon: Icons.share_outlined,
                label: _engagement == null ? 'Share' : '${_engagement!.playCount}',
                onTap: () {},
              ),
              const SizedBox(height: 14),
              _ActionCircle(icon: Icons.person_outline, label: 'Profile', onTap: () {}),
            ],
          ),
        ),
      if (showBottomInfo)
        Positioned(
          left: 14,
          right: 90,
          bottom: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.episode.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(widget.episode.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (widget.onWatchFull != null) ...[
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () {
                    _controller?.pause();
                    widget.onWatchFull!();
                  },
                  child: const Text('Watch Full'),
                ),
              ]
            ],
          ),
        ),
      if (_pausedByUser && !widget.isLocked && showBottomInfo)
        const Center(
          child: Icon(Icons.play_circle_fill_rounded, size: 76, color: Colors.white70),
        ),
      IgnorePointer(
        child: AnimatedOpacity(
          opacity: _showLikeBurst ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: const Center(
            child: Icon(Icons.favorite, size: 88, color: Colors.redAccent),
          ),
        ),
      ),
      if (widget.isLocked)
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
          child: Container(
            color: Colors.black.withValues(alpha: 0.45),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.lockTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                FilledButton(onPressed: widget.onGoPremium, child: Text(widget.lockButtonText)),
              ],
            ),
          ),
        ),
    ],
    );

    return VisibilityDetector(
      key: ValueKey<String>(widget.episode.episodeId),
      onVisibilityChanged: (info) {
        _isVisible = info.visibleFraction > 0.6;
        if (widget.isLocked) return;
        if (_canAutoPlay()) {
          _ensurePlayerInitialized();
          _requestPlay();
          if (!_reportedPlaybackStart) {
            _reportedPlaybackStart = true;
            widget.onPlaybackStarted();
          }
        } else {
          _controller?.pause();
        }
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _onScreenInteraction(),
        child: widget.showSeekBar
            ? videoStack
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePausePlay,
                onDoubleTap: _handleDoubleTapLike,
                child: videoStack,
              ),
      ),
    );
  }

  Widget _buildVideoSurface(bool isTablet, BetterPlayerController controller) {
    if (!isTablet) {
      return BetterPlayer(controller: controller);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final videoWidth = (constraints.maxHeight * 9) / 16;
        final clampedWidth = videoWidth > constraints.maxWidth ? constraints.maxWidth : videoWidth;
        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: clampedWidth,
            height: constraints.maxHeight,
            child: BetterPlayer(controller: controller),
          ),
        );
      },
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(icon),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

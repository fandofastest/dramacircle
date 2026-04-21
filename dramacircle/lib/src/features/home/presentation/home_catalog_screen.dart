import 'package:cached_network_image/cached_network_image.dart';
import 'package:dramacircle/src/core/providers.dart';
import 'package:dramacircle/src/data/models/drama_models.dart';
import 'package:dramacircle/src/features/detail/presentation/detail_screen.dart';
import 'package:dramacircle/src/features/fyp/providers/fyp_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeCatalogScreen extends ConsumerStatefulWidget {
  const HomeCatalogScreen({super.key});

  @override
  ConsumerState<HomeCatalogScreen> createState() => _HomeCatalogScreenState();
}

class _HomeCatalogScreenState extends ConsumerState<HomeCatalogScreen> {
  List<DramaItem> _forYou = <DramaItem>[];
  List<DramaItem> _latest = <DramaItem>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    final repo = ref.read(dramaRepositoryProvider);
    final data = await Future.wait([
      repo.forYou(page: 1),
      repo.latest(),
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      _forYou = data[0];
      _latest = data[1];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final continueWatchingMap = ref.read(localStoreProvider).continueWatching;
    final continueIds = continueWatchingMap.keys.map((key) => key.toString()).toSet();
    final continueWatchingItems = <DramaItem>[
      ..._forYou.where((item) => continueIds.contains(item.bookId)),
      ..._latest.where((item) => continueIds.contains(item.bookId)),
    ];
    final uniqueContinueWatching = _uniqueByBookId(continueWatchingItems);

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Home',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ringkasan cepat buat lanjut nonton.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (uniqueContinueWatching.isNotEmpty) ...[
                    const _SectionTitle('Lanjut Nonton'),
                    const SizedBox(height: 10),
                    _DramaHorizontal(items: uniqueContinueWatching.take(8).toList()),
                    const SizedBox(height: 20),
                  ],
                  const _SectionTitle('Untuk Kamu'),
                  const SizedBox(height: 10),
                  _DramaHorizontal(items: _forYou.take(8).toList()),
                  const SizedBox(height: 20),
                  const _SectionTitle('Terbaru'),
                  const SizedBox(height: 10),
                  _DramaGrid(items: _latest.take(8).toList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DramaItem> _uniqueByBookId(List<DramaItem> items) {
    final seen = <String>{};
    final output = <DramaItem>[];
    for (final item in items) {
      if (item.bookId.isEmpty || seen.contains(item.bookId)) {
        continue;
      }
      seen.add(item.bookId);
      output.add(item);
    }
    return output;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700));
  }
}

class _DramaHorizontal extends StatelessWidget {
  const _DramaHorizontal({required this.items});
  final List<DramaItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return _DramaCard(item: items[index], width: 160);
        },
      ),
    );
  }
}

class _DramaGrid extends StatelessWidget {
  const _DramaGrid({required this.items});
  final List<DramaItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.76,
      ),
      itemBuilder: (context, index) => _DramaCard(item: items[index]),
    );
  }
}

class _DramaCard extends StatelessWidget {
  const _DramaCard({required this.item, this.width});
  final DramaItem item;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailScreen(bookId: item.bookId))),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.cover ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorWidget: (_, __, ___) => Container(color: Colors.grey.shade900),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

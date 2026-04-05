import 'package:cached_network_image/cached_network_image.dart';
import 'package:dramacircle/src/data/models/drama_models.dart';
import 'package:dramacircle/src/features/detail/presentation/detail_screen.dart';
import 'package:dramacircle/src/features/fyp/providers/fyp_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  List<DramaItem> _trending = <DramaItem>[];
  List<DramaItem> _latest = <DramaItem>[];
  List<DramaItem> _search = <DramaItem>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(dramaRepositoryProvider);
    final data = await Future.wait([repo.trending(), repo.latest()]);
    if (mounted) {
      setState(() {
        _trending = data[0];
        _latest = data[1];
        _loading = false;
      });
    }
  }

  Future<void> _searchDrama(String query) async {
    if (query.isEmpty) {
      setState(() => _search = <DramaItem>[]);
      return;
    }
    final data = await ref.read(dramaRepositoryProvider).search(query);
    if (mounted) {
      setState(() => _search = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            onChanged: _searchDrama,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search drama'),
          ),
          const SizedBox(height: 16),
          if (_search.isNotEmpty) ...[
            const _SectionTitle('Search'),
            const SizedBox(height: 10),
            _DramaGrid(items: _search),
            const SizedBox(height: 20),
          ],
          const _SectionTitle('Trending'),
          const SizedBox(height: 10),
          _DramaHorizontal(items: _trending),
          const SizedBox(height: 20),
          const _SectionTitle('Latest'),
          const SizedBox(height: 10),
          _DramaGrid(items: _latest),
        ],
      ),
    );
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
          final item = items[index];
          return _DramaCard(item: item, width: 160);
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
      itemBuilder: (context, index) {
        return _DramaCard(item: items[index]);
      },
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
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailScreen(bookId: item.bookId)));
      },
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

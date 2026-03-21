import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/mosque_info.dart';
import '../../providers.dart';

class MosqueSearchWidget extends ConsumerStatefulWidget {
  final void Function(MosqueInfo mosque) onMosqueSelected;

  const MosqueSearchWidget({
    super.key,
    required this.onMosqueSelected,
  });

  @override
  ConsumerState<MosqueSearchWidget> createState() => _MosqueSearchWidgetState();
}

class _MosqueSearchWidgetState extends ConsumerState<MosqueSearchWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(mosqueSearchProvider);

    return Column(
      children: [
        TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.white, fontSize: 20),
          decoration: InputDecoration(
            hintText: 'Search mosque by name or city...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 18,
            ),
          ),
          onChanged: (query) {
            ref.read(mosqueSearchProvider.notifier).search(query);
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: searchState.when(
            data: (results) {
              if (results.isEmpty && _controller.text.length >= 2) {
                return const Center(
                  child: Text(
                    'No mosques found',
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                );
              }
              if (results.isEmpty) {
                return const Center(
                  child: Text(
                    'Type at least 2 characters to search',
                    style: TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                );
              }
              return ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final mosque = results[index];
                  return _MosqueTile(
                    mosque: mosque,
                    onTap: () => widget.onMosqueSelected(mosque),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Search failed: $e',
                    style: const TextStyle(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MosqueTile extends StatelessWidget {
  final MosqueInfo mosque;
  final VoidCallback onTap;

  const _MosqueTile({required this.mosque, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timesStr = mosque.todayTimes != null && mosque.todayTimes!.length >= 6
        ? 'Fajr ${mosque.todayTimes![0]}  |  Dhuhr ${mosque.todayTimes![2]}  |  Maghrib ${mosque.todayTimes![4]}'
        : '';

    return Card(
      color: Colors.white.withOpacity(0.08),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.mosque, color: Colors.tealAccent, size: 36),
        title: Text(
          mosque.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mosque.localisation != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  mosque.localisation!,
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (timesStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  timesStr,
                  style: const TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}

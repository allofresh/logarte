import 'package:flutter/material.dart';
import 'package:logarte/logarte.dart';
import 'package:logarte/src/console/logarte_theme_wrapper.dart';
import 'package:logarte/src/extensions/entry_extensions.dart';
import 'package:logarte/src/extensions/object_extensions.dart';
import 'package:logarte/src/extensions/string_extensions.dart';

enum MenuItem { copy, copyCurl }

class NetworkLogEntryDetailsScreen extends StatefulWidget {
  final NetworkLogarteEntry entry;
  final Logarte instance;

  const NetworkLogEntryDetailsScreen(
    this.entry, {
    Key? key,
    required this.instance,
  }) : super(key: key);

  @override
  State<NetworkLogEntryDetailsScreen> createState() =>
      _NetworkLogEntryDetailsScreenState();
}

class _NetworkLogEntryDetailsScreenState
    extends State<NetworkLogEntryDetailsScreen> {
  final TextEditingController _controller = TextEditingController();
  String _searchText = '';

  void handleClick(BuildContext context, MenuItem item) {
    switch (item) {
      case MenuItem.copy:
        final text = widget.entry.toString();
        text.copyToClipboard(context);
        break;
      case MenuItem.copyCurl:
        final cmd = widget.entry.toCurlCommand();
        cmd.copyToClipboard(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LogarteThemeWrapper(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: Navigator.of(context).pop,
            icon: const Icon(Icons.arrow_back),
          ),
          title: TextField(
            controller: _controller,
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search',
              filled: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _controller.clear,
              ),
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.share),
              onPressed: () {
                final text = widget.entry.toString();
                widget.instance.onShare?.call(text);
              },
            ),
            PopupMenuButton<MenuItem>(
              tooltip: 'More',
              icon: const Icon(Icons.more_vert),
              onSelected: (item) => handleClick(context, item),
              itemBuilder: (_) => <PopupMenuEntry<MenuItem>>[
                const PopupMenuItem<MenuItem>(
                  value: MenuItem.copy,
                  child: Text('Copy'),
                ),
                const PopupMenuItem<MenuItem>(
                  value: MenuItem.copyCurl,
                  child: Text('Copy as cURL'),
                ),
              ],
            ),
            const SizedBox(width: 12.0),
          ],
        ),
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Request'),
                  Tab(text: 'Response'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    Scrollbar(
                      child: ListView(
                        children: [
                          SelectableCopiableTile(
                            title: 'METHOD',
                            subtitle: widget.entry.request.method,
                          ),
                          const Divider(height: 0.0),
                          SelectableCopiableTile(
                            title: 'URL',
                            subtitle: widget.entry.request.url,
                            searchText: _searchText,
                          ),
                          const Divider(height: 0.0),
                          SelectableCopiableTile(
                            title: 'HEADERS',
                            subtitle: widget.entry.request.headers.prettyJson,
                            searchText: _searchText,
                          ),
                          if (widget.entry.request.method != 'GET') ...[
                            const Divider(height: 0.0),
                            SelectableCopiableTile(
                              title: 'BODY',
                              subtitle: widget.entry.request.body.prettyJson,
                              searchText: _searchText,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Scrollbar(
                      child: ListView(
                        children: [
                          SelectableCopiableTile(
                            title: 'STATUS CODE',
                            subtitle:
                                widget.entry.response.statusCode.toString(),
                          ),
                          const Divider(height: 0.0),
                          SelectableCopiableTile(
                            title: 'HEADERS',
                            subtitle: widget.entry.response.headers.prettyJson,
                            searchText: _searchText,
                          ),
                          const Divider(height: 0.0),
                          SelectableCopiableTile(
                            title: 'BODY',
                            subtitle: widget.entry.response.body.prettyJson,
                            searchText: _searchText,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectableCopiableTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String searchText;

  const SelectableCopiableTile({
    required this.title,
    required this.subtitle,
    this.searchText = '',
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => _copyToClipboard(context),
      title: SelectableText(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
        onTap: () => _copyToClipboard(context),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: SelectableText.rich(
          TextSpan(
            children: _buildHighlightedTextSpans(),
          ),
          onTap: () => _copyToClipboard(context),
        ),
      ),
      // trailing: const Icon(Icons.copy),
    );
  }

  List<TextSpan> _buildHighlightedTextSpans() {
    if (searchText.isEmpty) {
      return [TextSpan(text: subtitle)];
    }

    final List<TextSpan> spans = [];
    final String lowerSubtitle = subtitle.toLowerCase();
    final String lowerSearchText = searchText.toLowerCase();

    int currentIndex = 0;

    while (currentIndex < subtitle.length) {
      final int matchIndex =
          lowerSubtitle.indexOf(lowerSearchText, currentIndex);

      if (matchIndex == -1) {
        // No more matches, add remaining text
        spans.add(TextSpan(text: subtitle.substring(currentIndex)));
        break;
      }

      // Add text before the match
      if (matchIndex > currentIndex) {
        spans.add(TextSpan(text: subtitle.substring(currentIndex, matchIndex)));
      }

      // Add the highlighted match
      spans.add(TextSpan(
        text: subtitle.substring(matchIndex, matchIndex + searchText.length),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));

      currentIndex = matchIndex + searchText.length;
    }

    return spans;
  }

  Future<void> _copyToClipboard(BuildContext context) {
    return subtitle.copyToClipboard(context);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'l10n/notification_labels.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_room_screen.dart';
import 'screens/community_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/profile_screen.dart';
import 'state/app_state.dart';
import 'state/locale_state.dart';

class KkiriApp extends StatelessWidget {
  const KkiriApp({super.key});

  @override
  Widget build(BuildContext context) {
    final LocaleState localeState = context.watch<LocaleState>();

    final GoRouter router = GoRouter(
      initialLocation: '/home/chat',
      routes: [
        ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) {
            return _KkiriShell(location: state.uri.toString(), child: child);
          },
          routes: [
            GoRoute(
              path: '/home/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/home/friends',
              builder: (_, __) => const FriendsScreen(),
            ),
            GoRoute(
              path: '/home/chat',
              builder: (_, __) => const ChatListScreen(),
              routes: [
                GoRoute(
                  path: 'room/:threadId',
                  builder: (BuildContext context, GoRouterState state) =>
                      ChatRoomScreen(threadId: state.pathParameters['threadId']!),
                ),
              ],
            ),
            GoRoute(
              path: '/home/community',
              builder: (_, __) => const CommunityScreen(),
            ),
          ],
        ),
      ],
    );

    final ThemeData theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFEE500),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFFDFBF4),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFEE500),
        foregroundColor: Colors.black87,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFFFF3A0),
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w600)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      useMaterial3: true,
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Kkiri',
      theme: theme,
      locale: localeState.locale,
      routerConfig: router,
      supportedLocales: AppLocalizations.supportedLanguageCodes
          .map((String code) => Locale(code))
          .toList(),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

enum _ShellMenuAction { changePhoto, notifications, language, support }

class _KkiriShell extends StatelessWidget {
  const _KkiriShell({required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final AppLocalizations l = AppLocalizations.of(context);
    final LocaleState localeState = context.watch<LocaleState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final SearchSelection? result = await showSearch<SearchSelection?>(
                context: context,
                delegate: _KkiriSearchDelegate(state, l),
              );
              if (result == null) return;
              switch (result.type) {
                case SearchResultType.friend:
                  state.openChat(context, result.id);
                  break;
                case SearchResultType.chat:
                  context.go('/home/chat/room/${result.id}');
                  break;
                case SearchResultType.post:
                  context.go('/home/community');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.communityTitle)),
                  );
                  break;
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => state.handleAddFriendDialog(context, l),
          ),
          PopupMenuButton<_ShellMenuAction>(
            onSelected: (value) => _onMenuSelected(context, value, state, localeState, l),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<_ShellMenuAction>(
                value: _ShellMenuAction.changePhoto,
                child: Text(l.changeProfilePhoto),
              ),
              PopupMenuItem<_ShellMenuAction>(
                value: _ShellMenuAction.notifications,
                child: Text(l.notificationSettings),
              ),
              PopupMenuItem<_ShellMenuAction>(
                value: _ShellMenuAction.language,
                child: Text(l.languageSettings),
              ),
              PopupMenuItem<_ShellMenuAction>(
                value: _ShellMenuAction.support,
                child: Text(l.customerSupport),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: _BottomNav(location: location),
    );
  }

  void _onMenuSelected(
    BuildContext context,
    _ShellMenuAction action,
    AppState state,
    LocaleState localeState,
    AppLocalizations l,
  ) {
    switch (action) {
      case _ShellMenuAction.changePhoto:
        _showAvatarSheet(context, state, l);
        break;
      case _ShellMenuAction.notifications:
        _showNotificationSheet(context, l);
        break;
      case _ShellMenuAction.language:
        _showLanguageSheet(context, localeState, l);
        break;
      case _ShellMenuAction.support:
        _showSupportDialog(context, l);
        break;
    }
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    int currentIndex = 0;
    if (location.startsWith('/home/friends')) currentIndex = 1;
    if (location.startsWith('/home/chat')) currentIndex = 2;
    if (location.startsWith('/home/community')) currentIndex = 3;

    return NavigationBar(
      selectedIndex: currentIndex,
      destinations: [
        NavigationDestination(icon: const Icon(Icons.person), label: l.tabProfile),
        NavigationDestination(icon: const Icon(Icons.location_on), label: l.tabFriends),
        NavigationDestination(icon: const Icon(Icons.chat_bubble), label: l.tabChats),
        NavigationDestination(icon: const Icon(Icons.article), label: l.tabCommunity),
      ],
      onDestinationSelected: (int index) {
        switch (index) {
          case 0:
            context.go('/home/profile');
            break;
          case 1:
            context.go('/home/friends');
            break;
          case 2:
            context.go('/home/chat');
            break;
          case 3:
            context.go('/home/community');
            break;
        }
      },
    );
  }
}

void _showAvatarSheet(BuildContext context, AppState state, AppLocalizations l) {
  const List<String> avatars = <String>[
    'https://images.unsplash.com/photo-1521572267360-ee0c2909d518',
    'https://images.unsplash.com/photo-1502767089025-6572583495b0',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1',
  ];
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.changeProfilePhoto, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: avatars
                  .map(
                    (String url) => GestureDetector(
                      onTap: () {
                        state.updateAvatar(url);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.ok)),
                        );
                      },
                      child: CircleAvatar(radius: 36, backgroundImage: NetworkImage(url)),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    },
  );
}

void _showNotificationSheet(BuildContext context, AppLocalizations l) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Consumer<AppState>(
          builder: (BuildContext context, AppState value, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.notificationSettings, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...value.notificationOptions.entries.map((entry) {
                  return SwitchListTile(
                    title: Text(notificationLabel(l, entry.key)),
                    value: entry.value,
                    onChanged: (bool toggled) => value.updateNotification(entry.key, toggled),
                  );
                }),
              ],
            );
          },
        ),
      );
    },
  );
}

void _showLanguageSheet(BuildContext context, LocaleState localeState, AppLocalizations l) {
  const Map<String, String> languageNames = <String, String>{
    'ko': '한국어',
    'en': 'English',
    'zh': '中文',
    'hi': 'हिन्दी',
    'ja': '日本語',
  };
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.languageSettings, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(l.languageSettingsDescription,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            ...AppLocalizations.supportedLanguageCodes.map((String code) {
              final bool selected = localeState.locale?.languageCode == code;
              return ListTile(
                leading: selected
                    ? Icon(Icons.radio_button_checked, color: Theme.of(context).colorScheme.primary)
                    : const Icon(Icons.radio_button_off),
                title: Text(languageNames[code] ?? code.toUpperCase()),
                onTap: () {
                  localeState.setLocale(Locale(code));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l.languageUpdated)));
                },
              );
            }),
          ],
        ),
      );
    },
  );
}

void _showSupportDialog(BuildContext context, AppLocalizations l) {
  showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(l.customerSupport),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.customerSupportDescription),
            const SizedBox(height: 12),
            Text(l.supportEmail, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.ok),
          ),
        ],
      );
    },
  );
}

enum SearchResultType { friend, chat, post }

class SearchSelection {
  SearchSelection(this.type, this.id);

  final SearchResultType type;
  final String id;
}

class _KkiriSearchDelegate extends SearchDelegate<SearchSelection?> {
  _KkiriSearchDelegate(this.state, this.localization)
      : super(searchFieldLabel: localization.searchHint);

  final AppState state;
  final AppLocalizations localization;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final String lower = query.toLowerCase();
    final List<_SearchEntry> results = <_SearchEntry>[];

    for (final thread in state.threads) {
      final friend = state.getById(thread.friendId);
      if (lower.isEmpty ||
          friend.name.toLowerCase().contains(lower) ||
          (thread.lastMessage?.toLowerCase().contains(lower) ?? false)) {
        results.add(_SearchEntry(
          type: SearchResultType.chat,
          id: thread.id,
          title: friend.name,
          subtitle: thread.lastMessage ?? localization.startChat,
          avatarUrl: friend.avatarUrl,
          category: localization.searchChatsLabel,
        ));
      }
    }

    for (final friend in state.friends) {
      if (lower.isEmpty ||
          friend.name.toLowerCase().contains(lower) ||
          friend.statusMessage.toLowerCase().contains(lower)) {
        results.add(_SearchEntry(
          type: SearchResultType.friend,
          id: friend.id,
          title: friend.name,
          subtitle: friend.statusMessage,
          avatarUrl: friend.avatarUrl,
          category: localization.searchFriendsLabel,
        ));
      }
    }

    for (final post in state.posts) {
      if (lower.isEmpty || post.content.toLowerCase().contains(lower)) {
        results.add(_SearchEntry(
          type: SearchResultType.post,
          id: post.id,
          title: state.getById(post.authorId).name,
          subtitle: post.content,
          avatarUrl: state.getById(post.authorId).avatarUrl,
          category: localization.searchPostsLabel,
        ));
      }
    }

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(localization.friendNotFound),
        ),
      );
    }

    results.sort((a, b) => a.category.compareTo(b.category));

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (BuildContext context, int index) {
        final _SearchEntry entry = results[index];
        return ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(entry.avatarUrl)),
          title: Text(entry.title),
          subtitle: Text(entry.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(entry.category),
          onTap: () => close(context, SearchSelection(entry.type, entry.id)),
        );
      },
    );
  }
}

class _SearchEntry {
  _SearchEntry({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.avatarUrl,
    required this.category,
  });

  final SearchResultType type;
  final String id;
  final String title;
  final String subtitle;
  final String avatarUrl;
  final String category;
}

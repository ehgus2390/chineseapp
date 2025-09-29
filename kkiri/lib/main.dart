import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

// ======================
// AppState (상태 관리)
// ======================
class AppState extends ChangeNotifier {
  String? userName;
  final List<Post> posts = [];

  void login(String name) {
    userName = name;
    notifyListeners();
  }

  void addPost(String content) {
    posts.add(Post(content: content, author: userName ?? "익명"));
    notifyListeners();
  }
  void addComment(int postIndex, String commentContent) {
    final post = posts[postIndex];
    post.comments.add(
      Comment(content: commentContent, author: userName ?? "익명"),
    );
    notifyListeners();
  }
  bool get isLoggedIn => userName != null;
}

class Post {
  final String content;
  final String author;
  final List<Comment> comments;

  Post({
    required this.content,
    required this.author,
    List<Comment>? comments,
  }) : comments = comments ?? [];
}
class Comment {
  final String content;
  final String author;
  Comment({required this.content, required this.author});
}

// ======================
// 메인 앱
// ======================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Community App',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const RootPage(),
      ),
    );
  }
}

// ======================
// RootPage: 로그인 여부 체크
// ======================
class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.isLoggedIn) {
          return const MainScreen();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

// ======================
// 로그인 페이지
// ======================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("로그인")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("닉네임을 입력하세요"),
            TextField(controller: _controller),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  Provider.of<AppState>(context, listen: false)
                      .login(_controller.text);
                }
              },
              child: const Text("로그인"),
            )
          ],
        ),
      ),
    );
  }
}

// ======================
// 메인 화면 (탭 구조)
// ======================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    TimetablePage(),
    BoardPage(),
    ChatPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Communication for students"),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
          IconButton(icon: const Icon(Icons.account_circle), onPressed: () {}),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: "Schedule"),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: "Noticeboard"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Cheating"),
        ],
      ),
    );
  }
}

// ======================
// 페이지 예시
// ======================
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("홈 화면 - 교내소식, 인기글, 링크"));
  }
}

class TimetablePage extends StatelessWidget {
  const TimetablePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("시간표 만들기 화면"));
  }
}

// ======================
// 게시판 페이지 (글쓰기 가능)
// ======================
class BoardPage extends StatelessWidget {
  const BoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      body: ListView.builder(
        itemCount: appState.posts.length,
        itemBuilder: (context, index) {
          final post = appState.posts[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ExpansionTile(
              title: Text(post.content),
              subtitle: Text("Host: ${post.author}"),
              children: [
                // 댓글 목록
                ...post.comments.map(
                      (c) => ListTile(
                    title: Text(c.content),
                    subtitle: Text("작성자: ${c.author}"),
                  ),
                ),
                // 댓글 작성 버튼
                TextButton.icon(
                  icon: const Icon(Icons.comment),
                  label: const Text("댓글 달기"),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => CommentDialog(postIndex: index),
                    );
                  },
                )
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const PostDialog(),
          );
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}
// ======================
// 댓글작성 다이얼로그
// ======================
class CommentDialog extends StatefulWidget {
  final int postIndex;
  const CommentDialog({super.key, required this.postIndex});

  @override
  State<CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<CommentDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("댓글 작성"),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: "댓글을 입력하세요"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("취소"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Provider.of<AppState>(context, listen: false)
                  .addComment(widget.postIndex, _controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text("등록"),
        ),
      ],
    );
  }
}

// ======================
// 글쓰기 다이얼로그
// ======================
class PostDialog extends StatefulWidget {
  const PostDialog({super.key});

  @override
  State<PostDialog> createState() => _PostDialogState();
}

class _PostDialogState extends State<PostDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("새 게시글 작성"),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: "내용을 입력하세요"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("취소"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Provider.of<AppState>(context, listen: false)
                  .addPost(_controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text("등록"),
        ),
      ],
    );
  }
}

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("채팅 화면"));
  }
}

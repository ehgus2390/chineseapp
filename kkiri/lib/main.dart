import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '대학 커뮤니티',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// ------------------ STATE 관리 ------------------

class AppState extends ChangeNotifier {
  String? userName;

  void login(String name) {
    userName = name;
    notifyListeners();
  }

  void logout() {
    userName = null;
    notifyListeners();
  }
}

// ------------------ 로그인 페이지 ------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎓 대학 커뮤니티 로그인', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: '닉네임 입력'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  appState.login(controller.text.trim().isEmpty ? "익명" : controller.text.trim());
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
                },
                child: const Text('입장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------ 메인 화면 ------------------

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;
  final pages = [
    const HomePage(),
    const BoardPage(),
    const ChatPage(),
    const MyPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '홈'),
          NavigationDestination(icon: Icon(Icons.forum), label: '게시판'),
          NavigationDestination(icon: Icon(Icons.chat), label: '채팅'),
          NavigationDestination(icon: Icon(Icons.person), label: '내정보'),
        ],
      ),
    );
  }
}

// ------------------ 홈 ------------------

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('홈')),
      body: Center(
        child: Text(
          '안녕하세요, ${appState.userName ?? "익명"}님 👋\n오늘도 좋은 하루 되세요!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

// ------------------ 게시판 ------------------

class BoardPage extends StatelessWidget {
  const BoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('게시판')),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.getPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("아직 게시글이 없습니다."));

          return ListView(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['content'] ?? ''),
                  subtitle: Text("작성자: ${data['author']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${data['likes'] ?? 0}'),
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () => firestore.likePost(doc.id),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CommentPage(postId: doc.id),
                    ));
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => PostDialog(firestore: firestore, author: appState.userName ?? "익명"),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PostDialog extends StatefulWidget {
  final FirestoreService firestore;
  final String author;
  const PostDialog({super.key, required this.firestore, required this.author});

  @override
  State<PostDialog> createState() => _PostDialogState();
}

class _PostDialogState extends State<PostDialog> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('새 게시글 작성'),
      content: TextField(controller: controller, decoration: const InputDecoration(hintText: '내용을 입력하세요')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        ElevatedButton(
          onPressed: () async {
            await widget.firestore.addPost(widget.author, controller.text);
            Navigator.pop(context);
          },
          child: const Text('등록'),
        )
      ],
    );
  }
}

// ------------------ 댓글 ------------------

class CommentPage extends StatefulWidget {
  final String postId;
  const CommentPage({super.key, required this.postId});

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final _firestore = FirebaseFirestore.instance;
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("댓글")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('posts').doc(widget.postId).collection('comments').orderBy('createdAt').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final comments = snapshot.data!.docs;
                return ListView(
                  children: comments.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['content'] ?? ''),
                      subtitle: Text(data['author'] ?? ''),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: '댓글 입력...'))),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  _firestore.collection('posts').doc(widget.postId).collection('comments').add({
                    'author': appState.userName ?? '익명',
                    'content': _controller.text,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  _controller.clear();
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}

// ------------------ 채팅 ------------------

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _firestore = FirebaseFirestore.instance;
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("실시간 채팅")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('chats/general/messages').orderBy('timestamp').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                return ListView(
                  children: messages.map((doc) {
                    final msg = doc.data() as Map<String, dynamic>;
                    return ListTile(title: Text(msg['text']), subtitle: Text(msg['sender']));
                  }).toList(),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: "메시지 입력"))),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  _firestore.collection('chats/general/messages').add({
                    'text': _controller.text,
                    'sender': appState.userName ?? '익명',
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  _controller.clear();
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}

// ------------------ 마이페이지 ------------------

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('내 정보')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('닉네임: ${appState.userName ?? "익명"}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                appState.logout();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
              },
              child: const Text('로그아웃'),
            )
          ],
        ),
      ),
    );
  }
}

// ------------------ FIRESTORE SERVICE ------------------

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addPost(String author, String content) async {
    await _db.collection('posts').add({
      'author': author,
      'content': content,
      'likes': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> likePost(String postId) async {
    final postRef = _db.collection('posts').doc(postId);
    await _db.runTransaction((tx) async {
      final doc = await tx.get(postRef);
      if (doc.exists) {
        final likes = (doc['likes'] ?? 0) + 1;
        tx.update(postRef, {'likes': likes});
      }
    });
  }

  Stream<QuerySnapshot> getPosts() {
    return _db.collection('posts').orderBy('createdAt', descending: true).snapshots();
  }
}

// ------------------ NOTIFICATION SERVICE ------------------

class NotificationService {
  final _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    await _fcm.requestPermission();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 알림: ${message.notification?.title}');
    });
  }
}

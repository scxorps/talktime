import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talktime/widgets/menu_bar.dart'; // Import MenuBar widget

final _firestore = FirebaseFirestore.instance;
User? signedInUser;

class ChatScreen extends StatefulWidget {
  static const String screenRoute = 'chat_screen';
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String? messagetext;
  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    _drawerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _drawerAnimation = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOut,
    );
  }

  void getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        signedInUser = user;
      });
      print('Signed in user email: ${signedInUser!.email}');
    }
  }

  void _toggleDrawer() {
    if (_drawerController.isDismissed) {
      _drawerController.forward();
    } else {
      _drawerController.reverse();
    }
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the back arrow
        backgroundColor: const Color.fromARGB(255, 23, 245, 97),
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 25),
            SizedBox(width: 10),
            Text('TalkTime'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: _toggleDrawer,
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MessagesStreamBuilder(),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Color.fromARGB(255, 23, 245, 97),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageTextController,
                          onChanged: (value) {
                            messagetext = value;
                          },
                          decoration: InputDecoration(
                            hintText: 'Type a message',
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 20,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          messageTextController.clear();
                          if (messagetext != null && messagetext!.isNotEmpty) {
                            _firestore.collection('messages').add({
                              'text': messagetext,
                              'sender': signedInUser?.email,
                              'time': FieldValue.serverTimestamp(),
                            });
                            messagetext = null;
                          }
                        },
                        child: Text(
                          'Send',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SlideTransition(
            position: _drawerAnimation.drive(
              Tween<Offset>(
                begin: Offset(1.0, 0.0),
                end: Offset.zero,
              ),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: MenuBare(), // Use the MenuBar widget here
            ),
          ),
        ],
      ),
    );
  }
}

class MessagesStreamBuilder extends StatelessWidget {
  const MessagesStreamBuilder({super.key});

  Future<String> _getUsername(String email) async {
    final userSnapshot = await _firestore.collection('current_users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    
    if (userSnapshot.docs.isNotEmpty) {
      return userSnapshot.docs.first['username'];
    }
    return 'Unknown User';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').orderBy('time').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }

        List<Future<MessageLine>> messageFutures = [];
        final messages = snapshot.data!.docs.reversed;

        for (var message in messages) {
          final messageText = message['text'];
          final messageSenderEmail = message['sender'];
          final currentUser = signedInUser?.email;

          // Create a future to fetch the username
          final usernameFuture = _getUsername(messageSenderEmail);

          messageFutures.add(
            usernameFuture.then((senderUsername) => MessageLine(
              sender: senderUsername,
              text: messageText,
              isMe: currentUser == messageSenderEmail,
            )),
          );
        }

        // Wait for all futures to complete
        return FutureBuilder<List<MessageLine>>(
          future: Future.wait(messageFutures),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.lightBlueAccent,
                ),
              );
            }

            final messageWidgets = snapshot.data!;
            return Expanded(
              child: ListView(
                reverse: true,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                children: messageWidgets,
              ),
            );
          },
        );
      },
    );
  }
}

class MessageLine extends StatelessWidget {
  const MessageLine({
    this.text,
    this.sender,
    required this.isMe,
    super.key,
  });

  final String? text;
  final String? sender;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            '$sender',
            style: TextStyle(
              fontSize: 12,
              color: Colors.yellow[900],
            ),
          ),
          Material(
            elevation: 5,
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  )
                : BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
            color: isMe ? Colors.blue[800] : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                '$text',
                style: TextStyle(
                  fontSize: 15,
                  color: isMe ? Colors.white : Colors.black45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

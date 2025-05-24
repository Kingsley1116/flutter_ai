import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart'; // 用於剪貼簿操作
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart'; // 用於分享訊息

class ChatPage extends StatefulWidget {
  final String chatRoom;
  final String model;

  const ChatPage({super.key, required this.chatRoom, required this.model});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static final Map<String, List<Map<String, String>>> _chatHistory = {};
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  bool _isAscending = true; // 訊息排序狀態
  final List<int> _importantMessages = []; // 儲存標記為重要的訊息索引

  List<Map<String, String>> get _messages =>
      _chatHistory[widget.chatRoom] ?? [];

  void _addMessage(String role, String content) {
    setState(() {
      if (!_chatHistory.containsKey(widget.chatRoom)) {
        _chatHistory[widget.chatRoom] = [];
      }
      _chatHistory[widget.chatRoom]!.add({'role': role, 'content': content});
    });
  }

  Future<void> _sendMessage(String message) async {
    _addMessage('user', message);
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization':
              'Bearer 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',
          'Content-Type': 'application/json',
        },
        body: json.encode({'model': widget.model, 'messages': _messages}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final assistantMessage = data['choices']?[0]?['message']?['content'];
        if (assistantMessage != null) {
          _addMessage('assistant', assistantMessage);
        } else {
          _addMessage('assistant', 'Error: Invalid response format.');
        }
      } else {
        _addMessage('assistant', 'Error: ${response.body}');
      }
    } catch (e) {
      _addMessage('assistant', 'Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _regenerateResponse(int index) async {
    final userMessage = _messages[index]['content'];
    if (userMessage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization':
              'Bearer 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',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': widget.model,
          'messages': [
            {'role': 'user', 'content': userMessage},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final assistantMessage = data['choices']?[0]?['message']?['content'];
        if (assistantMessage != null) {
          setState(() {
            _messages[index + 1]['content'] = assistantMessage;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Invalid response format.')),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteMessage(int index) {
    setState(() {
      _messages.removeAt(index);
    });
  }

  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied to clipboard')),
    );
  }

  void _editMessage(int index, String newContent) {
    setState(() {
      _messages[index]['content'] = newContent;
    });
  }

  void _toggleMessageOrder() {
    setState(() {
      _isAscending = !_isAscending;
      _messages.sort((a, b) {
        final timeA = DateTime.parse(
          a['timestamp'] ?? DateTime.now().toString(),
        );
        final timeB = DateTime.parse(
          b['timestamp'] ?? DateTime.now().toString(),
        );
        return _isAscending ? timeA.compareTo(timeB) : timeB.compareTo(timeA);
      });
    });
  }

  void _markMessageAsImportant(int index) {
    setState(() {
      if (_importantMessages.contains(index)) {
        _importantMessages.remove(index);
      } else {
        _importantMessages.add(index);
      }
    });
  }

  void _shareMessage(String content) {
    Share.share(content);
  }

  void _clearChatHistory() {
    setState(() {
      _messages.clear();
    });
  }

  void _searchMessages(String query) {
    final results =
        _messages.where((message) {
          return message['content']?.toLowerCase().contains(
                query.toLowerCase(),
              ) ??
              false;
        }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Results'),
          content: SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(results[index]['content'] ?? ''));
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, String> message, int index) {
    final isUser = message['role'] == 'user';
    final isImportant = _importantMessages.contains(index);

    return GestureDetector(
      onSecondaryTap: () {
        _showMessageOptions(message['content'] ?? '', index);
      },
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
          decoration: BoxDecoration(
            color: isUser ? Colors.blue[300] : Colors.green[300],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
              bottomRight: isUser ? Radius.zero : const Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
            border:
                isImportant
                    ? Border.all(color: Colors.red, width: 2)
                    : null, // 標記為重要時顯示紅色邊框
          ),
          child: MarkdownBody(
            data: message['content'] ?? '',
            selectable: true,
            onTapLink: (text, href, title) {
              if (href != null) {
                debugPrint('Tapped link: $href');
              }
            },
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(String content, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                _copyMessage(content);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _shareMessage(content);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: Text(
                _importantMessages.contains(index)
                    ? 'Unmark as Important'
                    : 'Mark as Important',
              ),
              onTap: () {
                Navigator.pop(context);
                _markMessageAsImportant(index);
              },
            ),
            if (_messages[index]['role'] == 'user')
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Regenerate Response'),
                onTap: () {
                  Navigator.pop(context);
                  _regenerateResponse(index);
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditMessageDialog(content, index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(index);
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditMessageDialog(String content, int index) {
    final TextEditingController controller = TextEditingController(
      text: content,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Message'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter new message'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newContent = controller.text.trim();
                if (newContent.isNotEmpty) {
                  _editMessage(index, newContent);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _handleSendMessage() {
    final message = _controller.text;
    if (message.isNotEmpty) {
      _controller.clear();
      _sendMessage(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 獲取當前主題

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatRoom),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _MessageSearchDelegate(_messages, _searchMessages),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _toggleMessageOrder,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearChatHistory,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Model: ${widget.model}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 聊天記錄
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message, index);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          // 輸入框與發送按鈕
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter your message',
                      hintStyle: TextStyle(
                        color: Colors.grey, // 根據主題設置提示文字顏色
                      ),
                      filled: true,
                      fillColor:
                          theme.inputDecorationTheme.fillColor ??
                          Colors.grey[200], // 根據主題設置背景顏色
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(
                      color: Colors.black, // 根據主題設置文字顏色
                    ),
                    onSubmitted: (value) => _handleSendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _handleSendMessage,
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageSearchDelegate extends SearchDelegate {
  final List<Map<String, String>> messages;
  final Function(String) onSearch;

  _MessageSearchDelegate(this.messages, this.onSearch);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results =
        messages.where((message) {
          return message['content']?.toLowerCase().contains(
                query.toLowerCase(),
              ) ??
              false;
        }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(results[index]['content'] ?? ''));
      },
    );
  }
}

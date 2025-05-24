import 'package:flutter/material.dart';
import 'settings_page.dart';
import 'chat_page.dart';
import 'dart:io'; // 用於導出聊天記錄
import 'package:path_provider/path_provider.dart'; // 用於獲取存儲路徑
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // 用於顏色選擇器

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false; // 深色模式狀態
  int _streamSpeed = 50; // 預設串流速度

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _updateStreamSpeed(int newSpeed) {
    setState(() {
      _streamSpeed = newSpeed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          surface: Colors.grey[900], // 柔和的深色背景
          onSurface: Colors.white70, // 柔和的文字顏色
        ),
        scaffoldBackgroundColor: Colors.grey[850], // 柔和的背景顏色
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black87, // 深色 AppBar
          foregroundColor: Colors.white70, // AppBar 文字顏色
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: ChatRoomsPage(
        toggleTheme: _toggleTheme,
        isDarkMode: _isDarkMode,
        streamSpeed: _streamSpeed,
        onStreamSpeedChanged: _updateStreamSpeed,
      ),
    );
  }
}

class ChatRoomsPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final int streamSpeed;
  final ValueChanged<int> onStreamSpeedChanged;

  const ChatRoomsPage({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
    required this.streamSpeed,
    required this.onStreamSpeedChanged,
  });

  @override
  State<ChatRoomsPage> createState() => _ChatRoomsPageState();
}

class _ChatRoomsPageState extends State<ChatRoomsPage> {
  final List<Map<String, String>> _chatRooms = []; // 儲存聊天室名稱與模型
  bool _isSortedByName = true; // 聊天室排序狀態
  final List<int> _pinnedChatRooms = []; // 儲存固定聊天室的索引
  final Map<String, List<Map<String, String>>> _chatHistory =
      {}; // 儲存每個聊天室的聊天記錄
  final List<Map<String, String>> _archivedChatRooms = []; // 儲存歸檔的聊天室
  final Map<String, Color> _chatRoomColors = {}; // 儲存聊天室主題顏色
  final List<int> _selectedChatRooms = []; // 儲存批量選擇的聊天室索引
  final Map<String, String> _chatRoomPasswords = {}; // 儲存聊天室密碼
  final List<Map<String, String>> _recentChatRooms = []; // 最近訪問的聊天室
  final Map<String, List<String>> _chatRoomTags = {}; // 儲存聊天室標籤
  final Map<String, DateTime> _chatRoomReminders = {}; // 儲存聊天室提醒時間

  void _addChatRoom(String chatRoomName, String model) {
    if (chatRoomName.isNotEmpty) {
      setState(() {
        _chatRooms.add({'name': chatRoomName, 'model': model});
      });
    }
  }

  void _removeChatRoom(int index) {
    setState(() {
      _chatRooms.removeAt(index);
    });
  }

  void _renameChatRoom(int index) {
    final TextEditingController controller = TextEditingController(
      text: _chatRooms[index]['name'],
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Chat Room'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter new name'),
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
                setState(() {
                  _chatRooms[index]['name'] = controller.text.trim();
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _toggleChatRoomOrder() {
    setState(() {
      _isSortedByName = !_isSortedByName;
      _chatRooms.sort((a, b) {
        if (_isSortedByName) {
          return a['name']!.compareTo(b['name']!);
        } else {
          final createdAtA = a['createdAt'] ?? '';
          final createdAtB = b['createdAt'] ?? '';
          return createdAtA.compareTo(createdAtB);
        }
      });
    });
  }

  void _pinChatRoom(int index) {
    setState(() {
      if (_pinnedChatRooms.contains(index)) {
        _pinnedChatRooms.remove(index);
      } else {
        _pinnedChatRooms.add(index);
      }
    });
  }

  void _exportChatRoom(int index) async {
    final chatRoom = _chatRooms[index];
    final chatHistory = _chatHistory[chatRoom['name']] ?? [];
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${chatRoom['name']}_chat.txt');
    final content = chatHistory
        .map((message) {
          return '${message['role']}: ${message['content']}';
        })
        .join('\n');
    await file.writeAsString(content);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Chat exported to ${file.path}')));
  }

  void _searchChatRooms(String query) {
    final results =
        _chatRooms.where((chatRoom) {
          return chatRoom['name']!.toLowerCase().contains(query.toLowerCase());
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
                return ListTile(
                  title: Text(results[index]['name']!),
                  subtitle: Text('Model: ${results[index]['model']}'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ChatPage(
                              chatRoom: results[index]['name']!,
                              model: results[index]['model']!,
                            ),
                      ),
                    );
                  },
                );
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

  void _showAddChatRoomDialog() {
    final TextEditingController controller = TextEditingController();
    String selectedModel = 'qwen/qwen3-8b:free'; // 預設模型
    final List<String> models = [
      'qwen/qwen3-8b:free',
      'deepseek/deepseek-chat-v3-0324:free',
      'google/gemini-2.0-flash-exp:free',
    ]; // 可選模型列表

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Chat Room'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter chat room name',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedModel,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedModel = newValue!;
                      });
                    },
                    items:
                        models.map<DropdownMenuItem<String>>((String model) {
                          return DropdownMenuItem<String>(
                            value: model,
                            child: Text(model),
                          );
                        }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) {
                      // 若名稱為空，彈出提示
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chat room name is required.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      _addChatRoom(controller.text, selectedModel);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRemoveChatRoomDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Chat Room'),
          content: const Text(
            'Are you sure you want to remove this chat room?',
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
                _removeChatRoom(index);
                Navigator.pop(context);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _archiveChatRoom(int index) {
    final chatRoom = _chatRooms[index];
    if (_archivedChatRooms.contains(chatRoom)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat room already archived')),
      );
      return;
    }
    setState(() {
      _archivedChatRooms.add(chatRoom);
      _chatRooms.removeAt(index);
    });
  }

  void _restoreChatRoom(int index) {
    setState(() {
      _chatRooms.add(_archivedChatRooms[index]);
      _archivedChatRooms.removeAt(index);
    });
  }

  void _setChatRoomColor(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Chat Room Color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor:
                  _chatRoomColors[_chatRooms[index]['name']] ?? Colors.blue,
              onColorChanged: (color) {
                setState(() {
                  _chatRoomColors[_chatRooms[index]['name']!] = color;
                });
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  void _deleteSelectedChatRooms() {
    setState(() {
      _selectedChatRooms.sort((a, b) => b.compareTo(a)); // 倒序刪除避免索引錯誤
      for (final index in _selectedChatRooms) {
        _chatRooms.removeAt(index);
      }
      _selectedChatRooms.clear(); // 清除選擇的聊天室索引
    });
  }

  void _showChatRoomStats(int index) {
    final chatRoom = _chatRooms[index];
    final chatHistory = _chatHistory[chatRoom['name']] ?? [];
    final lastActivity =
        chatHistory.isNotEmpty ? chatHistory.last['timestamp'] : 'No activity';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Stats for ${chatRoom['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Messages: ${chatHistory.length}'),
              Text('Last Activity: $lastActivity'),
            ],
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

  void _setChatRoomPassword(String chatRoomName) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Password for $chatRoomName'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter password'),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _chatRoomPasswords[chatRoomName] = controller.text.trim();
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _backupChatRoom(String chatRoomName) async {
    final chatHistory = _chatHistory[chatRoomName] ?? [];
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${chatRoomName}_backup.txt');
    final content = chatHistory
        .map((message) => '${message['role']}: ${message['content']}')
        .join('\n');
    await file.writeAsString(content);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Backup saved to ${file.path}')));
  }

  void _addChatRoomTag(String chatRoomName) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Tag for $chatRoomName'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter tag'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _chatRoomTags.putIfAbsent(chatRoomName, () => []);
                  _chatRoomTags[chatRoomName]!.add(controller.text.trim());
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _setChatRoomReminder(String chatRoomName) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((selectedDate) {
      if (selectedDate != null) {
        setState(() {
          _chatRoomReminders[chatRoomName] = selectedDate;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder set for $selectedDate')),
        );
      }
    });
  }

  void _addToRecentChatRooms(Map<String, String> chatRoom) {
    setState(() {
      _recentChatRooms.removeWhere((room) => room['name'] == chatRoom['name']);
      _recentChatRooms.insert(0, chatRoom);
      if (_recentChatRooms.length > 5) {
        _recentChatRooms.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 獲取當前主題
    final Color titleColor = theme.colorScheme.onSurface; // 動態設置標題顏色
    final Color buttonColor = theme.colorScheme.onSurface; // 動態設置按鈕顏色

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat Rooms',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: titleColor, // 使用動態顏色
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _ChatRoomSearchDelegate(_chatRooms, _searchChatRooms),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _toggleChatRoomOrder,
          ),
          if (_selectedChatRooms.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedChatRooms,
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 最近訪問的聊天室
              if (_recentChatRooms.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Chat Rooms',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _recentChatRooms.length,
                          itemBuilder: (context, index) {
                            final chatRoom = _recentChatRooms[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ChatPage(
                                            chatRoom: chatRoom['name']!,
                                            model: chatRoom['model']!,
                                          ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(chatRoom['name']!),
                                      Text(
                                        'Model: ${chatRoom['model']}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              // 歸檔聊天室
              if (_archivedChatRooms.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Archived Chat Rooms',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _archivedChatRooms.length,
                          itemBuilder: (context, index) {
                            final chatRoom = _archivedChatRooms[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              child: InkWell(
                                onTap: () {
                                  _restoreChatRoom(index);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(chatRoom['name']!),
                                      Text(
                                        'Model: ${chatRoom['model']}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              // 聊天室列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _chatRooms.length,
                  itemBuilder: (context, index) {
                    final chatRoom = _chatRooms[index];
                    final isPinned = _pinnedChatRooms.contains(index);
                    final isSelected = _selectedChatRooms.contains(index);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      color: _chatRoomColors[chatRoom['name']] ?? Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        title: Text(
                          chatRoom['name']!,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: titleColor, // 使用動態顏色
                          ),
                        ),
                        subtitle: Text(
                          'Model: ${chatRoom['model']}',
                          style: TextStyle(color: buttonColor), // 使用動態顏色
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isPinned
                                    ? Icons.push_pin
                                    : Icons.push_pin_outlined,
                                color: isPinned ? Colors.orange : buttonColor,
                              ),
                              onPressed: () {
                                _pinChatRoom(index);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _renameChatRoom(index);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.download,
                                color: Colors.green,
                              ),
                              onPressed: () {
                                _exportChatRoom(index);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.archive,
                                color: Colors.orange,
                              ),
                              onPressed: () {
                                _archiveChatRoom(index);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.color_lens,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                _setChatRoomColor(index);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.bar_chart,
                                color: Colors.green,
                              ),
                              onPressed: () {
                                _showChatRoomStats(index);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showRemoveChatRoomDialog(index);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.lock,
                                color: Colors.orange,
                              ),
                              onPressed: () {
                                _setChatRoomPassword(chatRoom['name']!);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.backup,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                _backupChatRoom(chatRoom['name']!);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.label,
                                color: Colors.green,
                              ),
                              onPressed: () {
                                _addChatRoomTag(chatRoom['name']!);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.alarm, color: Colors.red),
                              onPressed: () {
                                _setChatRoomReminder(chatRoom['name']!);
                              },
                            ),
                            Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedChatRooms.add(index);
                                  } else {
                                    _selectedChatRooms.remove(index);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          if (_chatRoomPasswords.containsKey(
                            chatRoom['name']!,
                          )) {
                            final TextEditingController passwordController =
                                TextEditingController();
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Enter Password'),
                                  content: TextField(
                                    controller: passwordController,
                                    decoration: const InputDecoration(
                                      hintText: 'Password',
                                    ),
                                    obscureText: true,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        if (passwordController.text.trim() ==
                                            _chatRoomPasswords[chatRoom['name']!]) {
                                          Navigator.pop(context);
                                          _addToRecentChatRooms(chatRoom);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => ChatPage(
                                                    chatRoom: chatRoom['name']!,
                                                    model: chatRoom['model']!,
                                                  ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Incorrect password',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Enter'),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            _addToRecentChatRooms(chatRoom);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ChatPage(
                                      chatRoom: chatRoom['name']!,
                                      model: chatRoom['model']!,
                                    ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => SettingsPage(
                        toggleTheme: widget.toggleTheme,
                        isDarkMode: widget.isDarkMode,
                        streamSpeed: widget.streamSpeed,
                        onStreamSpeedChanged: widget.onStreamSpeedChanged,
                      ),
                ),
              );
            },
            icon: const Icon(Icons.settings),
            label: const Text('Settings'),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: _showAddChatRoomDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Room'),
          ),
        ],
      ),
    );
  }
}

class _ChatRoomSearchDelegate extends SearchDelegate {
  final List<Map<String, String>> chatRooms;
  final Function(String) onSearch;

  _ChatRoomSearchDelegate(this.chatRooms, this.onSearch);

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
        chatRooms.where((chatRoom) {
          return chatRoom['name']!.toLowerCase().contains(query.toLowerCase());
        }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(results[index]['name']!),
          subtitle: Text('Model: ${results[index]['model']}'),
          onTap: () {
            close(context, null);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ChatPage(
                      chatRoom: results[index]['name']!,
                      model: results[index]['model']!,
                    ),
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter_simple_chat/models/user_model.dart';

class Message {
  final User sender;
  final String time;
  final String text;
  final bool isServiceMessage;

  Message({
    this.sender,
    this.time,
    this.text,
    this.isServiceMessage,
  });

  Message.fromJson(Map<String, dynamic> json)
      : time = json['time'] != null ? json['time'] : "",
        sender = User(id: 1, name: json['name'] != null ? json['name'] : ""),
        isServiceMessage = json['name'] != null ? false : true,
        text = json['text'];

  Map<String, dynamic> toJson() =>
      {
        'time': time,
        'name': sender.name,
        'text': text,
      };
}

// YOU - current user
User currentUser = User(
  id: 0,
  name: 'Current User',
);

List<Message> messages = [];

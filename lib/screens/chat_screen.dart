import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_simple_chat/models/message_model.dart';
import 'package:flutter_simple_chat/models/user_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';


class ChatScreen extends StatefulWidget {
  final User user;

  ChatScreen({this.user});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String newMessageText = "";
  var editingController = TextEditingController();
  final String serverUrl = 'ws://pm.tada.team/ws?name='+ currentUser.name;
  WebSocketChannel channel;

  _ChatScreenState(){
    channel = IOWebSocketChannel.connect(serverUrl);
    listening();
  }

  processMessage(data){
    try {
        print(data);
        Map messageMap = jsonDecode(data);
        var message = Message.fromJson(messageMap);

        try {
          //find existing item
          var existingItem = messages.firstWhere((itemToCheck) =>
          (itemToCheck.isServiceMessage && itemToCheck.text == message.text) ||
              (itemToCheck.sender.name == currentUser.name &&
                  itemToCheck.text == message.text), orElse: () => null);

          if (existingItem != null) {
            existingItem = null;
            return;
          }
        }catch(e){
          return;
        }


        setState(() {
          messages.insert(0, message);
        });
    } catch (e) {
      print('exception $e');
    }
  }

  listening(){
    try {
      channel.stream.listen((data) => processMessage(data),
          onDone: () {
            print('onDone: ws channel closed');
            this.reconnect();
          }, onError: (e) {
            print('onError: ws error $e');
            this.wserror(e);
          }, cancelOnError: true);
    } catch (e) {
      print('exception $e');
    }
  }

  wserror(err) async {
    print(new DateTime.now().toString() + " Connection error: $err");
    await reconnect();
  }

  reconnect() async {
    if (channel != null) {
      // add in a reconnect delay
      await Future.delayed(Duration(seconds: 4));
    }else return;
    setState(() {
      print(new DateTime.now().toString() + " Starting connection attempt...");
      channel = IOWebSocketChannel.connect(serverUrl);
      print(new DateTime.now().toString() + " Connection attempt completed.");
    });
    listening();
  }

  _buildMessage(Message message, bool isMe) {
    final Container msg = Container(
      margin: isMe
          ? EdgeInsets.only(
              top: 8.0,
              bottom: 8.0,
              left: 80.0,
          )
          : message.isServiceMessage ? EdgeInsets.only(
              left: 60.0,
          ) : EdgeInsets.only(
              top: 8.0,
              bottom: 8.0,
      ),
      padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
      width: MediaQuery.of(context).size.width * 0.75,
      decoration: BoxDecoration(
        color: isMe ? Color.fromARGB(255, 179, 230, 255) :
                message.isServiceMessage ? Color.fromARGB(255, 255, 255, 255) :
                Color(0xFFFFEFEE),
        borderRadius: isMe
            ? BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0),
                bottomLeft: Radius.circular(15.0),
                bottomRight: Radius.circular(15.0)
              )
            : BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0),
                bottomLeft: Radius.circular(15.0),
                bottomRight: Radius.circular(15.0),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message.sender.name,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            message.text,
            style: TextStyle(
              color: Color.fromARGB(255, 102, 102, 102),
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    if (isMe) {
      return msg;
    }
    return Row(
      children: <Widget>[
        msg,
      ],
    );
  }

  _buildMessageComposer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      height: 70.0,
      color: Colors.white,
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: editingController,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (value) {
                newMessageText = value;
              },
              decoration: InputDecoration.collapsed(
                hintText: 'Send a message...',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            iconSize: 25.0,
            color: Theme.of(context).primaryColor,
            onPressed: () {
              final Message newMessage = Message(
                sender: currentUser,
                text: newMessageText,
                isServiceMessage: false,
              );

              if (editingController.text.isNotEmpty) {
                messages.insert(0, newMessage);
                print(editingController.text);
                print(jsonEncode({"text": "${editingController.text}"}));
                channel.sink.add(jsonEncode({"text": "${editingController.text}"}));
                //set state
                setState(() {});
              }

              editingController.text = "";
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text(
          widget.user.name,
          style: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0.0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: ClipRRect(
                  child: ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.only(top: 15.0),
                    itemCount: messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Message message = messages[index];
                      final bool isMe = message.sender.id == currentUser.id;
                      return _buildMessage(message, isMe);
                    },
                  ),
                ),
              ),
            ),
            _buildMessageComposer(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    print('dispose');
    editingController.dispose();
    channel.sink.close();
    channel = null;
    super.dispose();
  }
}

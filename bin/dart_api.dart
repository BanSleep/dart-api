import 'dart:convert';
import 'dart:io';

import 'package:dart_api/dart_api.dart' as dart_api;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart' as shelf_static;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart' as shelf_websocket;

void main() async {
  final cascade = Cascade().add(handler).add(_router);
  var server = await shelf_io.serve(
      logRequests().addHandler(cascade.handler), 'localhost', 8080);

  print(database['users'].isNotEmpty
      ? database['users'][database['users'].length - 1]['id']
      : null);

  print('ws://${server.address.host}:${server.port}');
}

var file = File('files/database.json').readAsStringSync();

Map<String, dynamic> database = jsonDecode(file);


final handler = shelf_websocket.webSocketHandler((webSocket) {
  webSocket.stream.listen((message) {
    print(message);
    webSocket.sink.add("$message");
  });
});


final _staticHandler =
    shelf_static.createStaticHandler('files', defaultDocument: 'index.html');

final _router = shelf_router.Router()
  ..get('/api/test-get', testGet)
  ..post('/api/register', register)
  ..post('/api/login', login)
  ..delete('/api/delete-user', deleteUser);

Response testGet(Request request) {
  var file = File('files/database.json').readAsStringSync();
  Map<String, dynamic> database = jsonDecode(file);
  return Response(200, body: jsonEncode(database));
}

int userId = database['users'].isEmpty
    ? 0
    : database['users'][database['users'].length - 1]['id'] + 1;

var headers = {'Content-Type': 'application/json'};

register(Request request) async {
  final data = jsonDecode(await request.readAsString());
  data['name'].toString();
  Response response = validData(data);
  return response;
}

validData(dynamic data) {
  if (data['login'] == null || data['login'].isEmpty) {
    return Response(422,
        body: jsonEncode(
          {
            'message': "Field name is required",
          },
        ),
        headers: headers);
  } else if (data['password'] == null || data['password'].isEmpty) {
    return Response(422,
        body: jsonEncode(
          {
            'message': "Field last_name is required",
          },
        ),
        headers: headers);
  } else {
    for (int i = 0; i < database['users'].length; i++) {
      if (data['login'].toString().toLowerCase() == database['users'][i]['login'].toString().toLowerCase()) {
        return Response(422, body: jsonEncode( {
          'message': 'This login is already to use'
        }));
      }
    }

    Uuid uuid = Uuid();
    data['id'] = userId;
    data['token'] = uuid.v4();
    userId++;
    database['users'].add(data);
    File('files/database.json').writeAsStringSync(jsonEncode(database));
    print(database);
    return Response(200,
        body: jsonEncode(
          database['users'][userId - 1],
        ));
  }
}

deleteUser(Request request) async {
  print(userId);
  database['users'].removeAt(userId - 1);
  File('files/database.json').writeAsStringSync(jsonEncode(database));
  return Response(
    200,
    body: jsonEncode(
      database['users'][userId],
    ),
  );
}

login(Request request) async {
  final data = jsonDecode(await request.readAsString());
  data['login'].toString();
  for (int i = 0; i < database['users'].length; i++) {
    if (data['login'] != null && data['password'].isNotEmpty && data['login'].isNotEmpty && data['password'] != null) {
      if (data['login'] == database['users'][i]['login'] && data['password'] == database['users'][i]['password']) {
        return Response(200, body:
          jsonEncode(database['users'][i]),
        );
      } else {
        return Response.badRequest();
      }
    } else {
      return Response(422);
    }
  }
  return Response(200);
}

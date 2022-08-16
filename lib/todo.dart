import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show immutable;
import 'package:http/http.dart';
import 'package:riverpod/riverpod.dart';

/// A read-only description of a todo-item
@immutable
class Todo {
  const Todo({
    required this.title,
    required this.id,
    this.userId,
    this.completed = false,
  });

  final int id;
  final int? userId;
  final String title;
  final bool completed;

  @override
  String toString() {
    return 'Todo(description: $title, completed: $completed)';
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      userId: json['userId'],
      completed: json['completed'],
    );
  }
}

/// An object that controls a list of [Todo].
class TodoList extends StateNotifier<List<Todo>> {
  TodoList([List<Todo>? initialTodos]) : super(initialTodos ?? []);

  String api = 'https://jsonplaceholder.typicode.com/todos';

  /// MVP API
  Future<void> getTodos() async {
    Response response = await get(Uri.parse(api));
    if (response.statusCode == 200) {
      final List result = jsonDecode(response.body);
      state = [
        ...state,
        for (Todo remoteTodo in result.map(((e) => Todo.fromJson(e))).toList())
          remoteTodo
      ];
    } else {
      throw Exception(response.reasonPhrase);
    }
  }

  void add(String description) {
    state = [
      ...state,
      Todo(
        id: Random().nextInt(9999999),
        title: description,
      ),
    ];
  }

  void toggle(int id) {
    state = [
      for (final todo in state)
        if (todo.id == id)
          Todo(
            id: todo.id,
            completed: !todo.completed,
            title: todo.title,
          )
        else
          todo,
    ];
  }

  void edit({required int id, required String title}) {
    state = [
      for (final todo in state)
        if (todo.id == id)
          Todo(
            id: todo.id,
            completed: todo.completed,
            title: title,
          )
        else
          todo,
    ];
  }

  void remove(Todo target) {
    state = state.where((todo) => todo.id != target.id).toList();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:todos/todo.dart';

/// create todos
final todoListProvider = StateNotifierProvider<TodoList, List<Todo>>((ref) {
  // init predefined/cached todos from local
  return TodoList(const [
    Todo(id: 0, title: 'Knowunity'),
    Todo(id: 1, title: 'Flutter'),
    Todo(id: 2, title: 'Developer'),
  ]);
});

/// define filter
enum TodoListFilter {
  all,
  active,
  completed,
}

/// create todos filter
final todoListFilter = StateProvider((_) => TodoListFilter.all);

/// create incomplete todos counter
final uncompletedTodosCount = Provider<int>((ref) {
  return ref.watch(todoListProvider).where((todo) => !todo.completed).length;
});

/// filter todos
final filteredTodos = Provider<List<Todo>>((ref) {
  // get current filter
  final filter = ref.watch(todoListFilter);
  // get current todos
  final todos = ref.watch(todoListProvider);

  switch (filter) {
    case TodoListFilter.completed:
      return todos.where((todo) => todo.completed).toList();
    case TodoListFilter.active:
      return todos.where((todo) => !todo.completed).toList();
    case TodoListFilter.all:
      return todos;
  }
});

/// init todos app
void main() {
  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: TodosApp(),
    );
  }
}

class TodosApp extends ConsumerStatefulWidget {
  const TodosApp({Key? key}) : super(key: key);

  @override
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends ConsumerState<TodosApp> {
  final TextEditingController newTodoController = TextEditingController();

  /// override init state
  @override
  void initState() {
    super.initState();
    // fetch new todos from remote
    ref.read(todoListProvider.notifier).getTodos();
  }

  @override
  Widget build(BuildContext context) {
    // get current todos
    final todos = ref.watch(filteredTodos).reversed.toList();

    return GestureDetector(
      // close keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                  // Put here all widgets that are not slivers.
                  child: Column(
                children: [
                  const Title(),
                  TextField(
                    key: const Key('addTodo'),
                    controller: newTodoController,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                        labelText: 'What\'s next?',
                        suffixIcon: newTodoController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  ref
                                      .read(todoListProvider.notifier)
                                      .add(newTodoController.text);
                                  newTodoController.clear();
                                  FocusScope.of(context).unfocus();
                                },
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.blueAccent,
                                ),
                              )
                            : null),
                    onChanged: (value) {
                      setState(() {});
                    },
                    onSubmitted: (value) {
                      ref.read(todoListProvider.notifier).add(value);
                      newTodoController.clear();
                    },
                  ),
                  const SizedBox(height: 42),
                  const Toolbar(),
                  if (todos.isNotEmpty) const Divider(height: 0),
                ],
              )),
              // Replace your ListView.builder with this:
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return Dismissible(
                      key: ValueKey(todos[index].id),
                      onDismissed: (_) {
                        ref
                            .read(todoListProvider.notifier)
                            .remove(todos[index]);
                      },
                      child: ProviderScope(
                        overrides: [
                          _currentTodo.overrideWithValue(todos[index]),
                        ],
                        child: const TodoItem(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Toolbar extends HookConsumerWidget {
  const Toolbar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(todoListFilter);

    Color? textColorFor(TodoListFilter value) {
      return filter == value
          ? Colors.lightBlueAccent
          : Theme.of(context).colorScheme.onPrimary;
    }

    return Material(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${ref.watch(uncompletedTodosCount)} items left',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Tooltip(
            key: const Key('allFilter'),
            message: 'All todos',
            child: TextButton(
              onPressed: () =>
                  ref.read(todoListFilter.notifier).state = TodoListFilter.all,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor:
                    MaterialStateProperty.all(textColorFor(TodoListFilter.all)),
              ),
              child: const Text('All'),
            ),
          ),
          Tooltip(
            key: const Key('activeFilter'),
            message: 'Only uncompleted todos',
            child: TextButton(
              onPressed: () => ref.read(todoListFilter.notifier).state =
                  TodoListFilter.active,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: MaterialStateProperty.all(
                  textColorFor(TodoListFilter.active),
                ),
              ),
              child: const Text('Active'),
            ),
          ),
          Tooltip(
            key: const Key('completedFilter'),
            message: 'Only completed todos',
            child: TextButton(
              onPressed: () => ref.read(todoListFilter.notifier).state =
                  TodoListFilter.completed,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: MaterialStateProperty.all(
                  textColorFor(TodoListFilter.completed),
                ),
              ),
              child: const Text('Completed'),
            ),
          ),
        ],
      ),
    );
  }
}

/// hero widget
class Title extends StatelessWidget {
  const Title({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text(
      'MY AGENDA',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.lightBlueAccent,
        fontSize: 36,
        letterSpacing: 4,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// create current todos provider
final _currentTodo = Provider<Todo>((ref) => throw UnimplementedError());

class TodoItem extends HookConsumerWidget {
  const TodoItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = ref.watch(_currentTodo);
    final itemFocusNode = useFocusNode();
    final itemIsFocused = useIsFocused(itemFocusNode);

    final textEditingController = useTextEditingController();
    final textFieldFocusNode = useFocusNode();

    return Material(
      color: Theme.of(context).cardColor,
      elevation: 6,
      child: Focus(
        focusNode: itemFocusNode,
        onFocusChange: (focused) {
          if (focused) {
            textEditingController.text = todo.title;
          } else {
            // Commit changes only when the textfield is unfocused, for performance
            ref
                .read(todoListProvider.notifier)
                .edit(id: todo.id, title: textEditingController.text);
          }
        },
        child: ListTile(
          onTap: () {
            itemFocusNode.requestFocus();
            textFieldFocusNode.requestFocus();
          },
          leading: Checkbox(
            value: todo.completed,
            onChanged: (value) =>
                ref.read(todoListProvider.notifier).toggle(todo.id),
          ),
          title: itemIsFocused
              ? TextField(
                  autofocus: true,
                  focusNode: textFieldFocusNode,
                  controller: textEditingController,
                )
              : Text(todo.title),
        ),
      ),
    );
  }
}

bool useIsFocused(FocusNode node) {
  final isFocused = useState(node.hasFocus);

  useEffect(() {
    void listener() {
      isFocused.value = node.hasFocus;
    }

    node.addListener(listener);
    return () => node.removeListener(listener);
  }, [node]);

  return isFocused.value;
}

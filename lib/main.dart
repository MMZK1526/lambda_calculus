import 'package:flutter/material.dart';
import 'package:lambda_calculus/lambda_calculus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lambda Calculus',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(title: 'Lambda Calculus'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _controller = TextEditingController();
  bool _hasError = false;
  final _results = <Lambda>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Type in your Lambda term'),
            TextFormField(controller: _controller),
            ElevatedButton(
              onPressed: () {
                final lambda = _controller.text.toLambda();

                if (lambda == null) {
                  setState(() => _hasError = true);
                } else {
                  Lambda? cur = lambda;
                  _results.clear();
                  for (int i = 0; i < 100; i++) {
                    if (cur == null) break;
                    _results.add(cur);
                    cur = cur.eval1(
                      evalType: LambdaEvaluationType.fullReduction,
                    );
                  }
                  setState(() => _hasError = false);
                }
              },
              child: const Text('Evaluate!'),
            ),
            ..._results.map((l) => Text(l.toString())),
            if (_hasError)
              const Text(
                'There is an error in your Lambda term',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}

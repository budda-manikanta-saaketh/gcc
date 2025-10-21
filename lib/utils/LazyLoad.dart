import 'package:flutter/material.dart';

class LazyLoadPage extends StatefulWidget {
  final Widget Function() builder;

  const LazyLoadPage({Key? key, required this.builder}) : super(key: key);

  @override
  State<LazyLoadPage> createState() => _LazyLoadPageState();
}

class _LazyLoadPageState extends State<LazyLoadPage>
    with AutomaticKeepAliveClientMixin {
  late Widget? _child;

  @override
  void initState() {
    super.initState();
    _child = null; // initially not built
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required for AutomaticKeepAliveClientMixin
    _child ??= widget.builder();
    return _child!;
  }

  @override
  bool get wantKeepAlive => true;
}

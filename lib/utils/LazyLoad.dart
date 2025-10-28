import 'package:flutter/material.dart';

class LazyLoadPage extends StatefulWidget {
  final Widget Function() builder;

  const LazyLoadPage({super.key, required this.builder});

  @override
  State<LazyLoadPage> createState() => _LazyLoadPageState();
}

class _LazyLoadPageState extends State<LazyLoadPage>
    with AutomaticKeepAliveClientMixin {
  late Widget? _child;

  @override
  void initState() {
    super.initState();
    _child = null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _child ??= widget.builder();
    return _child!;
  }

  @override
  bool get wantKeepAlive => true;
}

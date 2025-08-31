import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FL Nodes')),
      body: GridView(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 16 / 9,
        ),
        children: [
          PageCard(
            title: const Text('Single instance'),
            subtitle: const Text('A single node editor instance'),
            icon: const Icon(Icons.filter_1),
            onPressed: () =>
                Navigator.of(context).pushNamed('/single_instance'),
          ),
          PageCard(
            title: const Text('Multiple instances'),
            subtitle: const Text('Multiple node editor instances'),
            icon: const Icon(Icons.filter_2),
            onPressed: () =>
                Navigator.of(context).pushNamed('/multiple_instances'),
          ),
        ],
      ),
    );
  }
}

class PageCard extends StatelessWidget {
  final Widget title;
  final VoidCallback? onPressed;
  final Widget? subtitle;
  final Widget? icon;
  const PageCard({
    super.key,
    required this.title,
    this.onPressed,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card.outlined(
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsetsGeometry.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: icon ?? const Icon(Icons.plus_one),
                ),
              ),
              DefaultTextStyle.merge(
                child: title,
                style: textTheme.titleMedium,
              ),
              if (subtitle != null) ...[
                const SizedBox(
                  height: 4,
                ),
                DefaultTextStyle.merge(
                  child: subtitle!,
                  style: textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:fl_context_menu/fl_context_menu.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const ContextMenuExampleScreen(),
    );
  }
}

class ContextMenuExampleScreen extends StatefulWidget {
  const ContextMenuExampleScreen({super.key});

  @override
  State<ContextMenuExampleScreen> createState() =>
      _ContextMenuExampleScreenState();
}

class _ContextMenuExampleScreenState extends State<ContextMenuExampleScreen> {
  @override
  Widget build(BuildContext context) {
    final menuData = FlMenuDataModel(
      sections: [
        FlMenuSectionDataModel(
          label: 'File',
          items: [
            FlMenuItemDataModel(
              idName: 'new',
              label: 'New',
              onPressed: (_) => debugPrint('New clicked'),
              icon: Icons.note_add,
            ),
            FlMenuItemDataModel(
              idName: 'open',
              label: 'Open',
              onPressed: (_) => debugPrint('Open clicked'),
              icon: Icons.folder_open,
            ),
            FlMenuItemDataModel(
              idName: 'save',
              label: 'Save',
              onPressed: (_) => debugPrint('Save clicked'),
              icon: Icons.save,
            ),
          ],
        ),
        FlMenuSectionDataModel(
          label: 'Edit',
          items: [
            FlSubmenuDataModel(
              idName: 'transform',
              label: 'Transform',
              items: [
                FlMenuItemDataModel(
                  idName: 'rotate_90',
                  label: 'Rotate 90°',
                  onPressed: (_) => debugPrint('Rotate clicked'),
                ),
                FlMenuItemDataModel(
                  idName: 'flip_horizontal',
                  label: 'Flip Horizontal',
                  onPressed: (_) => debugPrint('Flip clicked'),
                ),
              ],
            ),
            FlMenuItemDataModel(
              idName: 'duplicate',
              label: 'Duplicate',
              onPressed: (_) => debugPrint('Duplicate clicked'),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: GestureDetector(
        onSecondaryTapDown: (details) {
          showFlContextMenu(
            context: context,
            position: details.globalPosition,
            data: menuData,
          );
        },
        child: CustomPaint(painter: GridPainter(), size: Size.infinite),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withAlpha(77)
      ..strokeWidth = 1.0;

    const gridSize = 20.0;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

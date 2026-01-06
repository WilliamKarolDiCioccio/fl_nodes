import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';

class NodeHeaderStyles {
  static FlNodeHeaderStyle value(FlNodeState state) =>
      flDefaultNodeHeaderStyleBuilder(state).copyWith(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange, Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
      );

  static FlNodeHeaderStyle generator(FlNodeState state) =>
      flDefaultNodeHeaderStyleBuilder(state).copyWith(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
      );

  static FlNodeHeaderStyle logic(FlNodeState state) =>
      flDefaultNodeHeaderStyleBuilder(state).copyWith(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red, Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
      );

  static FlNodeHeaderStyle math(FlNodeState state) =>
      flDefaultNodeHeaderStyleBuilder(state).copyWith(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
      );

  static FlNodeHeaderStyle flow(FlNodeState state) =>
      flDefaultNodeHeaderStyleBuilder(state).copyWith(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
      );

  static FlNodeHeaderStyle io(FlNodeState state) =>
      flDefaultNodeHeaderStyleBuilder(state).copyWith(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
      );
}

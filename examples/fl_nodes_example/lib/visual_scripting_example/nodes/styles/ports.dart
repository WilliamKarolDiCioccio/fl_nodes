import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';

/// Styles for the ports in the node editor.
class PortStyles {
  static FlPortStyle dataOutput(FlPortState state) => FlPortStyle(
        color: state.isHovered
            ? const Color(0xFFFFD54F) // Warm amber on hover
            : const Color(0xFFFF7043), // Modern coral-orange
        shape: FlPortShape.circle,
        radius: state.isHovered ? 6 : 5,
        linkStyleBuilder: (linkState) => FlLinkStyle(
          color: linkState.isSelected
              ? const Color(0xFFFFB74D) // Rich amber when selected
              : linkState.isHovered
                  ? const Color(0xFFFFD54F) // Bright amber on hover
                  : const Color(0xFFFF7043), // Default coral-orange
          lineWidth: linkState.isSelected
              ? 4.0
              : linkState.isHovered
                  ? 4.5
                  : 3.0,
          drawMode: FlLineDrawMode.solid,
          curveType: FlLinkCurveType.bezier,
        ),
      );

  static FlPortStyle dataInput(FlPortState state) => FlPortStyle(
        color: state.isHovered
            ? const Color(0xFFFFD54F) // Warm amber on hover
            : const Color(0xFFFF8A65), // Softer coral for inputs
        shape: FlPortShape.circle,
        radius: state.isHovered ? 6 : 5,
        linkStyleBuilder: (linkState) => FlLinkStyle(
          color: linkState.isSelected
              ? const Color(0xFFFFB74D) // Rich amber when selected
              : linkState.isHovered
                  ? const Color(0xFFFFD54F) // Bright amber on hover
                  : const Color(0xFFFF8A65), // Softer coral for inputs
          lineWidth: linkState.isSelected
              ? 4.0
              : linkState.isHovered
                  ? 4.5
                  : 3.0,
          drawMode: FlLineDrawMode.solid,
          curveType: FlLinkCurveType.bezier,
        ),
      );

  static FlPortStyle controlOutput(FlPortState state) => FlPortStyle(
        color: state.isHovered
            ? const Color(0xFF4DD0E1) // Bright cyan on hover
            : const Color(0xFF26A69A), // Modern teal
        shape: FlPortShape.triangle,
        radius: state.isHovered ? 6 : 5,
        linkStyleBuilder: (linkState) => FlLinkStyle.gradient(
          gradient: linkState.isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFF4DD0E1), // Bright cyan
                    Color(0xFF42A5F5), // Material blue
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : linkState.isHovered
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF80CBC4), // Light teal
                        Color(0xFF64B5F6), // Light blue
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : const LinearGradient(
                      colors: [
                        Color(0xFF26A69A), // Teal
                        Color(0xFF1976D2), // Deep blue
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
          lineWidth: linkState.isSelected
              ? 4.0
              : linkState.isHovered
                  ? 4.5
                  : 3.0,
          drawMode: FlLineDrawMode.solid,
          curveType: FlLinkCurveType.bezier,
        ),
      );

  static FlPortStyle controlInput(FlPortState state) => FlPortStyle(
        color: state.isHovered
            ? const Color(0xFF64B5F6) // Bright cyan on hover
            : const Color(0xFF1976D2), // Softer teal for inputs
        shape: FlPortShape.triangle,
        radius: state.isHovered ? 6 : 5,
        linkStyleBuilder: (linkState) => FlLinkStyle.gradient(
          gradient: linkState.isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFF4DD0E1), // Bright cyan
                    Color(0xFF42A5F5), // Material blue
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : linkState.isHovered
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF80CBC4), // Light teal
                        Color(0xFF64B5F6), // Light blue
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : const LinearGradient(
                      colors: [
                        Color(0xFF4DB6AC), // Softer teal for inputs
                        Color(0xFF1976D2), // Deep blue
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
          lineWidth: linkState.isSelected
              ? 4.0
              : linkState.isHovered
                  ? 4.5
                  : 3.0,
          drawMode: FlLineDrawMode.solid,
          curveType: FlLinkCurveType.bezier,
        ),
      );
}

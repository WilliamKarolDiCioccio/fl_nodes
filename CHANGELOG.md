## 0.1.0 (Beta)

- Initial beta release with core features.
- Published to gather community feedback.

## 0.1.0+1 (Hotfix)

- Fixed several input system issues (partial resolution of input-related bugs).

## 0.2.0

- **Custom Builders**: Added support for general-purpose node-based UIs.
  _(A guide will be provided once the API stabilizes.)_
- **Enhanced Styling**: Node styles now dynamically adapt to entity states (e.g., selected, collapsed).
- **Snap-to-Grid**: Introduced customizable grid-snapping for easier alignment.
- **Performance**: Optimized rendering performance, especially with large node graphs.

## 0.2.0+1 (Hotfix)

- Fixed node rendering issues after creation and deletion.

## 0.3.0

- **Improved Interaction & Feedback**: Links can now be selected, and both links and ports highlight on hover.
- **Performance**: Further performance boosts when working with large node counts.
- **Bug Fixes**:

  - Restored correct offset handling in the undo/redo system.
  - Fixed project loading failure when opening a non-empty editor.
    ([#59](https://github.com/WilliamKarolDiCioccio/fl_nodes/pull/59), [#57](https://github.com/WilliamKarolDiCioccio/fl_nodes/pull/57))

## 0.3.1

- **Mobile Browser Support**: Fixed input issues on mobile web platforms by replacing `os_detect` with `kIsWeb` and `defaultTargetPlatform`.
  ([#73](https://github.com/WilliamKarolDiCioccio/fl_nodes/pull/73))
- **Expanded Public API**: Exported additional commonly used types, removing the need for direct `src/` imports.
  ([#72](https://github.com/WilliamKarolDiCioccio/fl_nodes/pull/72))

Thanks to [playday3008](https://github.com/playday3008) for these contributions! 🎉

## 0.3.2

- **Port Compatibility Checks**: Port type checks now account for inheritance, improving flexibility.
- **Performance**: Improved node scalability via cached responsive styles and optimized rendering.
- **API Improvements**:

  - Added a callback system for custom error handling and reporting.
  - Simplified gradient link styling options.

- **Fixes**:

  1. Default LOD value now correctly matches zoom level.
  2. Fixed gradient links not drawing when no dirty flag was set.
  3. Restored proper style-based link draw batching with custom comparison logic.

Special thanks to [Blokyk](https://github.com/Blokyk) for many of these improvements! 🙌

## 0.4.0

- **Localization Support**:

  - Built-in system makes it easy to localize node-based UIs.
  - Integrates seamlessly with Flutter’s `l10n` but also supports custom locale management.
  - Ships with translations for common languages via a delegate (extensible by developers).
  - Node labels can now directly adapt to the build context for simpler localization.

- **State Management Overhaul**:

  - Completely redesigned state system for smoother interactions and peak performance across devices.

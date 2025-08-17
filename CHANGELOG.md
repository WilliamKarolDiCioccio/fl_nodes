## 0.1.0 (Beta)

- Initial beta release showcasing core features.
- Released to gather community feedback.

## 0.1.0+1 (Hotfix)

- Fixed input system issues (partially resolved input-related problems).

## 0.2.0

- **Custom Builders**: Introduced support for general-purpose node-based UIs.
  - A guide will be provided in the future as the API stabilizes.
- **Enhanced Styling**: Node styles now dynamically respond to entity states
  (e.g., selected, collapsed).
- **Snap-to-Grid**: Added a customizable grid-snapping feature for better
  alignment.
- **Performance Improvements**: Significantly optimized performance, especially
  when handling large numbers of nodes.

## 0.2.0+1 (Hotfix)

- Fixed node rendering after creation and deletion

## 0.3.0

- **Better Interaction and Feedback**: Links can now be selected and, along with ports, are now highlighted on hover.
- **Performance Improvements**: Significantly optimized performance, especially
  when handling large numbers of nodes.
- **Fixed Bugs**: offset restoration in undo/redo system and project loading failure when the editor is not empty ([#59](https://github.com/WilliamKarolDiCioccio/fl_nodes/pull/59) [#57](https://github.com/WilliamKarolDiCioccio/fl_nodes/pull/57)).

## 0.3.1

- **Fixed Mobile Browser**: Fixed input on mobile browser platforms by replacing `os_detect` with `kIsWeb` and `defaultTargetPlatform` ([#73](https://github.com/WilliamKarolDiCioccio/fl_nodes/pull/73)).
- **Exposed More Types To Public API**: Exported addtional symbols of common usage to avoid direct imports from src/ ([#72](https://github.com/WilliamKarolDiCioccio/fl_nodes/pull/72)).

Thanks to [playday3008](https://github.com/playday3008) for these fixes and improvements!

## 0.4.0

- **Port Compatibility Checks**: Made port compatiility cheks aware of type inheritance when checking each port's data type.
- **Improved Performance**: Enabling higher node counts by caching responsive styles and optimizing rendering code.
- **Improved API**: Implemented a callback system to enable customized error handling and reporting and simplfied styling options for gradient links.
- **Small Fixes**:
  1. Fix default LOD value initialization to match zoom level.
  2. Fixed gradient links not drawing if no dirty flag is set and restored proper style-based links draw batching with custom comparison logic.

Thanks to [Blokyk](https://github.com/Blokyk) for many of these fixes and improvements!

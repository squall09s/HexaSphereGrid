# 🌀 HexaSphereGrid

> A modular SwiftUI UI component inspired by the **Sphere Grid** from Final Fantasy X ⚔️🌟

[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2015%2B-blue)](#)
[![License](https://img.shields.io/github/license/your-name/hexaSphereGrid)](./LICENSE)

---

## 🌟 Overview

`HexaSphereGrid` is a highly customizable SwiftUI component for building interactive hexagonal node maps 🧩. Inspired by Final Fantasy X's Sphere Grid, it’s ideal for RPG skill trees, gamified progress maps, or visually rich dashboards.

🧙 Features:
- Interactive, coordinate-based hexagonal tiling
- Smooth pinch-to-zoom and drag with inertial scroll
- Unlockable, selectable, and highlightable nodes
- Progress indicators (per node)
- Custom image overlays anchored to node corners
- Dynamic popovers for contextual node actions
- Fully customizable visuals (color, image, etc.)

<img src="Assets/sample_img.png" alt="HexaSphereGrid Preview" style="width:100%; border-radius:12px;" />

---

## 📦 Installation

### Swift Package Manager (SPM)

Add this repository to your Xcode project:

```
https://github.com/squall09s/HexaSphereGrid
```

Then import:

```swift
import HexaSphereGrid
```

---

## 🧪 Example Usage

```swift
struct ContentView: View {
    
    @StateObject private var viewModel = HexaSphereGridViewModel(dataSource: MyNodeStyleProvider())
    
    var body: some View {
        
        HexaSphereGridView(viewModel: viewModel, showDebugCoordinates: true) { sphereNode in
            VStack {
                Text(sphereNode.name)
                    .padding()
                
                switch viewModel.sphereNodeState(forID: sphereNode.id) {
                case .unlocked:
                    if viewModel.currentSelectedSphereNode?.id != sphereNode.id {
                        Button("Select") {
                            viewModel.deselectHighlightedNode()
                            viewModel.currentSelectedSphereNode = sphereNode
                        }
                    }
                case .unlockable:
                    Button("Unlock") {
                        viewModel.deselectHighlightedNode()
                        viewModel.updateState(forNodeId: sphereNode.id, unlocked: true)
                    }
                case .locked:
                    Text("Locked")
                }
            }
        }
        
    }
}


```

This updated sample shows:
- how to load JSON node data,
- how to assign progress dynamically,
- how to place custom image overlays anchored to nodes.

---

## 🎨 Customizing Appearance

You can control the image and color of each node using a `SphereNodeDataSource`. Just pass a provider to the `HexaSphereGridModel`.

### 👇 Define a provider

```swift
struct MyNodeStyleProvider: SphereNodeDataSource {
    func image(for node: SphereNode) -> Image? {
        return Image(...)
    }

    func color(for node: SphereNode) -> Color {
        node.isActivated ? .green : .gray
    }
}
```

### 💡 Usage

```swift
@StateObject private var viewModel = HexaSphereGridModel(
    dataSource: MyNodeStyleProvider()
)
```

This makes your nodes visually dynamic, customizable, and theme-ready ✨

---

## 🧱 Components

| Component             | Description                                 |
|-----------------------|---------------------------------------------|
| `SphereNode`          | Represents a single hexagonal node          |
| `HexaSphereGrid`      | The main scrollable/zoomable grid view      |
| `HexaSphereGridModel` | Handles node state and unlock logic         |
| `SphereNodeView`      | View for rendering an individual node       |

---

## 💡 Use Cases

- RPG skill trees 🔓
- Visual progress tracking 🎮
- Gamified user journeys 🧭
- Knowledge paths 📚

---

## 🔮 Roadmap

- [ ] Multi-user interactions 👥
- [ ] Dynamic node loading 🌐
- [ ] Theming & skins 🎨
- [ ] Who knows... a built-in minigame? 🎯

---

## 🧙 Inspiration

- Final Fantasy X — The Sphere Grid system
- A love for geometric UI systems 💠
- The eternal allure of hexagons ✨

---

## 👨‍💻 Author

Made with ❤️ by [Nicolas LAURENT](https://github.com/squall09s)  
If you like it, **star it and share it!**

---

## 📄 License

MIT — Use it well and build epic things 🪄

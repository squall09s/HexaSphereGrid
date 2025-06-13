//
//  HexaSphereGridView.swift
//  HexaSphereGrid
//
//  Created by Nicolas Laurent on 22/04/2025.
//

import Foundation
import SwiftUI


enum ZoomLevel {
    case min, normal, max
}

private let zoomPresets: [ZoomLevel: CGFloat] = [
    .min: 0.2,
    .normal: 0.75,
    .max: 1.8
]

/// Coefficient pour élargir la zone de rebond aux bords (1 = limite stricte, >1 = zone augmentée)
private let bounceFactor: CGFloat = 3.5


public struct HexaSphereGridView<Popover: View>: View {
    
    private let showDebugCoordinates: Bool
    
    @ObservedObject var viewModel: HexaSphereGridViewModel
    private let popoverContent: ((SphereNode) -> Popover)?
   
    
    public init(viewModel: HexaSphereGridViewModel, showDebugCoordinates : Bool = false, popoverContent: ((SphereNode) -> Popover)? = nil) {
        self.viewModel = viewModel
        self.popoverContent = popoverContent
        self.showDebugCoordinates = showDebugCoordinates
    }
    
    @State private var position = CGSize.zero
    @State private var dragOffset = CGSize.zero
    
    @GestureState private var zoomScaleGesture: CGFloat = 1.0
    @State private var zoomScale: CGFloat = 0.75
    @State private var zoomLevel: ZoomLevel = .normal
    
    
    private let hexSize: CGFloat = 90
    /// Espace (positif pour plus d’écart, négatif pour rapprocher) entre les centres des hexagones
    private let hexSpacing: CGFloat = 0
    private let mapRadius = 10 // rayon en hexagones autour du centre
    
    
    public var body: some View {
        GeometryReader { geometry in
            // Precompute common values to simplify body expressions
            let offset = CGSize(
                width: position.width + dragOffset.width + geometry.size.width / 2,
                height: position.height + dragOffset.height + geometry.size.height / 2
            )
            ZStack {
                hexagonViewsBackgroundLayer(geometry: geometry, offset: offset)
                unlockPathsLayer(geometry: geometry, offset: offset)
                hexagonViewsLayer(geometry: geometry, offset: offset)
                
                
                ForEach(viewModel.nodeOverlays.sorted(by: { $0.key < $1.key }), id: \.key) { id, view in
                  overlay(for: id, view: view, offset: offset)
                }
                
                
                if let _highlightedSphereNode = viewModel.highlightedSphereNode,
                   let content = popoverContent?(_highlightedSphereNode) {
                    
                    let size = hexSize * _highlightedSphereNode.weight * 1.8
                    let pos = hexToPixel(_highlightedSphereNode.coordinate(), size: hexSize)
                
                    VStack(spacing: 0) {
                        content
                            .frame(minWidth: 120)
                                                .padding( .all, 8)
                                                .padding( .vertical, 16)
                                                .background(
                                                    CustomPopoverContainer()
                                                        .fill(Color.white)
                                                        .shadow(radius: 4)
                                                )
                    }
                    .transition(.scale.combined(with: .opacity))
                    .position(x: pos.x + offset.width,
                              y: pos.y + offset.height + size / 2 + 20)
                    .onTapGesture {
                        viewModel.highlightedSphereNode = nil
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.highlightedSphereNode = nil
            }
            .scaleEffect(zoomScale * zoomScaleGesture)
            .animation(.easeInOut(duration: 0.2), value: zoomScale * zoomScaleGesture)
            .background(Color(UIColor.black.withAlphaComponent(0.1).cgColor))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        viewModel.highlightedSphereNode = nil
                        let ez = zoomScale * zoomScaleGesture
                        dragOffset = CGSize(
                            width: value.translation.width / ez,
                            height: value.translation.height / ez
                        )
                    }
                    .onEnded { value in
                        position.width += value.translation.width / (zoomScale * zoomScaleGesture)
                        position.height += value.translation.height / (zoomScale * zoomScaleGesture)
                        dragOffset = .zero
                        // Bounce at edges with hexagon padding
                        let ez = zoomScale * zoomScaleGesture
                        let hexWidth = hexSize * sqrt(3)
                        let totalMapWidth = hexWidth * CGFloat(mapRadius * 2) + hexWidth
                        let mapWidth = totalMapWidth * ez * bounceFactor
                        let totalMapHeight = 3 * hexSize * CGFloat(mapRadius) + 2 * hexSize
                        let mapHeight = totalMapHeight * ez * bounceFactor
                        
                        withAnimation(.spring()) {
                            // horizontal clamp or center if too small
                            if mapWidth > geometry.size.width {
                                let maxX = (mapWidth - geometry.size.width) / 2
                                let minX = -maxX
                                position.width = min(max(position.width, minX), maxX)
                            } else {
                                position.width = 0
                            }
                            // vertical clamp or center if too small
                            if mapHeight > geometry.size.height {
                                let maxY = (mapHeight - geometry.size.height) / 2
                                let minY = -maxY
                                position.height = min(max(position.height, minY), maxY)
                            } else {
                                position.height = 0
                            }
                        }
                    }
                    .simultaneously(with:
                        MagnificationGesture()
                            .updating($zoomScaleGesture) { value, state, _ in
                                state = value
                            }
                            .onEnded { value in
                                withAnimation(.spring()) {
                                    // accumulate scale and reset the gesture state
                                    zoomScale *= value
                                    zoomScale = min(max(zoomScale, zoomPresets[.min]!),
                                                    zoomPresets[.max]!)
                                    // snap to nearest preset
                                    let closest = zoomPresets.min { abs($0.value - zoomScale) < abs($1.value - zoomScale) }!
                                    zoomScale = closest.value
                                    zoomLevel = closest.key
                                    viewModel.highlightedSphereNode = nil
                                }
                            }
                    )
            )
        }.clipped()
    }
    
    @ViewBuilder
    private func overlay(for id: String, view: AnyView, offset: CGSize) -> some View {
        if let node = viewModel.sphereNodes.first(where: { $0.id == id }) {
            let size = hexSize * node.weight * 1.8
            let pos = hexToPixel(node.coordinate(), size: hexSize)

            let overlaySize = size * 0.35
            view
                .frame(width: overlaySize, height: overlaySize)
                .position(
                    x: pos.x + offset.width - size * 0.43,
                    y: pos.y + offset.height - size * 0.25
                )
        }
    }
    
    @ViewBuilder
    private func unlockPathsLayer(geometry: GeometryProxy, offset: CGSize) -> some View {
        ForEach(viewModel.sphereNodes.filter { $0.unlocked }, id: \.id) { sphereNode in
            ForEach(viewModel.neighborIDs(for: sphereNode), id: \.self) { childID in
                UnlockPathLineView(parent: sphereNode, childID: childID, allNodes: viewModel.sphereNodes, offset: offset, hexSize: hexSize)
            }
        }
    }
    
    @ViewBuilder
    private func hexagonViewsLayer(geometry: GeometryProxy, offset: CGSize) -> some View {
        
        ForEach(viewModel.sphereNodes, id: \.id) { sphereNode in
            hexCell(for: sphereNode, offset: offset)
        }
        
    }
    
    @ViewBuilder
    private func hexCell(for sphereNode: SphereNode, offset: CGSize) -> some View {
        let size = hexSize * sphereNode.weight * 1.8
        let pos = hexToPixel(sphereNode.coordinate(), size: hexSize)

        ZStack {
            SphereNodeView(state: viewModel.sphereNodeState(forID: sphereNode.id),
                           zoomLevel: zoomLevel,
                           name: sphereNode.name,
                           image: viewModel.image(for: sphereNode),
                           mainColor: viewModel.color(for: sphereNode),
                           progress: sphereNode.progress,
                           isSelected: viewModel.currentSelectedSphereNode?.id == sphereNode.id)
                .frame(width: size, height: size)
                .position(x: pos.x + offset.width,
                          y: pos.y + offset.height)
                .onTapGesture {
                    guard zoomLevel != .min else { return }

                    if viewModel.highlightedSphereNode?.id != sphereNode.id {
                        viewModel.highlightedSphereNode = sphereNode
                    } else {
                        viewModel.highlightedSphereNode = nil
                    }
                }

            if showDebugCoordinates {
                Text("(\(sphereNode.q), \(sphereNode.r))")
                    .font(.caption.bold())
                    .foregroundColor(.red)
                    .position(x: pos.x + offset.width,
                              y: pos.y + offset.height + size / 2 + 10)
            }
        }
    }
    
    
    @ViewBuilder
    private func hexagonViewsBackgroundLayer(geometry: GeometryProxy, offset: CGSize) -> some View {
        ForEach(viewModel.sphereNodes) { sphereNode in
            let size = hexSize * sphereNode.weight * 1.8
            let pos = hexToPixel(sphereNode.coordinate(), size: hexSize)
            HexagonViewBackground()
                .frame(width: size, height: size)
                .position(x: pos.x + offset.width,
                          y: pos.y + offset.height)
                
        }
    }
    
   
    
    // MARK: - Coordinate & Layout
    private func hexToPixel(_ hex: GridCoord, size: CGFloat) -> CGPoint {
        // Calculate center-to-center spacing including custom spacing
        let width = size * sqrt(3) + hexSpacing
        let height = size * 3/2 + hexSpacing
        let x = width * (CGFloat(hex.q) + CGFloat(hex.r) / 2)
        let y = height * CGFloat(hex.r)
        return CGPoint(x: x, y: y)
    }
    
    
}

private struct UnlockPathLineView: View {
    let parent: SphereNode
    let childID: String
    let allNodes: [SphereNode]
    let offset: CGSize
    let hexSize: CGFloat

    var body: some View {
        if let child = allNodes.first(where: { $0.id == childID }), child.unlocked {
            let parentPoint = hexToPixel(parent.coordinate(), size: hexSize)
            let childPoint = hexToPixel(child.coordinate(), size: hexSize)
            Path { path in
                path.move(to: CGPoint(x: parentPoint.x + offset.width,
                                      y: parentPoint.y + offset.height))
                path.addLine(to: CGPoint(x: childPoint.x + offset.width,
                                         y: childPoint.y + offset.height))
            }
            .stroke(Color.white, lineWidth: 15)
        }
    }

    private func hexToPixel(_ hex: GridCoord, size: CGFloat) -> CGPoint {
        let width = size * sqrt(3)
        let height = size * 3/2
        let x = width * (CGFloat(hex.q) + CGFloat(hex.r) / 2)
        let y = height * CGFloat(hex.r)
        return CGPoint(x: x, y: y)
    }
}





public final class HexaSphereGridViewModel: ObservableObject {
    
    @Published public var currentSelectedSphereNode: SphereNode?
    @Published var highlightedSphereNode: SphereNode? = nil
    
    @Published public var sphereNodes: [SphereNode] = []
    @Published var nodeOverlays: [String: AnyView] = [:]
    
  
    public var dataSource: SphereNodeDataSource?
    
    private var imageCache: [String: Image] = [:]
    
    public init(dataSource: SphereNodeDataSource? = nil) {
        self.dataSource = dataSource
    }
    
    public func configure(with nodes : [HexagonDataProtocol]){
        self.sphereNodes = nodes.map({ _nodeData in
            return SphereNode(id: _nodeData.id,
                              coord: GridCoord(q: _nodeData.q, r: _nodeData.r),
                              name: _nodeData.name,
                              weight: 1,
                              progress: _nodeData.progress)
        
        })
    }
    
    // Exemple d'utilisation dans ta vue ou logique
    public func color(for node: SphereNode) -> Color {
        dataSource?.color(for: node) ?? Color.black
    }
    
    public func image(for node: SphereNode) -> Image? {
        
        if self.sphereNodeState(forID: node.id) == .locked {
            
            return Image(systemName: "seal.fill")
            
        }else{
            
            if let cached = imageCache[node.id] {
                return cached
            } else if let generated = dataSource?.image(for: node) {
                imageCache[node.id] = generated
                return generated
            } else {
                return nil
            }
        }
    }
    
    public func sphereNodeState(forID id : String) -> HexagonState {
        
        guard let idx = sphereNodes.firstIndex(where: { $0.id == id }) else { return .locked }
        
        if sphereNodes[idx].unlocked {
            
            return .unlocked
            
        } else {
            
            /// Identifiants des cases déverrouillables (voisines des cases déjà unlockées)
            var unlockableSphereNodeIDs: Set<String> {
                var set = Set<String>()
                for sphereNode in sphereNodes where sphereNode.unlocked {
                    set.formUnion(neighborIDs(for: sphereNode))
                }
                // Ne pas proposer celles déjà déverrouillées
                set.subtract(sphereNodes.filter { $0.unlocked }.map { $0.id })
                return set
            }
            
            if sphereNodes[idx].unlocked {
                return .unlocked
            } else {
                return unlockableSphereNodeIDs.contains(id) ? .unlockable : .locked
            }
        }
    }
    
    /// Tente de déverrouiller une case si elle est voisine d’une case unlockée
    public func updateState(forNodeId id: String, unlocked : Bool) {
        guard let idx = sphereNodes.firstIndex(where: { $0.id == id }) else { return }
        sphereNodes[idx].unlocked = true
    }
    
    public func neighborIDs(for node: SphereNode) -> [String] {
        let directions = [
            GridCoord(q: 1, r: 0), GridCoord(q: 1, r: -1), GridCoord(q: 0, r: -1),
            GridCoord(q: -1, r: 0), GridCoord(q: -1, r: 1), GridCoord(q: 0, r: 1)
        ]
        
        return directions.compactMap { offset in
            let neighborCoord = GridCoord(q: node.q + offset.q, r: node.r + offset.r)
            return sphereNodes.first(where: { $0.coordinate() == neighborCoord })?.id
        }
    }
    
    public func deselectHighlightedNode() {
        highlightedSphereNode = nil
    }
    
    public func display(overlays: [(id: String, view: AnyView)]) {
        var newDict: [String: AnyView] = [:]
        for overlay in overlays {
            newDict[overlay.id] = overlay.view
        }
        self.nodeOverlays = newDict
    }
    
    
}

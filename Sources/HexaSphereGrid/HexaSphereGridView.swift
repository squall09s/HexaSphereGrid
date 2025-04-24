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
    
    @ObservedObject var viewModel: HexaSphereGridViewModel
    private let popoverContent: ((SphereNode) -> Popover)?
    
    public init(viewModel: HexaSphereGridViewModel, popoverContent: ((SphereNode) -> Popover)? = nil) {
        self.viewModel = viewModel
        self.popoverContent = popoverContent
    }
    
    @State private var position = CGSize.zero
    @State private var dragOffset = CGSize.zero
    
    @GestureState private var zoomScaleGesture: CGFloat = 1.0
    @State private var zoomScale: CGFloat = 0.75
    @State private var zoomLevel: ZoomLevel = .normal
    
    @State private var highlightedSphereNodeID: UUID? = nil
   
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
                
                if let selectedID = highlightedSphereNodeID,
                   let sphereNode = viewModel.sphereNodes.first(where: { $0.id == selectedID }),
                   let content = popoverContent?(sphereNode) {
                    
                    let size = hexSize * sphereNode.weight * 1.8
                    let pos = hexToPixel(sphereNode.coord, size: hexSize)
                
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
                        highlightedSphereNodeID = nil
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                highlightedSphereNodeID = nil
                viewModel.currentSelectedSphereNode = nil
            }
            .scaleEffect(zoomScale * zoomScaleGesture)
            .animation(.easeInOut(duration: 0.2), value: zoomScale * zoomScaleGesture)
            .background(Color(UIColor.black.withAlphaComponent(0.1).cgColor))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        highlightedSphereNodeID = nil
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
                                    highlightedSphereNodeID = nil
                                }
                            }
                    )
            )
        }.clipped()
    }
    
    @ViewBuilder
    private func unlockPathsLayer(geometry: GeometryProxy, offset: CGSize) -> some View {
        ForEach(viewModel.sphereNodes.filter { $0.isActivated }, id: \.id) { sphereNode in
            ForEach(sphereNode.linkedNodeIDs, id: \.self) { childID in
                if let child = viewModel.sphereNodes.first(where: { $0.id == childID }), child.isActivated {
                    let parentPoint = hexToPixel(sphereNode.coord, size: hexSize)
                    let childPoint = hexToPixel(child.coord, size: hexSize)
                    Path { path in
                        path.move(to: CGPoint(x: parentPoint.x + offset.width,
                                              y: parentPoint.y + offset.height))
                        path.addLine(to: CGPoint(x: childPoint.x + offset.width,
                                                 y: childPoint.y + offset.height))
                    }
                    .stroke(Color.white, lineWidth: 15)
                }
            }
        }
    }
    
    @ViewBuilder
    private func hexagonViewsLayer(geometry: GeometryProxy, offset: CGSize) -> some View {
        ForEach(viewModel.sphereNodes) { sphereNode in
            
            Group {
                
                let size = hexSize * sphereNode.weight * 1.8
                let pos = hexToPixel(sphereNode.coord, size: hexSize)
                
                SphereNodeView(state: viewModel.sphereNodeState(forID: sphereNode.id),
                               zoomLevel: zoomLevel,
                               name: sphereNode.name,
                               image: viewModel.image(for: sphereNode),
                               mainColor: viewModel.color(for: sphereNode)).frame(width: size, height: size)
                    .position(x: pos.x + offset.width,
                              y: pos.y + offset.height)
                    .onTapGesture {
                        guard zoomLevel != .min else { return }

                        if highlightedSphereNodeID != sphereNode.id {
                            highlightedSphereNodeID = sphereNode.id
                        } else {
                            highlightedSphereNodeID = nil
                        }
                    }
                
            }
        }
        
        if let sphereNode = viewModel.currentSelectedSphereNode {
            
            let size = hexSize * sphereNode.weight * 1.8
            let pos = hexToPixel(sphereNode.coord, size: hexSize)

            // Profile badge with smooth spring move and appearance
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(radius: 4)
                .transition(.scale.combined(with: .opacity))
                .animation(.interpolatingSpring(stiffness: 100, damping: 12), value: sphereNode.id)
                .position(x: pos.x + offset.width - size * 0.4,
                          y: pos.y + offset.height - size * 0.2)
        }
    }
    
    
    @ViewBuilder
    private func hexagonViewsBackgroundLayer(geometry: GeometryProxy, offset: CGSize) -> some View {
        ForEach(viewModel.sphereNodes) { sphereNode in
            let size = hexSize * sphereNode.weight * 1.8
            let pos = hexToPixel(sphereNode.coord, size: hexSize)
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

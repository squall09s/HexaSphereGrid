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
    
    let showDebugCoordinates: Bool
    let showMiniMap: Bool
    
    @ObservedObject var viewModel: HexaSphereGridViewModel
    private let popoverContent: ((SphereNode) -> Popover)?
   
    @State private var showUnlockPaths: Bool = true
  
    public init(viewModel: HexaSphereGridViewModel, showDebugCoordinates : Bool = false, showMiniMap: Bool = true, popoverContent: ((SphereNode) -> Popover)? = nil) {
        self.viewModel = viewModel
        self.popoverContent = popoverContent
        self.showDebugCoordinates = showDebugCoordinates
        self.showMiniMap = showMiniMap
    }
    
    @State var position = CGSize.zero
    @State var dragOffset = CGSize.zero
    
    @GestureState var zoomScaleGesture: CGFloat = 1.0
    @State var zoomScale: CGFloat = 0.75
    @State var zoomLevel: ZoomLevel = .normal
    
    
    let hexSize: CGFloat = 90
    /// Espace (positif pour plus d’écart, négatif pour rapprocher) entre les centres des hexagones
    private let hexSpacing: CGFloat = 0
    let mapRadius = 10 // rayon en hexagones autour du centre
    
    
    private func popoverScale(for zoom: ZoomLevel) -> CGFloat {
        switch zoom {
        case .min: return 1.2
        case .normal: return 1.2
        case .max: return 0.6
        }
    }
    
    public var body: some View {
        GeometryReader { geometry in
            // Precompute common values to simplify body expressions
            let offset = CGSize(
                width: position.width + dragOffset.width + geometry.size.width / 2,
                height: position.height + dragOffset.height + geometry.size.height / 2
            )
            ZStack {
                
                hexagonViewsBackgroundLayer(geometry: geometry, offset: offset)
                if showUnlockPaths {
                    unlockPathsLayer(geometry: geometry, offset: offset)
                }
                hexagonViewsLayer(geometry: geometry, offset: offset)
                
                
                ForEach(viewModel.nodeOverlays.sorted(by: { $0.key.uuidString < $1.key.uuidString }), id: \.key) { id, view in
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
                    .scaleEffect(popoverScale(for: zoomLevel))
                    .transition(.scale.combined(with: .opacity))
                    .position(x: pos.x + offset.width,
                              y: pos.y + offset.height + size / 2 + 20)
                    .onTapGesture {
                        viewModel.highlightedSphereNode = nil
                    }
                }
            }
            .contentShape(Rectangle())
            .onChange(of: self.zoomLevel) { _ in
                viewModel.highlightedSphereNode = nil
            }
            .onChange(of: viewModel.highlightedSphereNode) { newValue in
                guard let node = newValue else { return }
                showUnlockPaths = false
                let pos = hexToPixel(node.coordinate(), size: hexSize)
                withAnimation(.spring()) {
                    self.position = CGSize(
                        width: -pos.x,
                        height: -pos.y
                    )
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showUnlockPaths = true
                    }
                }
            }
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
                        
                        let _hexWidth = hexSize * sqrt(3)
                        let _hexHeight = hexSize * 3 / 2
                        let q = Int(round(position.width / _hexWidth - (position.height / _hexHeight) / 2))
                        let r = Int(round(position.height / _hexHeight))
                        viewModel.currentCenter = GridCoord(q: q, r: r)
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
            .overlay(
                Group {
                    if showMiniMap {
                        miniMapView()
                            .padding(.trailing)
                            .padding(.top, (UIApplication.shared.connectedScenes
                                                .compactMap { ($0 as? UIWindowScene)?.keyWindow?.safeAreaInsets.top }
                                                .first ?? 20 ) + 10
                                            )
                    }
                },
                alignment: .topTrailing
            )
            
        }.clipped()
    }
    
    @ViewBuilder
    private func overlay(for id: UUID, view: AnyView, offset: CGSize) -> some View {
        if let node = viewModel.sphereNodes.first(where: { $0.id == id }) {
            let size = hexSize * node.weight * 1.8
            let pos = hexToPixel(node.coordinate(), size: hexSize)

            let overlaySize = size * 0.35
            view
                .frame(width: overlaySize, height: overlaySize)
                .position(
                    x: pos.x + offset.width - size * 0.38,
                    y: pos.y + offset.height - size * 0.22
                )
        }
    }
  
    
}

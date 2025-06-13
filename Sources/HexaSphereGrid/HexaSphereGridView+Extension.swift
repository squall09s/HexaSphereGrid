//
//  File.swift
//  HexaSphereGrid
//
//  Created by Nicolas Laurent on 13/06/2025.
//

import SwiftUI

public extension HexaSphereGridView {
    
    
    @ViewBuilder
    func hexagonViewsBackgroundLayer(geometry: GeometryProxy, offset: CGSize) -> some View {
        ForEach(viewModel.sphereNodes) { sphereNode in
            let size = hexSize * sphereNode.weight * 1.8
            let pos = hexToPixel(sphereNode.coordinate(), size: hexSize)
            HexagonViewBackground()
                .frame(width: size, height: size)
                .position(x: pos.x + offset.width,
                          y: pos.y + offset.height)
                
        }
    }
    
    
    @ViewBuilder
    func unlockPathsLayer(geometry: GeometryProxy, offset: CGSize) -> some View {
        if zoomLevel != .min {
            ForEach(viewModel.sphereNodes.filter { $0.unlocked }, id: \.id) { sphereNode in
                ForEach(viewModel.neighborIDs(for: sphereNode), id: \.self) { childID in
                   
                    UnlockPathLineView(parent: sphereNode, childID: childID, allNodes: viewModel.sphereNodes, offset: offset, hexSize: hexSize)
                }
            }
        }
    }
    
    @ViewBuilder
    func hexagonViewsLayer(geometry: GeometryProxy, offset: CGSize) -> some View {
        
        ForEach(viewModel.sphereNodes, id: \.id) { sphereNode in
            hexCell(for: sphereNode, offset: offset)
        }
        
    }
    
    @ViewBuilder
    func hexCell(for sphereNode: SphereNode, offset: CGSize) -> some View {
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
    
    
    
}

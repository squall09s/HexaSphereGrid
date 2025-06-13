//
//  File.swift
//  HexaSphereGrid
//
//  Created by Nicolas Laurent on 14/06/2025.
//

import SwiftUI

extension HexaSphereGridView {
    
    
    
    @ViewBuilder
    func miniMapView() -> some View {
        if zoomLevel != .min {
            // Place inside safeAreaInset, top trailing with padding
            // The actual view
            // Usage: .safeAreaInset(edge: .top, alignment: .trailing) { miniMapView() }
            GeometryReader { geo in
                let allNodes = viewModel.sphereNodes
                let minQ = allNodes.map(\.q).min() ?? 0
                let maxQ = allNodes.map(\.q).max() ?? 1
                let minR = allNodes.map(\.r).min() ?? 0
                let maxR = allNodes.map(\.r).max() ?? 1
                let gridWidth = CGFloat(maxQ - minQ + 1)
                let gridHeight = CGFloat(maxR - minR + 1)

                let allHexWidth = hexSize * sqrt(3)
                let allHexHeight = hexSize * 3/2

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            let nodeSize = 4.0
                            let hexPositions = viewModel.sphereNodes.map { node in
                                (node, hexToPixel(node.coordinate(), size: nodeSize * 1.8))
                            }

                            let minX = hexPositions.map { $0.1.x }.min() ?? 0
                            let maxX = hexPositions.map { $0.1.x }.max() ?? 1
                            let minY = hexPositions.map { $0.1.y }.min() ?? 0
                            let maxY = hexPositions.map { $0.1.y }.max() ?? 1

                            let padding: CGFloat = 20.0

                            let rangeX = maxX - minX
                            let rangeY = maxY - minY

                            let paddedMinX = minX - padding
                            let paddedMaxX = maxX + padding
                            let paddedMinY = minY - padding
                            let paddedMaxY = maxY + padding

                            let totalWidth = paddedMaxX - paddedMinX
                            let totalHeight = paddedMaxY - paddedMinY

                            ForEach(hexPositions, id: \.0.id) { (node, pos) in
                                Circle()
                                    .fill(node.unlocked ? Color.black.opacity(0.7) : Color.black.opacity(0.3))
                                    .frame(width: nodeSize, height: nodeSize)
                                    .position(
                                        x: ((pos.x - paddedMinX) / totalWidth) * 90,
                                        y: ((pos.y - paddedMinY) / totalHeight) * 90
                                    )
                            }
                            
                            // Add viewport indicator
                            let center = hexToPixel(viewModel.currentCenter, size: nodeSize * 1.8)
                            let indicatorX = (1.0 - ((center.x - paddedMinX) / totalWidth)) * 90
                            let indicatorY = (1.0 - ((center.y - paddedMinY) / totalHeight)) * 90

                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color(UIColor(_colorLiteralRed: 204.0/255.0, green: 62.0/255.0, blue: 62.0/255.0, alpha: 1)), lineWidth: 2.5)
                                .frame(width: 18, height: 18)
                                .position(x: indicatorX, y: indicatorY)
                            
                        }
                        .frame(width: 90, height: 90)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.top, 24)
                        .padding(.trailing, 16)
                    }
                }
            }
            .frame(height: 110)
        }
    }
    
}

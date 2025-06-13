//
//  SwiftUIView.swift
//  HexaSphereGrid
//
//  Created by Nicolas Laurent on 13/06/2025.
//

import SwiftUI

public struct UnlockPathLineView: View {
    
    let parent: SphereNode
    let childID: UUID
    let allNodes: [SphereNode]
    let offset: CGSize
    let hexSize: CGFloat

    public var body: some View {
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

    
}

func hexToPixel(_ hex: GridCoord, size: CGFloat) -> CGPoint {
    let width = size * sqrt(3)
    let height = size * 3/2
    let x = width * (CGFloat(hex.q) + CGFloat(hex.r) / 2)
    let y = height * CGFloat(hex.r)
    return CGPoint(x: x, y: y)
}



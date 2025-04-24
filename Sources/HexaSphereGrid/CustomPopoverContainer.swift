//
//  CustomPopoverContainer.swift
//  HexaSphereGrid
//
//  Created by Nicolas Laurent on 24/04/2025.
//

import SwiftUI

struct CustomPopoverContainer: Shape {
    let cornerRadius: CGFloat = 10
    let triangleHeight: CGFloat = 10
    let triangleWidth: CGFloat = 20

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let rectTop = triangleHeight
        let body = CGRect(
            x: 0,
            y: rectTop,
            width: rect.width,
            height: rect.height - triangleHeight
        )

        // Triangle en haut centré
        let triangleCenter = rect.midX

        path.move(to: CGPoint(x: triangleCenter - triangleWidth / 2, y: rectTop))
        path.addLine(to: CGPoint(x: triangleCenter, y: 0))
        path.addLine(to: CGPoint(x: triangleCenter + triangleWidth / 2, y: rectTop))

        // Corps avec coins arrondis
        path.addRoundedRect(in: body, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        
        return path
    }
}


#Preview {
    CustomPopoverContainer()
}

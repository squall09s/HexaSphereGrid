//
//  SphereNodeView.swift
//  HexaSphereGrid
//
//  Created by Nicolas Laurent on 22/04/2025.
//

import SwiftUI

public enum HexagonState {
    case unlocked
    case locked
    case unlockable
}

struct HexagonViewBackground: View {

    var body: some View {
        ZStack {
            RoundedHexagon()
                .fill(.white)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
}


struct SphereNodeView: View {
    
    let state : HexagonState
    let zoomLevel: ZoomLevel
    let name: String
    let image : Image?
    let mainColor: Color
    let progress: Double?
    let isSelected: Bool

    public init(state: HexagonState, zoomLevel: ZoomLevel, name: String, image: Image?, mainColor: Color = .black, progress: Double? = nil, isSelected : Bool) {
        self.state = state
        self.zoomLevel = zoomLevel
        self.name = name
        self.image = image
        self.mainColor = mainColor
        self.progress = progress
        self.isSelected = isSelected
    }
    
    private var color: Color {
        switch state {
        case .unlocked: return .white
        case .locked: return .black.opacity(0.2)
        case .unlockable: return .black.opacity(0.2)
        }
    }
    
    var body: some View {
        ZStack {
            RoundedHexagon()
                .fill(color)
               
            if zoomLevel == .normal || zoomLevel == .max, let progress = progress, state == .unlocked {
                GeometryReader { geo in
                    ZStack {
                        Capsule()
                            .fill(Color(red: 217/255, green: 217/255, blue: 217/255))
                            .frame(width: 10, height: geo.size.height * 0.4)
                            .offset(x: geo.size.width * 0.8, y: geo.size.height * 0.3)
                        Capsule()
                            .fill( self.isSelected ? contentColor : Color(red: 182/255, green: 182/255, blue: 182/255))
                            .frame(width: 10, height: geo.size.height * 0.4 * progress)
                            .offset(x: geo.size.width * 0.8, y: geo.size.height * 0.3 + ((geo.size.height * 0.4) - (geo.size.height * 0.4 * progress))/2.0 )
                    }
                }
            }

            if zoomLevel == .normal {
                VStack {
                    
                    if let image = image {
                        image
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(contentColor)
                    }
                    
                    
                    
                }.padding(50)
            }
            
            if zoomLevel == .max {
                VStack {
                    
                    if let image = image {
                        image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(1.5)
                            .foregroundColor(contentColor)
                            .padding(10)
                    }
                    
                    Text(name)
                        .font(.caption)
                        .foregroundColor(contentColor)
                    
                    
                }.padding(50)
            }
        }
    }

    private var contentColor: Color {
        switch state {
        case .unlocked:
            return mainColor
        case .locked:
            return .black.opacity(0.03)
        case .unlockable:
            return .black.opacity(0.3)
        }
        
    }
    
}

struct RoundedHexagon: Shape {
    
    init(cornerRadiusRatio: CGFloat = 0.1) {
        self.cornerRadiusRatio = cornerRadiusRatio
    }
    
    /// cornerRadiusRatio ∈ [0.0, 0.5] exprimé en % du rayon du cercle inscrit
    var cornerRadiusRatio: CGFloat = 0.1

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        let cornerRadius = min(max(cornerRadiusRatio, 0.0), 0.5) * radius
        let angles = (0..<6).map { Angle.degrees(Double($0) * 60 - 30) }

        let points = angles.map { angle in
            CGPoint(
                x: center.x + radius * cos(CGFloat(angle.radians)),
                y: center.y + radius * sin(CGFloat(angle.radians))
            )
        }

        var path = Path()
        for i in 0..<6 {
            let prev = points[(i + 5) % 6]
            let current = points[i]
            let next = points[(i + 1) % 6]

            // Vecteurs normalisés
            let v1 = normalize(CGPoint(x: current.x - prev.x, y: current.y - prev.y))
            let v2 = normalize(CGPoint(x: next.x - current.x, y: next.y - current.y))

            let entry = CGPoint(x: current.x - v1.x * cornerRadius, y: current.y - v1.y * cornerRadius)
            let exit  = CGPoint(x: current.x + v2.x * cornerRadius, y: current.y + v2.y * cornerRadius)

            if i == 0 {
                path.move(to: entry)
            } else {
                path.addLine(to: entry)
            }

            path.addQuadCurve(to: exit, control: current)
        }

        path.closeSubpath()
        return path
    }

    private func normalize(_ v: CGPoint) -> CGPoint {
        let len = sqrt(v.x * v.x + v.y * v.y)
        return len == 0 ? .zero : CGPoint(x: v.x / len, y: v.y / len)
    }
}


#Preview {
    SphereNodeView(state: .locked, zoomLevel: .max, name: "hello", image: Image(systemName: "leaf.fill"), isSelected: true)
    SphereNodeView(state: .unlocked, zoomLevel: .normal, name: "hello", image: Image(systemName: "leaf.fill"), isSelected: true)
    SphereNodeView(state: .unlockable, zoomLevel: .min, name: "hello", image: Image(systemName: "leaf.fill"), isSelected: false)
}

//
//  SphereNodeData.swift
//  HexaSphereGridExampleApp
//
//  Created by Nicolas Laurent on 22/04/2025.
//

import Foundation
import HexaSphereGrid
import SwiftUI

enum SphereNodeOrientation: String, Codable {
    case topLeft
    case topRight
    case right
    case bottomRight
    case bottomLeft
    case left
}

final class SphereNodeData: Codable, Hashable {
    
    let name: String
    let color : Int
    let orientation: SphereNodeOrientation?
    let children: [SphereNodeData]?

    init(name: String, orientation: SphereNodeOrientation? = nil, children: [SphereNodeData]? = nil, color : Int) {
        self.name = name
        self.orientation = orientation
        self.children = children
        self.color = color
    }

    static func == (lhs: SphereNodeData, rhs: SphereNodeData) -> Bool {
        return lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

func loadTree() throws -> SphereNodeData {
    let url = Bundle.main.url(forResource: "FakeNodeData", withExtension: "json")!
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(SphereNodeData.self, from: data)
}





func loadSpheres() -> [SphereNode]{
    
    var sphereNodes: [SphereNode] = []
    
    let root: SphereNodeData = try! loadTree()
    
    let directionOffsetMap: [SphereNodeOrientation: GridCoord] = [
        .topLeft:     GridCoord(q: -1, r: 0),
        .topRight:    GridCoord(q:  0, r: -1),
        .right:       GridCoord(q:  1, r: -1),
        .bottomRight: GridCoord(q:  1, r:  0),
        .bottomLeft:  GridCoord(q:  0, r:  1),
        .left:        GridCoord(q: -1, r:  1)
    ]
    
    // 2) fonction recursive qui construit les sphereNodes et lie parent→enfants
    func traverse(_ node: SphereNodeData, at coord: GridCoord) -> UUID {
        let id = UUID()
        // on crée d’abord le sphereNode sans enfants
        sphereNodes.append(SphereNode(
            id:           id,
            coord:        coord,
            name:         node.name,
            color:        Color("color_main_palette_\(node.color)"),
            weight:       1,
            linkedNodeIDs:  [],
            isActivated:   false
        ))
        let idx = sphereNodes.count - 1
        
        for child in node.children ?? [] {
            guard let orientation = child.orientation,
                  let offset = directionOffsetMap[orientation] else { continue }
            let childCoord = GridCoord(q: coord.q + offset.q,
                                       r: coord.r + offset.r)
            let childID = traverse(child, at: childCoord)
            sphereNodes[idx].linkedNodeIDs.append(childID)
        }
        return id
    }
    
    // 3) on lance la récursion depuis le centre
    let rootID = traverse(root, at: GridCoord(q: 0, r: 0))
    // 4) on déverrouille la racine
    if let i = sphereNodes.firstIndex(where: { $0.id == rootID }) {
        sphereNodes[i].isActivated = true
    }
    
    return sphereNodes
    
}

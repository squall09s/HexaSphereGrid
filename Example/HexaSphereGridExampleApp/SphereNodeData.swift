//
//  SphereNodeData.swift
//  HexaSphereGridExampleApp
//
//  Created by Nicolas Laurent on 22/04/2025.
//

import Foundation
import HexaSphereGrid

final class SphereNodeData: Codable, Hashable {
    
    init(name: String, children_1: SphereNodeData? = nil, children_2: SphereNodeData? = nil, children_3: SphereNodeData? = nil, children_4: SphereNodeData? = nil, children_5: SphereNodeData? = nil, children_6: SphereNodeData? = nil) {
        self.name = name
        self.children_1 = children_1
        self.children_2 = children_2
        self.children_3 = children_3
        self.children_4 = children_4
        self.children_5 = children_5
        self.children_6 = children_6
    }
    
    let name: String
    let children_1: SphereNodeData?   // en haut‑gauche
    let children_2: SphereNodeData?   // en haut‑droite
    let children_3: SphereNodeData?   // à droite
    let children_4: SphereNodeData?   // bas‑droite
    let children_5: SphereNodeData?   // bas‑gauche
    let children_6: SphereNodeData?   // à gauche

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
    
    // 1) vecteurs axiaux pour les 6 directions
    let directionOffsets = [
        GridCoord(q: -1, r: 0),  // children_1 (haut‑gauche)
        GridCoord(q:  0, r: -1), // children_2 (haut‑droite)
        GridCoord(q:  1, r: -1), // children_3 (droite)
        GridCoord(q:  1, r:  0), // children_4 (bas‑droite)
        GridCoord(q:  0, r:  1), // children_5 (bas‑gauche)
        GridCoord(q: -1, r:  1)  // children_6 (gauche)
    ]
    
    // 2) fonction recursive qui construit les sphereNodes et lie parent→enfants
    func traverse(_ node: SphereNodeData, at coord: GridCoord) -> UUID {
        let id = UUID()
        // on crée d’abord le sphereNode sans enfants
        sphereNodes.append(SphereNode(
            id:           id,
            coord:        coord,
            name:         node.name,
            color:        .blue,
            weight:       1,
            linkedNodeIDs:  [],
            isActivated:   false
        ))
        let idx = sphereNodes.count - 1
        
        // on parcourt chaque slot enfants_1…_6
        let slots: [SphereNodeData?] = [
            node.children_1, node.children_2, node.children_3,
            node.children_4, node.children_5, node.children_6
        ]
        for (i, child) in slots.enumerated() {
            guard let child = child else { continue }
            let off = directionOffsets[i]
            let childCoord = GridCoord(q: coord.q + off.q,
                                      r: coord.r + off.r)
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

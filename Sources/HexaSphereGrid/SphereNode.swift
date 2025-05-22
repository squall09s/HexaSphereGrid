//
//  SphereNode.swift
//  HexaSphereGrid
//
//  Created by Nicolas Laurent on 24/04/2025.
//

import SwiftUI

public struct GridCoord: Hashable {
    public let q: Int
    public let r: Int
    
    public init(q: Int, r: Int) {
        self.q = q
        self.r = r
    }
}

public struct SphereNode: Identifiable {
    
    public init(id : String, coord: GridCoord, name: String, color: Int, weight: CGFloat, linkedNodeIDs: [String] = [], unlocked: Bool = false) {
        self.id = id
        self.coord = coord
        self.name = name
        self.color = color
        self.weight = weight
        self.linkedNodeIDs = linkedNodeIDs
        self.unlocked = unlocked
    }
    
    public var id : String
    public let coord: GridCoord
    public let name: String
    public var color: Int
    public var weight: CGFloat
    public var linkedNodeIDs: [String] = []
    
    /// État d'activation (false = locked, true = activated)
    public var unlocked: Bool = false
    
    public static func == (lhs: SphereNode, rhs: SphereNode) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        id.hashValue
    }
    
}


public enum SphereNodeOrientation: String, Codable {
    case topLeft
    case topRight
    case right
    case bottomRight
    case bottomLeft
    case left
}

public final class SphereNodeData: Codable, Hashable {
    
    let id : String
    let name: String
    let color : Int
    let unlocked : Bool?
    let orientation: SphereNodeOrientation?
    let children: [SphereNodeData]?
    let isCurrentNode: Bool?

    init(id: String, name: String, orientation: SphereNodeOrientation? = nil, children: [SphereNodeData]? = nil, color: Int, unlocked: Bool? = nil, isCurrentNode: Bool = false) {
        self.id = id
        self.name = name
        self.orientation = orientation
        self.children = children
        self.color = color
        self.unlocked = unlocked
        self.isCurrentNode = isCurrentNode
    }

    public static func == (lhs: SphereNodeData, rhs: SphereNodeData) -> Bool {
        return lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    func findCurrentNode() -> SphereNodeData? {
        if isCurrentNode == true {
            return self
        }
        for child in children ?? [] {
            if let found = child.findCurrentNode() {
                return found
            }
        }
        return nil
    }
        
    
}

public func buildNodes(rootNode : SphereNodeData) -> [SphereNode] {
    
    var sphereNodes: [SphereNode] = []
    
    let directionOffsetMap: [SphereNodeOrientation: GridCoord] = [
        .topLeft:     GridCoord(q: -1, r: 0),
        .topRight:    GridCoord(q:  0, r: -1),
        .right:       GridCoord(q:  1, r: -1),
        .bottomRight: GridCoord(q:  1, r:  0),
        .bottomLeft:  GridCoord(q:  0, r:  1),
        .left:        GridCoord(q: -1, r:  1)
    ]
    
    // 2) fonction recursive qui construit les sphereNodes et lie parent→enfants
    func traverse(_ node: SphereNodeData, at coord: GridCoord) -> String {
        let id = node.id
        // on crée d’abord le sphereNode sans enfants
        sphereNodes.append(SphereNode(
            id:           id,
            coord:        coord,
            name:         node.name,
            color:        node.color,
            weight:       1,
            linkedNodeIDs:  [],
            unlocked:   node.unlocked ?? false
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
    let rootID = traverse(rootNode, at: GridCoord(q: 0, r: 0))
    
    return sphereNodes
    
}

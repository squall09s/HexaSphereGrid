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
    
    public init(id : UUID, coord: GridCoord, name: String, color: Color, weight: CGFloat, linkedNodeIDs: [UUID] = [], isActivated: Bool = false) {
        self.id = id
        self.coord = coord
        self.name = name
        self.color = color
        self.weight = weight
        self.linkedNodeIDs = linkedNodeIDs
        self.isActivated = isActivated
    }
    
    public var id = UUID()
    public let coord: GridCoord
    public let name: String
    public var color: Color
    public var weight: CGFloat
    public var linkedNodeIDs: [UUID] = []
    /// État d'activation (false = locked, true = activated)
    public var isActivated: Bool = false
    
}

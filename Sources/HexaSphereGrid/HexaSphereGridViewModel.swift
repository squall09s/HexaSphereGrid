//
//  HexaSphereGridViewModel.swift
//  HexaSphereGrid
//
//  Created by Nicolas Laurent on 24/04/2025.
//

import SwiftUI
import Foundation


public protocol SphereNodeDataSource {
    func image(for node: SphereNode) -> Image?
    func color(for node: SphereNode) -> Color
}


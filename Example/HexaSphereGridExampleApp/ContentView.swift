//
//  ContentView.swift
//  HexaSphereGridExampleApp
//
//  Created by Nicolas Laurent on 22/04/2025.
//

import SwiftUI
import SwiftData
import HexaSphereGrid

struct ContentView: View {
    
    @StateObject private var viewModel = HexaSphereGridViewModel(dataSource: MyNodeStyleProvider())
    
    var body: some View {
        
        HexaSphereGridView( viewModel: viewModel, showDebugCoordinates: true) { sphereNode in
            
            VStack {
                
                Text(sphereNode.name)
                    .padding()
                
                switch viewModel.sphereNodeState(forID: sphereNode.id) {
                case .unlocked:
                    
                    if viewModel.currentSelectedSphereNode?.id != sphereNode.id {
                        Button("Select") {
                            
                            
                            viewModel.deselectHighlightedNode()
                            viewModel.currentSelectedSphereNode = sphereNode
                            
                        }
                    }
                    
                case .unlockable:
                    Button("Unlock") {
                        
                        viewModel.deselectHighlightedNode()
                        viewModel.updateState(forNodeId: sphereNode.id, unlocked: true)
                    }
                case .locked:
                    
                    Text("Locked")
                }
            }
        }.ignoresSafeArea()
        .onAppear {
            
            let url = Bundle.main.url(forResource: "FakeNodeData", withExtension: "json")!
            let data = try? Data(contentsOf: url)
            
            if let data = data {
                
                do {
                    let _nodes = try JSONDecoder().decode([MySphereNodeData].self, from: data)
                    viewModel.configure(with: _nodes)
                    
                    for _ in 0..<10 {
                        viewModel.updateState(forNodeId: _nodes.randomElement()?.id ?? "", unlocked: true)
                    }
                    
                    viewModel.display(overlays: [
                        (id: "4", view: AnyView(HexUserMarkerView(image: Image("icon_user_1")))),
                        (id: "9", view: AnyView(HexUserMarkerView(image: Image("icon_user_2")))),
                        (id: "12", view: AnyView(HexUserMarkerView(image: Image("icon_user_3"))))
                    ])
                    
                } catch {
                    print(error)
                }
                
                
            } else {
                print("Could not load data file.")
            }
            
        }
    }
}

struct MySphereNodeData: HexagonDataProtocol {
    
    var id: String
    var name: String
    
    var q: Int
    var r: Int
    
    var unlocked: Bool?
    var progress : Double?
}

struct MyNodeStyleProvider: SphereNodeDataSource {
    func image(for node: SphereNode) -> Image? {
       
    let name = [ "ic_game",
                 "ic_moto",
                 "ic_fiesta",
                 "ic_shop",
                 "ic_drink",
                 "ic_holi",
                 "ic_music",
                 "ic_sport"].randomElement( ) ?? ""
       return Image(name)
           
    }

    func color(for node: SphereNode) -> Color {
        
        let hash = node.id.hashValue
         
        switch abs(hash % 4) {
            case 0:
            return .blue
        case 1:
            return .green
        case 2:
            return .yellow
        case 3:
            return .red
        default:
            return .orange
        }
        
    }
}


// HexMapView<EmptyView>()

#Preview {
    ContentView()
}

struct HexUserMarkerView: View {
    let image: Image

    var body: some View {
        image
            .resizable()
            .scaledToFill()
            .frame(width: 42, height: 42)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
            .shadow(radius: 4)
    }
}

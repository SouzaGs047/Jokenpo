//
//  ConnectionView.swift
//  Jokenpo
//
//  Created by Ana Jamas on 17/11/25.
//  Created by Luisiana Ramirez on 17/11/25.
//

import SwiftUI
import MultipeerConnectivity

struct ContentView: View {
    @StateObject private var service = JokenpoMultipeerService()
    
    var body: some View {
        NavigationStack {
            StartView()
        }
        .environmentObject(service)
    }
}

//
//  ContentView.swift
//  Jokenpo
//
//  Created by Gustavo Souza Santana on 23/11/25.
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

//
//  ConnectionView.swift
//  Jokenpo
//
//  Created by Gustavo Souza Santana on 25/11/25.
//

import SwiftUI
import MultipeerConnectivity

struct ConnectionView: View {
    @EnvironmentObject var service: JokenpoMultipeerService
    @State private var goToGame = false
    
    var body: some View {
        VStack(spacing: 24) {
            
            // Estado da conexão
            VStack(spacing: 8) {
                Text(service.isConnected ?
                     "Conectado com: \(service.connectedPeerName ?? "—")" :
                     "Não conectado")
                    .font(.headline)
                
                Text(service.resultText)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            .padding()
            
            // Botões de Host / Join
            HStack(spacing: 16) {
                Button {
                    service.stopBrowsing()
                    service.startHosting()
                } label: {
                    Label("Criar Partida", systemImage: "antenna.radiowaves.left.and.right")
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    service.stopHosting()
                    service.startBrowsing()
                } label: {
                    Label("Entrar em Partida", systemImage: "person.2.fill")
                }
                .buttonStyle(.bordered)
            }
            
            // Lista de partidas encontradas
            if service.isBrowsing {
                if service.discoveredPeers.isEmpty {
                    Text("Procurando partidas próximas…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Partidas disponíveis:")
                            .font(.headline)
                        
                        ForEach(service.discoveredPeers, id: \.self) { peer in
                            Button {
                                service.invite(peer)
                            } label: {
                                HStack {
                                    Image(systemName: "gamecontroller.fill")
                                    Text(peer.displayName)
                                    Spacer()
                                    Image(systemName: "arrow.right.circle")
                                }
                                .padding(8)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            
            Divider()
            
            // Link para o jogo (apenas se estiver conectado)
            if service.isConnected {
                NavigationLink(isActive: $goToGame) {
                    GameView()
                        .environmentObject(service)
                } label: {
                    Text("Ir para o jogo")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("Conecte-se a alguém para começar a jogar.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        // Navega automaticamente quando conectar
        .onChange(of: service.isConnected) { conectado in
            if conectado {
                goToGame = true
            } else {
                goToGame = false
            }
        }
    }
}


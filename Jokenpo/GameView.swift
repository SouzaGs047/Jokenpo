//
//  GameView.swift
//  Jokenpo
//
//  Created by Gustavo Souza Santana on 25/11/25.
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var service: JokenpoMultipeerService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Partida contra: \(service.connectedPeerName ?? "—")")
                .font(.headline)
            
            Text(service.resultText)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
            
            VStack(spacing: 12) {
                Text("Sua jogada:")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    ForEach(JokenpoMove.allCases, id: \.self) { move in
                        Button {
                            service.sendMove(move)
                        } label: {
                            Text(label(for: move))
                                .font(.title3)
                                .padding()
                                .frame(minWidth: 80)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!service.isConnected)
                    }
                }
                
                Text("Você: \(service.myMove?.rawValue ?? "—")")
                    .padding(.bottom, 4)
                
                Button("Novo round") {
                    service.resetRound()
                }
                .buttonStyle(.bordered)
                .disabled(!service.isConnected)
            }
            
            Spacer()
            
            Button(role: .destructive) {
                service.disconnect()
                dismiss()
            } label: {
                Label("Encerrar partida", systemImage: "xmark.circle")
            }
        }
        .padding()
        .navigationTitle("Jogo")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: service.isConnected) { conectado in
            if !conectado {
                dismiss()
            }
        }
    }
    
    private func label(for move: JokenpoMove) -> String {
        switch move {
        case .pedra: return "🪨 Pedra"
        case .papel: return "📄 Papel"
        case .tesoura: return "✂️ Tesoura"
        }
    }
}

//
//  GameView.swift
//  Jokenpo
//
//  Created by Gustavo Souza Santana on 25/11/25.
//

import SwiftUI
import Combine

struct GameView: View {
    @EnvironmentObject var service: JokenpoMultipeerService
    @Environment(\.dismiss) private var dismiss
    
    @State private var timeRemaining: Int = 5
    @State private var isTimerRunning: Bool = false
    @State private var timer = Timer
        .publish(every: 1, on: .main, in: .common)
        .autoconnect()
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Jogando contra:")
                .font(.subheadline)
            
            Text("\(service.connectedPeerName ?? "—")")
                .font(.title3)
                .foregroundStyle(.blueGo)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.blueGo, lineWidth: 5)
                )
            
            // TIMER
            Text("Tempo: \(timeRemaining)s")
                .font(.headline)
                .bold()
                
            
            // 3 BOLINHAS DOS ROUNDS
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { index in
                    let result = service.roundResults[index]
                    let (symbolName, color) = imageNameForRound(result)
                    
                    ZStack {
                        Circle()
                            .stroke(.black, lineWidth: 2)
                            .frame(width: 15, height: 15)
                        
                        if let symbolName = symbolName, let color = color {
                            Image(systemName: symbolName)
                                .foregroundColor(color)
                                .font(.caption)
                        } else if result == .draw {
                            Text("=")
                                .font(.caption)
                        }
                    }
                }
            }
            
            VStack(spacing: 10) {
                // IMAGEM FINAL DA RODADA (win / defeat / draw)
                if service.matchFinished,
                   ["win", "defeat", "draw"].contains(service.resultText) {
                    Text("Esperando o outro jogador...")
                        .font(.headline)
                        .padding(.top)
                    Image(service.resultText) // win / defeat / draw
                } else {
                    // Sua jogada
                    Image("\(service.myMove?.rawValue ?? "—")J")
                }
                
                Spacer()
                
                // Botões de jogada
                if !service.matchFinished {
                    HStack {
                        ForEach(JokenpoMove.allCases, id: \.self) { move in
                            Button {
                                service.sendMove(move)
                            } label: {
                                Image("\(move)")
                                    .font(.title3)
                                    .padding()
                                    .frame(minWidth: 80)
                            }
                            .disabled(service.matchFinished) // não deixa jogar depois da rodada finalizada
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Botões de controle de rounds
                HStack(spacing: 12) {
                    if service.matchFinished {
                        Button("Resetar partida") {
                            service.resetMatch()      // agora sincroniza nos dois
                            startRoundTimer()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!service.isConnected)
                        
                    } else {
                        Button("Novo round") {
                            if !service.matchFinished {
                                service.nextRound()   // agora sincroniza nos dois
                                startRoundTimer()     // timer continua local
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(!service.isConnected || service.matchFinished)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.black, lineWidth: 5)
            )            
            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    service.disconnect()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            startRoundTimer()
        }
        // Timer ticando
        .onReceive(timer) { _ in
            guard isTimerRunning,
                  service.isConnected,
                  !service.matchFinished else { return }
            
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopRoundTimer()
                
                if service.myMove == nil {
                    if let randomMove = JokenpoMove.allCases.randomElement() {
                        service.sendMove(randomMove)
                    }
                }
            }
        }
        .onChange(of: service.isConnected) { oldValue, newValue in
            if newValue {
                service.resetMatch()
                startRoundTimer()
            } else {
                stopRoundTimer()
                dismiss()
            }
        }
        // 🔹 QUANDO O ROUND TROCAR (nextRound ou resetMatch do outro)
        .onChange(of: service.currentRoundIndex) { _, _ in
            if service.isConnected && !service.matchFinished {
                startRoundTimer()
            }
        }
        // 🔹 QUANDO A MELHOR-DE-3 TERMINAR, PARA O TIMER
        .onChange(of: service.matchFinished) { _, finished in
            if finished {
                stopRoundTimer()
            }
        }
    }
    
    private func startRoundTimer() {
        timeRemaining = 5
        isTimerRunning = true
    }
    
    private func stopRoundTimer() {
        isTimerRunning = false
    }
    
    private func imageNameForRound(_ result: RoundResult) -> (String?, Color?) {
        switch result {
        case .win:
            return ("checkmark", .green)
        case .defeat:
            return ("xmark", .red)
        case .draw:
            return ("stroke.line.diagonal", .gray)
        case .none:
            return (nil, .clear)
        }
    }
}

#Preview {
    GameView()
        .environmentObject(JokenpoMultipeerService())
}

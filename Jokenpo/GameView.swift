//
//  ConnectionView.swift
//  Jokenpo
//
//  Created by Ana Jamas on 17/11/25.
//  Created by Luisiana Ramirez on 17/11/25.
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
                    let (_, color) = imageNameForRound(result)
                    let fillColor: Color? = (result == .draw) ? Color.purple : color

                    ZStack {
                        Circle()
                            .stroke(.black, lineWidth: 2)
                            .frame(width: 15, height: 15)

                        if let fillColor = fillColor {
                            Circle()
                                .fill(fillColor)
                                .frame(width: 15, height: 15)
                        }
                    }
                }
            }
            
            VStack(spacing: 10) {
                if service.myMove == nil && !service.matchFinished {
                    Text("Escolha uma das opções:")
                        .font(.subheadline)
                        .padding(.top, 20)
                    Spacer()
                    
                } else if service.matchFinished,
                          ["win", "defeat", "draw"].contains(service.resultText) {
                    Text("Esperando o outro jogador...")
                        .font(.headline)
                        .padding(.top, 20)
                    
                    Image(service.resultText)
            
                } else if service.myMove != nil {
                    Image("\(service.myMove?.rawValue ?? "—")J")
                        .resizable()
                        .frame(maxWidth: 190, maxHeight: 335)
                        .scaledToFit()
                        .padding(.top, 18)
                        .padding(.bottom, 10)
                        
                } else {
                    Spacer()
                }
            
                if !service.matchFinished {
                    VStack {
                        Text("Escolha uma das opções:")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                            .padding(.top, 10)
                            .padding(.bottom, -12)
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
                                .disabled(service.matchFinished || service.myMove != nil)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                            .stroke(Color(red: 0.8, green: 0.8, blue: 0.8), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 670)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.black, lineWidth: 5)
            )
            HStack(spacing: 12) {
                if service.matchFinished {
                    Button("Jogar outra vez") {
                        service.resetMatch()
                        startRoundTimer()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!service.isConnected)
                    
                } else {
                    Button("Novo round") {
                        if !service.matchFinished {
                            service.nextRound()
                            startRoundTimer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!service.isConnected || service.myMove == nil)
                }
            }
            .padding(.top, 5)
        }
        .padding([.top, .horizontal])
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
        .onChange(of: service.currentRoundIndex) { _, _ in
            if service.isConnected && !service.matchFinished {
                startRoundTimer()
            }
        }
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

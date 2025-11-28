//
//  ConnectionView.swift
//  Jokenpo
//
//  Created by Ana Jamas on 17/11/25.
//  Created by Luisiana Ramirez on 17/11/25.
//

import SwiftUI
import MultipeerConnectivity

struct ConnectionView: View {
    @EnvironmentObject var service: JokenpoMultipeerService
    @State private var goToGame = false
    
    @State private var createRoom = false
    @State private var joinRoom = false
    
    var body: some View {
        ZStack {
            Image("tela2")
            
            VStack{
                Image("jokenGo")
                    .padding(.top,50)
                    .padding(.bottom,25)
                VStack(spacing: 15) {
                    if !joinRoom {
                        Button {
                            service.stopBrowsing()
                            service.startHosting()
                            
                            createRoom = true
                            joinRoom = false
                        } label: {
                            Image(createRoom ? "tela2-creatingRoom" : "tela2-create")
                        }
                    }
                    
                    if !createRoom {
                        Button {
                            service.stopHosting()
                            service.startBrowsing()
                            
                            createRoom = false
                            joinRoom = true
                        } label: {
                            Image(joinRoom ? "tela2-findingRoom" : "tela2-find")
                        }
                    }
                }
                
                
                if createRoom {
                    Text("Aguardando jogador entrar na sala....")
                        .font(.headline)
                        .padding()
                }
                
                // Lista de partidas encontradas
                if joinRoom {
                    VStack(alignment: .center) {
                        
                        Text("Encontrando outro jogador....")
                            .font(.headline)
                            .padding()
                        
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            ForEach(service.discoveredPeers, id: \.self) { peer in
                                
                                Button {
                                    service.invite(peer)
                                } label: {
                                    HStack {
                                        Text(peer.displayName)
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "play.circle.fill")
                                            .font(.title)
                                            .foregroundStyle(.white)
                                    }
                                    .padding()
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .foregroundStyle(.greenGo)
                                )
                                .padding()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(.greenGo, lineWidth: 5)
                    )
                    .padding(20)
                    .padding(.bottom)
                }
                    Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: service.isConnected) { oldValue, newValue in
            goToGame = newValue
        }
        .navigationDestination(isPresented: $goToGame) {
            GameView()
                .environmentObject(service)
        }
        .toolbar {
            if createRoom || joinRoom {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        createRoom = false
                        joinRoom = false
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.headline)
                            .bold()
                            .foregroundStyle(.black)
                    }
                }
                
            }
        }
    }
}

#Preview {
    ConnectionView()
        .environmentObject(JokenpoMultipeerService())
}

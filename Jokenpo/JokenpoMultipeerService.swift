//
//  NPCManager.swift
//  Jokenpo
//
//  Created by Gustavo Souza Santana on 23/11/25.
//

import Foundation
import MultipeerConnectivity
import SwiftUI
import Combine

enum JokenpoMove: String, Codable, CaseIterable {
    case pedra
    case papel
    case tesoura
}

struct JokenpoMessage: Codable {
    let move: JokenpoMove
}

class JokenpoMultipeerService: NSObject, ObservableObject {
    
    // MARK: - Multipeer
    private let serviceType = "jokenpo-game" //máx 15 chars, minúsculo
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    // MARK: - Estado publicado para a View
    
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var isBrowsing: Bool = false
    
    @Published var isHost: Bool = false
    @Published var connectedPeerName: String? = nil
    @Published var isConnected: Bool = false
    
    @Published var myMove: JokenpoMove? = nil
    @Published var opponentMove: JokenpoMove? = nil
    @Published var resultText: String = "Aguardando conexão…"
    
    // MARK: - Init
    
    override init() {
        super.init()
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
    }
    
    deinit {
        stopHosting()
        stopBrowsing()
        session.disconnect()
    }
    
    // MARK: - Host / Join
    
    func startHosting() {
        isHost = true
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID,
                                               discoveryInfo: nil,
                                               serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        DispatchQueue.main.async {
            self.resultText = "Aguardando jogador entrar na partida…"
        }
    }
    
    func stopHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
    }
    
    func startBrowsing() {
        isHost = false
        discoveredPeers = []
        isBrowsing = true
        
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        DispatchQueue.main.async {
            self.resultText = "Procurando partidas próximas…"
        }
    }

    func stopBrowsing() {
        isBrowsing = false
        browser?.stopBrowsingForPeers()
        browser = nil
        discoveredPeers = []
    }

    func invite(_ peer: MCPeerID) {
        guard let browser = browser else { return }
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 10)
        resultText = "Convidando \(peer.displayName)…"
    }

    func disconnect() {
        stopHosting()
        stopBrowsing()
        session.disconnect()
        
        DispatchQueue.main.async {
            self.connectedPeerName = nil
            self.isConnected = false
            self.resetRound()
            self.resultText = "Conexão encerrada. Volte a criar/entrar na partida."
        }
    }

    
    // MARK: - Jogo
    
    func sendMove(_ move: JokenpoMove) {
        myMove = move
        updateResult()
        
        guard !session.connectedPeers.isEmpty else { return }
        
        let message = JokenpoMessage(move: move)
        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Erro ao enviar movimento: \(error)")
        }
    }
    
    func resetRound() {
        myMove = nil
        opponentMove = nil
        resultText = isConnected ? "Escolha sua jogada" : "Aguardando conexão…"
    }
    
    private func updateResult() {
        guard let my = myMove else {
            resultText = "Escolha sua jogada"
            return
        }
        
        guard let opp = opponentMove else {
            resultText = "Você escolheu \(my.rawValue). Aguardando oponente…"
            return
        }
        
        let resultado: String
        
        if my == opp {
            resultado = "Empate! Ambos jogaram \(my.rawValue)."
        } else if (my == .pedra && opp == .tesoura) ||
                    (my == .papel && opp == .pedra) ||
                    (my == .tesoura && opp == .papel) {
            resultado = "Você venceu! \(my.rawValue) ganha de \(opp.rawValue)."
        } else {
            resultado = "Você perdeu! \(opp.rawValue) ganha de \(my.rawValue)."
        }
        
        resultText = resultado
    }
}

// MARK: - MCSessionDelegate

extension JokenpoMultipeerService: MCSessionDelegate {
    func session(_ session: MCSession,
                 peer peerID: MCPeerID,
                 didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.connectedPeerName = peerID.displayName
                self.isConnected = true
                self.resultText = "Conectado com \(peerID.displayName). Escolham suas jogadas!"
            case .connecting:
                self.resultText = "Conectando com \(peerID.displayName)…"
            case .notConnected:
                self.connectedPeerName = nil
                self.isConnected = false
                self.resultText = "Conexão perdida. Volte a criar/entrar na partida."
                self.resetRound()
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession,
                 didReceive data: Data,
                 fromPeer peerID: MCPeerID) {
        do {
            let message = try JSONDecoder().decode(JokenpoMessage.self, from: data)
            DispatchQueue.main.async {
                self.opponentMove = message.move
                self.updateResult()
            }
        } catch {
            print("Erro ao decodificar mensagem: \(error)")
        }
    }
    
    // Não usados aqui, mas precisam existir:
    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {}
    
    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?,
                 withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension JokenpoMultipeerService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Host aceita automaticamente
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didNotStartAdvertisingPeer error: Error) {
        print("Erro ao anunciar: \(error)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension JokenpoMultipeerService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            if !self.discoveredPeers.contains(peerID) {
                self.discoveredPeers.append(peerID)
            }
            if self.discoveredPeers.count == 1 {
                self.resultText = "Selecione uma partida para entrar."
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.discoveredPeers.removeAll { $0 == peerID }
        }
    }

    
    func browser(_ browser: MCNearbyServiceBrowser,
                 didNotStartBrowsingForPeers error: Error) {
        print("Erro ao buscar peers: \(error)")
    }
}

//
//  ConnectionView.swift
//  Jokenpo
//
//  Created by Ana Jamas on 17/11/25.
//  Created by Luisiana Ramirez on 17/11/25.
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

enum RoundResult {
    case none
    case win
    case defeat
    case draw
}

enum JokenpoCommand: String, Codable {
    case move
    case resetMatch
    case nextRound
}

struct JokenpoMessage: Codable {
    let command: JokenpoCommand
    let move: JokenpoMove?
}


class JokenpoMultipeerService: NSObject, ObservableObject {
    
    // MARK: - Multipeer
    
    private let serviceType = "jokenpo-game"
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
    @Published var resultText: String = ""
    
    @Published var currentRoundIndex: Int = 0
    @Published var roundResults: [RoundResult] = Array(repeating: .none, count: 3)
    @Published var matchFinished: Bool = false

    
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
    }

    func disconnect() {
        stopHosting()
        stopBrowsing()
        session.disconnect()
        
        DispatchQueue.main.async {
            self.connectedPeerName = nil
            self.isConnected = false
            self.resetMatch(localOnly: true)
        }
    }



    
    // MARK: - Jogo
    private func send(_ message: JokenpoMessage) {
        guard !session.connectedPeers.isEmpty else { return }
        
        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Erro ao enviar mensagem: \(error)")
        }
    }

    func sendMove(_ move: JokenpoMove) {
        myMove = move
        updateResult()
        
        let message = JokenpoMessage(command: .move, move: move)
        send(message)
    }

    
    func resetRound() {
        myMove = nil
        opponentMove = nil
        resultText = "Escolha sua jogada"
    }

    func resetMatch(localOnly: Bool = false) {
        currentRoundIndex = 0
        roundResults = Array(repeating: .none, count: 3)
        matchFinished = false
        resetRound()
        
        if !localOnly {
            let message = JokenpoMessage(command: .resetMatch, move: nil)
            send(message)
        }
    }

    func nextRound(localOnly: Bool = false) {
        guard currentRoundIndex < 2 else { return }
        currentRoundIndex += 1
        resetRound()
        
        if !localOnly {
            let message = JokenpoMessage(command: .nextRound, move: nil)
            send(message)
        }
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
        
        let roundResult: RoundResult
        
        if my == opp {
            roundResult = .draw
        } else if (my == .pedra && opp == .tesoura) ||
                    (my == .papel && opp == .pedra) ||
                    (my == .tesoura && opp == .papel) {
            roundResult = .win
        } else {
            roundResult = .defeat
        }
        
        if currentRoundIndex < roundResults.count {
            roundResults[currentRoundIndex] = roundResult
        }
        
        if currentRoundIndex < roundResults.count - 1 {
            switch roundResult {
            case .win:    resultText = "win"
            case .defeat: resultText = "defeat"
            case .draw:   resultText = "draw"
            case .none:   resultText = ""
            }
            return
        }
        
        matchFinished = true
        
        let wins    = roundResults.filter { $0 == .win }.count
        let defeats = roundResults.filter { $0 == .defeat }.count
        
        if wins > defeats {
            resultText = "win"
        } else if defeats > wins {
            resultText = "defeat"
        } else {
            resultText = "draw"
        }
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
                self.resultText = "Escolham suas jogadas!"
            case .connecting:
                self.resultText = ""
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
                switch message.command {
                case .move:
                    if let move = message.move {
                        self.opponentMove = move
                        self.updateResult()
                    }
                case .resetMatch:
                    self.resetMatch(localOnly: true)
                case .nextRound:
                    self.nextRound(localOnly: true)
                }
            }
        } catch {
            print("Erro ao decodificar mensagem: \(error)")
        }
    }

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

//
//  StartView.swift
//  Jokenpo
//
//  Created by Gustavo Souza Santana on 26/11/25.
//

import SwiftUI

struct StartView: View {
    var body: some View {
        ZStack {
            Image("tela1")
            VStack {
                Spacer()
                Image("jokenGo")
                Spacer()
                NavigationLink {
                    ConnectionView()
                } label: {
                    Image("tela1-start")
                }
                .padding(.bottom)
            }
        }
    }
}

#Preview {
    StartView()
}

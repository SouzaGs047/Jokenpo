//
//  ConnectionView.swift
//  Jokenpo
//
//  Created by Ana Jamas on 17/11/25.
//  Created by Luisiana Ramirez on 17/11/25.
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
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    StartView()
}

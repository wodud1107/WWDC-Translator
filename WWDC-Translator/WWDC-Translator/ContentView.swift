//
//  ContentView.swift
//  WWDC-Translator
//
//  Created by 김재영 on 3/9/26.
//

import SwiftUI
import WebKit

struct ContentView: View {
    @State private var year: String = ""
    @State private var sessionNumber: String = ""
    @State private var url: URL? = URL(string: "https://developer.apple.com/videos/")
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                HStack {
                    TextField("WWDC 연도", text: $year)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    
                    TextField("세션 번호", text: $sessionNumber)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    
                    Button("이동") {
                        goToSession()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(year.isEmpty || sessionNumber.isEmpty)
                }
            }
            .padding()
            #if os(macOS)
            .background(Color(NSColor.windowBackgroundColor))
            #else
            .background(Color(.systemBackground))
            #endif
            .shadow(radius: 2)
            
            if let url {
                WebView(url: url)
                    .ignoresSafeArea(edges: .bottom)
            } else {
                ContentUnavailableView("URL을 로드할 수 없습니다.", systemImage: "network.slash")
            }
        }
    }
    
    private func goToSession() {
        // WWDC 세션 URL 패턴: https://developer.apple.com/videos/play/wwdc{year}/{sessionNumber}/
        let sessionURLString = "https://developer.apple.com/videos/play/wwdc\(year)/\(sessionNumber)/"
        if let newURL = URL(string: sessionURLString) {
            self.url = newURL
        }
    }
}

#Preview {
    ContentView()
}

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
    
    @State private var page = WebPage()
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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
                .zIndex(1)
                
                WebView(page)
                    .ignoresSafeArea(edges: .bottom)
            }
            
            if let currentURL = page.url, currentURL.absoluteString.contains("play") {
                Button {
                    // TODO: callJavaScript 연동 예정
                    print("버튼 클릭됨: 전사문 추출 로직 연결 전")
                } label: {
                    HStack {
                        Image(systemName: "captions.bubble.fill")
                        Text("한국어 자막으로 보기")
                    }
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(radius: 4, x: 0, y: 2)
                }
                .padding(20)
                .buttonStyle(.plain) // 기본 버튼 스타일 제거하여 커스텀 디자인 유지
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            if let initialURL = URL(string: "https://developer.apple.com/videos/") {
                page.load(initialURL)
            }
        }
    }
    
    private func goToSession() {
        // WWDC 세션 URL 패턴: https://developer.apple.com/videos/play/wwdc{year}/{sessionNumber}/
        let sessionURLString = "https://developer.apple.com/videos/play/wwdc\(year)/\(sessionNumber)/"
        if let newURL = URL(string: sessionURLString) {
            page.load(newURL)
        }
    }
}

#Preview {
    ContentView()
}

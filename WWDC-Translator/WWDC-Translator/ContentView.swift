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
    @State private var isExtracting: Bool = false
    
    // 추출된 데이터 저장
    @State private var m3u8URL: String?
    @State private var subtitles: [Subtitle] = []
    
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
                    Task {
                        await extractTranscriptData()
                    }
                } label: {
                    HStack {
                        if isExtracting {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                                .padding(.trailing, 4)
                            Text("추출 중...")
                        } else {
                            Image(systemName: "captions.bubble.fill")
                            Text("한국어 자막으로 보기")
                        }
                    }
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(isExtracting ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(radius: 4, x: 0, y: 2)
                }
                .padding(20)
                .buttonStyle(.plain)
                .disabled(isExtracting)
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
        let sessionURLString = "https://developer.apple.com/videos/play/wwdc\(year)/\(sessionNumber)/"
        if let newURL = URL(string: sessionURLString) {
            page.load(newURL)
            self.m3u8URL = nil
            self.subtitles = []
        }
    }
    
    // 자막 데이터 추출 로직
    @MainActor
    private func extractTranscriptData() async {
        print("🔍 전사문 스크래핑 시작...")
        isExtracting = true
        defer { isExtracting = false }
        
        let dataScript = """
        try {
            // 1. 비디오 URL 추출 (meta 우선, video 차선)
            var metaVideo = document.querySelector('meta[property="og:video"]');
            var m3u8 = metaVideo ? metaVideo.content : "";
            
            // 2. 자막 텍스트 추출
            var sentences = document.querySelectorAll('#transcript-content .sentence, .supplement.transcript .sentence, .sentence');
            var results = [];
            
            for (var i = 0; i < sentences.length; i++) {
                var s = sentences[i];
                var timeSpan = s.querySelector('[data-start]');
                var start = timeSpan ? timeSpan.getAttribute('data-start') : (s.getAttribute('data-start-time') || "0");
                
                // 텍스트 추출
                var text = s.textContent.trim();
                if (text.length > 0) {
                    results.push(start + "|" + text);
                }
            }
            
            if (results.length === 0) return "ERROR:NO_DATA";
            
            return m3u8 + "###" + results.join("@@@");
        } catch (e) {
            return "ERROR:" + e.message;
        }
        """
        
        do {
            guard let rawString = try await page.callJavaScript(dataScript) as? String,
                  !rawString.hasPrefix("ERROR:") else {
                print("⚠️ 자막 데이터를 가져오지 못했습니다.")
                return
            }
            
            let components = rawString.components(separatedBy: "###")
            self.m3u8URL = components.first == "" ? nil : components.first
            
            if components.count > 1 {
                let lines = components[1].components(separatedBy: "@@@")
                var newSubtitles: [Subtitle] = []
                
                for line in lines {
                    let parts = line.components(separatedBy: "|")
                    if parts.count == 2 {
                        newSubtitles.append(Subtitle(startTime: Double(parts[0]) ?? 0.0, endTime: 0.0, text: parts[1]))
                    }
                }
                
                // 종료 시간 계산
                for i in 0..<newSubtitles.count {
                    if i < newSubtitles.count - 1 {
                        newSubtitles[i].endTime = newSubtitles[i+1].startTime
                    } else {
                        newSubtitles[i].endTime = newSubtitles[i].startTime + 3.0
                    }
                }
                
                self.subtitles = newSubtitles
                print("✅ 성공: \(self.subtitles.count)개의 Subtitle 모델 생성 완료")
            }
        } catch {
            print("❌ 추출 실패: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
}

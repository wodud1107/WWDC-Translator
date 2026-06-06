# WWDC Translator

WWDC Translator는 WWDC 세션 학습 중 한국어 자막이 없는 불편을 줄이기 위해 만든 개인용 실시간 자막 번역 앱입니다.
WWDC 페이지의 transcript를 가져오고, Apple Translation Framework로 번역한 뒤, AVPlayer 재생 시간에 맞춰 영상 위에 자막을 표시합니다.

사용 영상 https://developer.apple.com/videos/play/wwdc2016/416/
<img alt="스크린샷 2026-03-10 오전 2 34 34" src="https://github.com/user-attachments/assets/a1981b7a-b705-4675-b827-8383871d4ccb" />

## Tech Stack

- SwiftUI
- WebKit
- AVKit
- Apple Translation Framework
- Swift 6

## Why

WWDC 세션은 원문 transcript가 잘 제공되지만, 영상 재생 시간과 한국어 이해 흐름을 동시에 맞추기는 번거롭습니다.
외부 번역 API 비용이나 API key 관리 없이, Apple 시스템 프레임워크만으로 학습용 MVP를 빠르게 검증하는 것을 목표로 했습니다.

## Core Flow

1. 사용자가 WWDC 세션 URL을 입력합니다.
2. WebKit으로 WWDC 페이지의 transcript와 시작 시간을 추출합니다.
3. Apple Translation Framework로 원문 transcript를 한국어로 번역합니다.
4. AVPlayer의 재생 시간을 관찰해 현재 시점에 맞는 자막을 영상 위에 렌더링합니다.

## Key Decisions

### 외부 번역 API 없는 MVP

번역 API를 사용하면 비용, API key 관리, 네트워크 의존성이 생깁니다.
Apple Translation Framework를 사용해 시스템 번역 세션 기반으로 동작하도록 만들고, 개인 학습 도구로서 필요한 가치를 먼저 검증했습니다.

### Transcript와 영상 시간 싱크 연결

번역문이 영상 시간과 맞지 않으면 실제 학습 도구로 쓰기 어렵습니다.
WWDC transcript의 시간 정보와 AVPlayer time observer를 연결해 현재 재생 시점에 맞는 자막을 표시했습니다.

### 기능 검증 이후 구조 개선

초기 버전은 문제 해결 여부를 빠르게 확인하기 위해 ContentView 중심으로 구현했습니다.
다음 단계에서는 transcript 추출, 번역 세션, player sync를 ViewModel과 서비스 계층으로 분리해 유지보수성을 높일 계획입니다.

## Current Status

현재 버전은 개인 학습 문제를 제품 형태로 검증한 Prototype입니다.
이후 WebView 의존도를 낮추고, 네이티브 데이터 계층과 MVVM 구조로 리팩토링할 예정입니다.

//
//  DeepLService.swift
//  WWDC-Translator
//
//  Created by 김재영 on 3/9/26.
//

import Foundation

enum DeepLError: Error {
    case missingApiKey
    case invalidResponse
    case requestFailed(String)
}

struct DeepLResponse: Codable {
    struct Translation: Codable {
        let text: String
    }
    let translations: [Translation]
}

final class DeepLService {
    private var apiKey: String?
    private let endpoint = "https://api-free.deepl.com/v2/translate"

    init() {
        guard let path = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: path),
              let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let key = dict["DEEPL_API_KEY"] as? String else {
            return
        }
        self.apiKey = key
    }

    func translate(_ text: String, targetLang: String = "KO") async throws -> String {
        guard let key = apiKey else { throw DeepLError.missingApiKey }
        
        var urlComponents = URLComponents(string: endpoint)!
        urlComponents.queryItems = [
            URLQueryItem(name: "text", value: text),
            URLQueryItem(name: "target_lang", value: targetLang)
        ]
        
        guard let url = urlComponents.url else { throw DeepLError.invalidResponse }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("DeepL-Auth-Key \(key)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw DeepLError.requestFailed("HTTP Error: \(statusCode)")
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(DeepLResponse.self, from: data)
        return result.translations.first?.text ?? ""
    }
}

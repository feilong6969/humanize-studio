import SwiftUI
import AppKit
import Foundation
import Security

enum KeyStore {
    static let service = "HumanizeStudio", account = "openai-key"
    static func load() -> String {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
          kSecAttrService as String: service, kSecAttrAccount as String: account,
          kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var value: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &value) == errSecSuccess,
              let data = value as? Data else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
    static func save(_ key: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
          kSecAttrService as String: service, kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
        guard !key.isEmpty else { return }
        let add = query.merging([kSecValueData as String: Data(key.utf8)]) { _, new in new }
        SecItemAdd(add as CFDictionary, nil)
    }
}
struct APIResponse: Decodable {
    struct Output: Decodable {
        struct Content: Decodable { let type: String?; let text: String? }
        let content: [Content]?
    }
    let output: [Output]?
}
@MainActor final class EditorModel: ObservableObject {
    @Published var source = ""
    @Published var result = ""
    @Published var language = "Auto"
    @Published var tone = "Natural"
    @Published var key = KeyStore.load()
    @Published var busy = false
    @Published var status = "Enter text, set your API key, then choose Rewrite."
    let languages = ["Auto", "English", "日本語"]
    let tones = ["Natural", "Casual", "Simple", "Professional", "Student"]
    func storeKey() {
        KeyStore.save(key.trimmingCharacters(in: .whitespacesAndNewlines))
        status = key.isEmpty ? "API key cleared." : "API key saved in macOS Keychain."
    }
    func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result, forType: .string)
        status = "Copied."
    }
    func rewrite() async {
        let text = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { status = "Enter some text first."; return }
        guard !token.isEmpty else { status = "Enter and save an OpenAI API key first."; return }
        guard text.count <= 20000 else { status = "Limit is 20,000 characters."; return }
        busy = true; status = "Rewriting…"
        defer { busy = false }
        do {
            let rules = """
            Rewrite the user's passage so it sounds natural and clear. Preserve the meaning,             factual claims, names, and citations. Do not invent facts or deliberately insert errors.             Tone: \(tone). Language: \(language == "Auto" ? "keep the original language" : language).             Return only the rewritten passage without an introduction.
            """
            var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 60
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "model": "gpt-4.1-mini", "instructions": rules,
                "input": text, "max_output_tokens": 2500
            ])
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw RewriteError.message("No server response.") }
            guard (200..<300).contains(http.statusCode) else {
                throw RewriteError.message("API request failed (HTTP \(http.statusCode)). Check your key and API billing.")
            }
            let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
            let rewritten = (decoded.output ?? []).flatMap { $0.content ?? [] }
                .filter { $0.type == "output_text" }
                .compactMap { $0.text }.joined()
            guard !rewritten.isEmpty else { throw RewriteError.message("The API returned no rewritten text.") }
            result = rewritten; status = "Done. Review the result for accuracy."
        } catch { status = "Error: \(error.localizedDescription)" }
    }
}
enum RewriteError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let text) = self { return text }; return nil }
}
struct MainView: View {
    @StateObject private var editor = EditorModel()
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Humanize Studio").font(.largeTitle).bold()
                    Text("Make your writing sound more natural.").foregroundStyle(.secondary)
                }
                Spacer()
                Text("English · 日本語").foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                Picker("Style", selection: $editor.tone) {
                    ForEach(editor.tones, id: \.self) { Text($0) }
                }.frame(width: 220)
                Picker("Language", selection: $editor.language) {
                    ForEach(editor.languages, id: \.self) { Text($0) }
                }.frame(width: 220)
                Spacer()
            }
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Your text").font(.headline)
                    TextEditor(text: $editor.source)
                        .font(.body).scrollContentBackground(.hidden)
                        .padding(8).background(.quaternary.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                VStack(alignment: .leading, spacing: 7) {
                    Text("Rewritten text").font(.headline)
                    TextEditor(text: $editor.result)
                        .font(.body).scrollContentBackground(.hidden)
                        .padding(8).background(.quaternary.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            HStack {
                Button("Rewrite with AI") { Task { await editor.rewrite() } }
                    .buttonStyle(.borderedProminent).disabled(editor.busy)
                Button("Copy result") { editor.copy() }.disabled(editor.result.isEmpty)
                Button("Clear") { editor.source = ""; editor.result = "" }
                if editor.busy { ProgressView().controlSize(.small) }
                Spacer()
            }
            Divider()
            HStack {
                SecureField("OpenAI API key (sk-…)", text: $editor.key)
                    .textFieldStyle(.roundedBorder)
                Button("Save key") { editor.storeKey() }
            }
            Text("Your key stays in macOS Keychain. Text is sent to OpenAI only when you press Rewrite. API usage may cost money.")
                .font(.caption).foregroundStyle(.secondary)
            Text(editor.status).font(.callout).foregroundStyle(.secondary).lineLimit(2)
        }
        .padding(24).frame(minWidth: 830, minHeight: 560)
    }
}
@main struct HumanizeStudioApp: App {
    var body: some Scene { WindowGroup { MainView() } }
}

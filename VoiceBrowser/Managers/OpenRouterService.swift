import Foundation

class OpenRouterService {
    static let shared = OpenRouterService()

    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    private let apiKey: String?
    private let model = "tencent/hy3:free"

    private let systemPrompt = """
    Sei un assistente vocale per un browser mobile chiamato VoiceBrowser.
    L'utente parla e tu devi tradurre le sue richieste in comandi JSON per il browser.

    REGOLE:
    - Rispondi SOLO con JSON, nient'altro. Mai testo fuori dal JSON.
    - Usa sempre la lingua italiana per query e testi.

    COMANDI DISPONIBILI:
    {"action": "navigate", "url": "https://..."}
    {"action": "search", "query": "testo ricerca"}
    {"action": "scroll", "direction": "up/down", "amount": numero_pixel}
    {"action": "click", "text": "testo esatto elemento"}
    {"action": "back"}
    {"action": "forward"}
    {"action": "refresh"}
    {"action": "read"}
    {"action": "say", "text": "cosa dire all'utente"}

    ESEMPI:
    "vai su google" -> {"action": "navigate", "url": "https://google.com"}
    "cerca ristoranti a milano" -> {"action": "search", "query": "ristoranti milano"}
    "scorri giu" -> {"action": "scroll", "direction": "down", "amount": 500}
    "clicca su accetta cookie" -> {"action": "click", "text": "Accetta"}
    "torna indietro" -> {"action": "back"}
    "vai avanti" -> {"action": "forward"}
    "ricarica" -> {"action": "refresh"}
    "leggi la pagina" -> {"action": "read"}
    "cosa sai fare" -> {"action": "say", "text": "Posso navigare su siti web, cercare informazioni, scorrere, cliccare link e leggere contenuti. Prova a dirmi 'vai su google' o 'cerca qualcosa'!"}
    "apri youtube" -> {"action": "navigate", "url": "https://youtube.com"}
    "cerca video di gatti" -> {"action": "search", "query": "video di gatti divertenti"}
    """

    private init() {
        self.apiKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]
    }

    func sendCommand(_ text: String) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw OpenRouterError.missingKey
        }

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": text]
        ]

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.2,
            "max_tokens": 300
        ]

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResp = response as? HTTPURLResponse,
              (200...299).contains(httpResp.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        return message?["content"] as? String ?? ""
    }
}

enum OpenRouterError: LocalizedError {
    case missingKey

    var errorDescription: String? {
        switch self {
        case .missingKey:
            return "API key non configurata. Imposta OPENROUTER_API_KEY come variabile d'ambiente."
        }
    }
}

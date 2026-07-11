import Foundation

struct BrowserCommand: Codable {
    let action: String
    let url: String?
    let query: String?
    let direction: String?
    let amount: Int?
    let text: String?
}

enum ParsedCommand {
    case navigate(url: String)
    case search(query: String)
    case scroll(direction: String, amount: Int)
    case click(text: String)
    case goBack
    case goForward
    case refresh
    case read
    case say(text: String)
    case unknown

    static func from(json: String) -> ParsedCommand {
        guard let data = json.data(using: .utf8),
              let cmd = try? JSONDecoder().decode(BrowserCommand.self, from: data) else {
            return .unknown
        }

        switch cmd.action {
        case "navigate":
            if let url = cmd.url { return .navigate(url: url) }
        case "search":
            if let query = cmd.query { return .search(query: query) }
        case "scroll":
            return .scroll(direction: cmd.direction ?? "down", amount: cmd.amount ?? 300)
        case "click":
            if let text = cmd.text { return .click(text: text) }
        case "back":
            return .goBack
        case "forward":
            return .goForward
        case "refresh":
            return .refresh
        case "read":
            return .read
        case "say":
            if let text = cmd.text { return .say(text: text) }
        default:
            break
        }
        return .unknown
    }
}

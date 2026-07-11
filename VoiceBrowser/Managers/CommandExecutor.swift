import WebKit

@MainActor
class CommandExecutor {
    private weak var webView: WKWebView?

    init(webView: WKWebView) {
        self.webView = webView
    }

    func execute(_ command: ParsedCommand) async -> String? {
        guard let webView = webView else { return "Browser non disponibile" }

        switch command {
        case .navigate(let url):
            var urlString = url
            if !urlString.contains("://") {
                urlString = "https://\(urlString)"
            }
            guard let url = URL(string: urlString) else { return "URL non valido" }
            webView.load(URLRequest(url: url))
            return nil

        case .search(let query):
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            guard let url = URL(string: "https://www.google.com/search?q=\(encoded)") else {
                return "Impossibile cercare"
            }
            webView.load(URLRequest(url: url))
            return nil

        case .scroll(let direction, let amount):
            let delta = direction == "up" ? -amount : amount
            let current = webView.scrollView.contentOffset
            webView.scrollView.setContentOffset(
                CGPoint(x: current.x, y: current.y + CGFloat(delta)),
                animated: true
            )
            return nil

        case .click(let text):
            let escaped = text
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
            let js = """
            (function() {
                function findAndClick(el) {
                    let text = (el.textContent || '').trim().toLowerCase();
                    let placeholder = (el.placeholder || '').toLowerCase();
                    let aria = (el.getAttribute('aria-label') || '').toLowerCase();
                    let val = (el.value || '').toLowerCase();
                    let target = '\(escaped)'.toLowerCase();
                    if (text.includes(target) || placeholder.includes(target) || aria.includes(target) || val.includes(target)) {
                        el.click(); el.focus(); return true;
                    }
                    return false;
                }
                let tags = ['a','button','input','span','div','li','label','[role=button]','[role=link]','[role=option]'];
                let all = document.querySelectorAll(tags.join(','));
                for (let el of all) { if (findAndClick(el)) return true; }
                return false;
            })()
            """
            let result = try? await webView.evaluateJavaScript(js)
            let found = result as? Bool ?? false
            return found ? nil : "Elemento '\(text)' non trovato"

        case .goBack:
            if webView.canGoBack { webView.goBack() }
            return nil

        case .goForward:
            if webView.canGoForward { webView.goForward() }
            return nil

        case .refresh:
            webView.reload()
            return nil

        case .read:
            let js = "document.body.innerText || document.body.textContent || ''"
            let raw = try? await webView.evaluateJavaScript(js)
            if let text = raw as? String {
                let cleaned = text
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return String(cleaned.prefix(3000))
            }
            return "Impossibile leggere il contenuto della pagina"

        case .say(let text):
            return text

        case .unknown:
            return "Comando non riconosciuto"
        }
    }
}

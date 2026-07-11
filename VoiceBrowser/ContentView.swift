import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var speechManager = SpeechManager()

    @State private var webView = WKWebView(frame: .zero)
    @State private var urlString = ""
    @State private var isLoading = false
    @State private var canGoBack = false
    @State private var canGoForward = false

    @State private var statusMessage: String?
    @State private var showStatus = false
    @State private var isProcessing = false
    @State private var authChecked = false

    var body: some View {
        VStack(spacing: 0) {
            BrowserWebView(
                webView: webView,
                urlString: $urlString,
                isLoading: $isLoading,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward
            )

            if showStatus, let msg = statusMessage {
                statusBanner(msg)
            }

            if isProcessing {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.7)
                    Text("Elaborazione...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            ControlBar(
                urlString: $urlString,
                isLoading: isLoading,
                canGoBack: canGoBack,
                canGoForward: canGoForward,
                isListening: speechManager.isListening,
                transcription: speechManager.transcription,
                onNavigate: { url in loadURL(url) },
                onGoBack: { webView.goBack() },
                onGoForward: { webView.goForward() },
                onRefresh: { webView.reload() },
                onMicTap: handleMicTap
            )
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            loadURL("https://google.com")
            Task {
                authChecked = true
                _ = await speechManager.requestAuthorization()
            }
        }
    }

    private func statusBanner(_ text: String) -> some View {
        HStack {
            Image(systemName: "speaker.wave.2.fill")
                .foregroundStyle(.tint)
                .font(.caption)
            Text(text)
                .font(.caption)
                .lineLimit(2)
            Spacer()
            Button {
                withAnimation { showStatus = false }
            } label: {
                Image(systemName: "xmark").font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func loadURL(_ urlString: String) {
        var final = urlString
        if !final.contains("://") { final = "https://\(final)" }
        guard let url = URL(string: final) else { return }
        webView.load(URLRequest(url: url))
    }

    private func handleMicTap() {
        if speechManager.isListening {
            speechManager.stopListening()
            return
        }

        guard speechManager.isAuthorized else {
            statusMessage = "Permetti l'accesso al microfono nelle Impostazioni"
            withAnimation { showStatus = true }
            return
        }

        speechManager.startListening { text in
            guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            processVoiceCommand(text)
        }
    }

    private func processVoiceCommand(_ text: String) {
        isProcessing = true
        showStatus = false

        Task {
            do {
                let reply = try await OpenRouterService.shared.sendCommand(text)
                isProcessing = false

                let command = ParsedCommand.from(json: reply)
                let feedback = await CommandExecutor(webView: webView).execute(command)

                if let feedback = feedback {
                    speechManager.speak(feedback)
                    statusMessage = feedback
                    withAnimation { showStatus = true }
                }
            } catch {
                isProcessing = false
                statusMessage = "Errore: \(error.localizedDescription)"
                withAnimation { showStatus = true }
            }
        }
    }
}

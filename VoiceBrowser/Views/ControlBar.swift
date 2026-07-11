import SwiftUI

struct ControlBar: View {
    @Binding var urlString: String
    let isLoading: Bool
    let canGoBack: Bool
    let canGoForward: Bool
    let isListening: Bool
    let transcription: String
    let showCommandBar: Bool
    let onNavigate: (String) -> Void
    let onGoBack: () -> Void
    let onGoForward: () -> Void
    let onRefresh: () -> Void
    let onMicTap: () -> Void
    let onToggleCommand: () -> Void

    @State private var showURLSheet = false
    @State private var editURL = ""

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 6) {
                navButton(icon: "chevron.left", action: onGoBack, disabled: !canGoBack)
                navButton(icon: "chevron.right", action: onGoForward, disabled: !canGoForward)
                navButton(icon: "arrow.clockwise", action: onRefresh, disabled: isLoading)

                Button {
                    editURL = urlString
                    showURLSheet = true
                } label: {
                    HStack(spacing: 4) {
                        if isLoading {
                            ProgressView().scaleEffect(0.7)
                        }
                        Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.green)
                        Text(urlDisplay)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial)
                    .clipShape(.rect(cornerRadius: 8))
                }

                commandToggle
                micButton
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)

            if isListening {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundStyle(.red)
                        .symbolEffect(.pulse)
                    Text(transcription.isEmpty ? "Ascoltando..." : transcription)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.red.opacity(0.08))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showURLSheet) {
            NavigationStack {
                VStack(spacing: 16) {
                    TextField("Inserisci URL", text: $editURL)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                }
                .padding()
                .navigationTitle("Vai a")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Annulla") { showURLSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Vai") {
                            urlString = editURL
                            onNavigate(editURL)
                            showURLSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.height(160)])
        }
    }

    private var urlDisplay: String {
        urlString
            .replacingOccurrences(of: "https://www.", with: "")
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private func navButton(icon: String, action: @escaping () -> Void, disabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(disabled ? .tertiary : .primary)
                .frame(width: 32, height: 32)
                .background(.regularMaterial)
                .clipShape(.circle)
        }
        .disabled(disabled)
    }

    private var commandToggle: some View {
        Button(action: onToggleCommand) {
            Image(systemName: showCommandBar ? "keyboard.fill" : "keyboard")
                .font(.caption)
                .foregroundStyle(showCommandBar ? .white : .primary)
                .frame(width: 32, height: 32)
                .background(showCommandBar ? AnyShapeStyle(AppTint) : AnyShapeStyle(.regularMaterial))
                .clipShape(.circle)
        }
    }

    private var micButton: some View {
        Button(action: onMicTap) {
            Image(systemName: isListening ? "mic.fill" : "mic")
                .font(.body)
                .foregroundStyle(isListening ? .white : .primary)
                .frame(width: 36, height: 36)
                .background(isListening ? Color.red : AppTint)
                .clipShape(.circle)
        }
    }
}

private let AppTint = Color(red: 0.0, green: 0.48, blue: 1.0)

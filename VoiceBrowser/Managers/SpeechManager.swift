import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechManager: ObservableObject {
    private let recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()

    @Published var isAuthorized = false
    @Published var transcription = ""
    @Published var isListening = false

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "it-IT"))
    }

    func requestAuthorization() async -> Bool {
        let speechStatus = await SFSpeechRecognizer.requestAuthorization()
        let audioGranted = await AVAudioSession.sharedInstance().requestRecordPermission()
        isAuthorized = speechStatus == .authorized && audioGranted
        return isAuthorized
    }

    func startListening(completion: @escaping (String) -> Void) {
        guard let recognizer = recognizer, recognizer.isAvailable else { return }

        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()
        isListening = true

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let text = result.bestTranscription.formattedString
                self.transcription = text

                if result.isFinal {
                    self.stopListening()
                    completion(text)
                }
            }

            if error != nil {
                self.stopListening()
            }
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
    }

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "it-IT")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.1
        synthesizer.speak(utterance)
    }
}

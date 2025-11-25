import CoreImage
import CoreImage.CIFilterBuiltins
import Vision

enum ScreenshotCategory: String, CaseIterable, Identifiable {
    case chat
    case meme
    case ui
    case textDocument
    case photo
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chat: return "Chat / Messaging"
        case .meme: return "Meme"
        case .ui: return "App/Website UI"
        case .textDocument: return "Textdokument"
        case .photo: return "Foto"
        case .unknown: return "Unklar"
        }
    }
}

struct ClassificationResult {
    let primaryCategory: ScreenshotCategory
    let secondaryCategories: [ScreenshotCategory]
    let diagnostics: [String: String]
}

final class ScreenshotClassifier: ObservableObject {
    @Published private(set) var lastResult: ClassificationResult?

    private let ciContext = CIContext()

    func classify(image: PlatformImage) async throws {
#if canImport(UIKit)
        guard let cgImage = image.cgImage else { return }
#elseif canImport(AppKit)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
#else
        return
#endif

        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .fast
        textRequest.usesLanguageCorrection = false

        let classifyRequest = VNClassifyImageRequest()

        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([textRequest, classifyRequest])

        let textObservations = (textRequest.results as? [VNRecognizedTextObservation]) ?? []
        let classificationObservations = (classifyRequest.results as? [VNClassificationObservation]) ?? []

        let textStats = analyze(textObservations: textObservations, imageSize: cgImage.width * cgImage.height)
        let brightness = averageBrightness(for: cgImage)
        let topIdentifiers = classificationObservations.prefix(3)
        let identifierSummary = topIdentifiers.map { "\($0.identifier) \(Int($0.confidence * 100))%" }.joined(separator: ", ")

        let category = pickCategory(textStats: textStats, brightness: brightness, observations: classificationObservations)
        let secondary = ScreenshotCategory.allCases.filter { $0 != category && isPotentialCategory($0, textStats: textStats, brightness: brightness, observations: classificationObservations) }

        let diagnostics: [String: String] = [
            "Textblöcke": "\(textStats.blockCount)",
            "Zeichen": "\(textStats.characterCount)",
            "Textfläche": String(format: "%.0f%%", textStats.coverage * 100),
            "Helligkeit": String(format: "%.2f", brightness),
            "Top-Labels": identifierSummary
        ]

        let result = ClassificationResult(
            primaryCategory: category,
            secondaryCategories: Array(secondary.prefix(2)),
            diagnostics: diagnostics
        )

        await MainActor.run {
            self.lastResult = result
        }
    }

    private func analyze(textObservations: [VNRecognizedTextObservation], imageSize: Int) -> (coverage: Double, blockCount: Int, characterCount: Int) {
        guard imageSize > 0 else { return (0, 0, 0) }
        var textArea: Double = 0
        var characters = 0

        for observation in textObservations {
            let box = observation.boundingBox
            textArea += Double(box.width * box.height)
            let candidate = observation.topCandidates(1).first
            characters += candidate?.string.count ?? 0
        }

        return (coverage: textArea, blockCount: textObservations.count, characterCount: characters)
    }

    private func averageBrightness(for cgImage: CGImage) -> Double {
        let inputImage = CIImage(cgImage: cgImage)
        let filter = CIFilter.areaAverage()
        filter.inputImage = inputImage
        filter.extent = inputImage.extent

        guard let outputImage = filter.outputImage,
              let bitmap = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            return 0.5
        }

        let data = CFDataCreateMutable(nil, 4)!
        let context = CGContext(
            data: CFDataGetMutableBytePtr(data),
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!

        context.draw(bitmap, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        let pixel = CFDataGetMutableBytePtr(data)!
        let r = Double(pixel[0]) / 255.0
        let g = Double(pixel[1]) / 255.0
        let b = Double(pixel[2]) / 255.0
        return (r + g + b) / 3.0
    }

    private func pickCategory(textStats: (coverage: Double, blockCount: Int, characterCount: Int), brightness: Double, observations: [VNClassificationObservation]) -> ScreenshotCategory {
        let textDensity = textStats.coverage
        let topIdentifier = observations.first?.identifier.lowercased() ?? ""

        if textStats.blockCount > 3 && textDensity > 0.05 {
            if topIdentifier.contains("chat") || topIdentifier.contains("messag") {
                return .chat
            }
            return .textDocument
        }

        if topIdentifier.contains("screengrab") || topIdentifier.contains("monitor") || topIdentifier.contains("screen") {
            return .ui
        }

        if brightness > 0.7 && textStats.blockCount < 2 {
            return .photo
        }

        if observations.contains(where: { $0.identifier.lowercased().contains("comic") || $0.identifier.lowercased().contains("meme") }) {
            return .meme
        }

        if textStats.blockCount >= 1 && brightness > 0.3 {
            return .chat
        }

        return .unknown
    }

    private func isPotentialCategory(_ category: ScreenshotCategory, textStats: (coverage: Double, blockCount: Int, characterCount: Int), brightness: Double, observations: [VNClassificationObservation]) -> Bool {
        switch category {
        case .chat:
            return textStats.blockCount > 0 && brightness > 0.3
        case .meme:
            return observations.contains { $0.identifier.lowercased().contains("comic") || $0.identifier.lowercased().contains("meme") }
        case .ui:
            return observations.contains { $0.identifier.lowercased().contains("screen") || $0.identifier.lowercased().contains("website") }
        case .textDocument:
            return textStats.coverage > 0.04
        case .photo:
            return brightness > 0.6 && textStats.blockCount < 2
        case .unknown:
            return observations.isEmpty
        }
    }
}

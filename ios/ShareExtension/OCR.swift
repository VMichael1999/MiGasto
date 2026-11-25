import UIKit
import Vision

/// Lee el texto de una imagen en el teléfono (Vision). La captura no sale del
/// teléfono ni se guarda: solo se conserva el texto que se lee.
enum OCR {
    /// Cada texto con su lugar en la captura (para rearmar la tabla de la constancia).
    static func boxes(in image: UIImage) async -> [TextBox] {
        guard let cgImage = image.cgImage else { return [] }
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let boxes = observations.compactMap { o -> TextBox? in
                    guard let text = o.topCandidates(1).first?.string else { return nil }
                    let b = o.boundingBox
                    return TextBox(text: text, minX: b.minX, maxX: b.maxX, midY: b.midY, height: b.height)
                }
                continuation.resume(returning: boxes)
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["es-ES", "en-US"]
            request.usesLanguageCorrection = true

            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }
}

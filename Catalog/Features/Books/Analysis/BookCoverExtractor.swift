import CoreGraphics
import CoreImage
import Foundation
import Vision

/// Extracts and perspective-corrects a book cover from a source image.
struct BookCoverExtractor: Sendable {
    func extractCover(from image: CGImage) async -> CGImage? {
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 8
        request.minimumConfidence = 0.5
        request.minimumAspectRatio = 0.25
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.25
        request.quadratureTolerance = 35

        do {
            try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
        } catch {
            return nil
        }

        guard let rectangle = bestRectangle(in: request.results ?? []) else {
            return nil
        }

        return perspectiveCorrectedImage(image, using: rectangle)
    }

    private func bestRectangle(in observations: [VNRectangleObservation]) -> VNRectangleObservation? {
        observations.max { lhs, rhs in
            score(lhs) < score(rhs)
        }
    }

    private func score(_ observation: VNRectangleObservation) -> CGFloat {
        let area = observation.boundingBox.width * observation.boundingBox.height
        return area * CGFloat(max(observation.confidence, 0.01))
    }

    private func perspectiveCorrectedImage(
        _ image: CGImage,
        using rectangle: VNRectangleObservation
    ) -> CGImage? {
        let inputImage = CIImage(cgImage: image)
        let imageSize = inputImage.extent.size

        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else {
            return nil
        }

        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(vector(for: rectangle.topLeft, imageSize: imageSize), forKey: "inputTopLeft")
        filter.setValue(vector(for: rectangle.topRight, imageSize: imageSize), forKey: "inputTopRight")
        filter.setValue(vector(for: rectangle.bottomLeft, imageSize: imageSize), forKey: "inputBottomLeft")
        filter.setValue(vector(for: rectangle.bottomRight, imageSize: imageSize), forKey: "inputBottomRight")

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let extent = outputImage.extent.integral
        guard extent.width > 0, extent.height > 0 else {
            return nil
        }

        return CIContext().createCGImage(outputImage, from: extent)
    }

    private func vector(for point: CGPoint, imageSize: CGSize) -> CIVector {
        CIVector(
            x: point.x * imageSize.width,
            y: point.y * imageSize.height
        )
    }
}

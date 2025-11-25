import PhotosUI
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var classifier: ScreenshotClassifier
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: PlatformImage?
    @State private var isBusy = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                    Label("Screenshot wählen", systemImage: "photo.on.rectangle")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isBusy)
                .onChange(of: selectedItem) { newItem in
                    Task {
                        await loadImage(from: newItem)
                    }
                }

                if let image = selectedImage {
                    #if canImport(UIKit)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 6)
                    #elseif canImport(AppKit)
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 6)
                    #endif
                }

                if isBusy {
                    ProgressView("Analysiere…")
                } else if let result = classifier.lastResult {
                    CategoryResultView(result: result)
                }

                if let message = errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("CleanShot")
        }
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            isBusy = true
            selectedImage = nil
            errorMessage = nil
            if let data = try await item.loadTransferable(type: Data.self),
               let image = PlatformImage(data: data) {
                selectedImage = image
                try await classifier.classify(image: image)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isBusy = false
    }
}

struct CategoryResultView: View {
    let result: ClassificationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kategorie: \(result.primaryCategory.title)")
                .font(.headline)
            if !result.secondaryCategories.isEmpty {
                Text("Weitere Treffer: \(result.secondaryCategories.map { $0.title }.joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !result.diagnostics.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Analyse")
                        .font(.subheadline)
                        .bold()
                    ForEach(result.diagnostics.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        Text("\(key): \(value)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ScreenshotClassifier())
    }
}

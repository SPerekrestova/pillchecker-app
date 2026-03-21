import SwiftUI

struct ScanMedicineView: View {
    let slot: Int
    let drugInputViewModel: DrugInputViewModel
    @Environment(AppNavigator.self) private var navigator
    @State private var viewModel: ScanViewModel
    @State private var imageSource: UIImagePickerController.SourceType = .camera

    init(slot: Int, drugInputViewModel: DrugInputViewModel, apiClient: APIClient, ocrService: OCRService) {
        self.slot = slot
        self.drugInputViewModel = drugInputViewModel
        self._viewModel = State(initialValue: ScanViewModel(apiClient: apiClient, ocrService: ocrService))
    }

    private var network = NetworkMonitor.shared

    var body: some View {
        VStack(spacing: 0) {
            if !network.isConnected {
                OfflineBanner()
            }

            ScrollView {
                VStack(spacing: 20) {
                    if let image = viewModel.capturedImage {
                        capturedImageSection(image)
                    } else {
                        sourceSelectionSection
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Scan Medicine")
        .sheet(isPresented: $viewModel.showCamera) {
            ImagePicker(sourceType: imageSource) { image in
                Task { await viewModel.processImage(image) }
            }
        }
    }

    // MARK: - Source selection (replaces auto-firing confirmation dialog)

    private var sourceSelectionSection: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)

            Text("Take a photo of the medicine packaging to identify the drug.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        imageSource = .camera
                        viewModel.showCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button {
                    imageSource = .photoLibrary
                    viewModel.showCamera = true
                } label: {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.top, 40)
    }

    // MARK: - Captured image result

    @ViewBuilder
    private func capturedImageSection(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 250)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))

        if viewModel.isProcessing {
            ProgressView("Analyzing...")
        } else if let error = viewModel.error {
            Text(error)
                .foregroundStyle(Theme.critical)
                .font(.callout)
                .accessibilityAddTraits(.isStaticText)
        }

        // Only show drug name field when we have an extracted drug
        if viewModel.extractedDrug != nil {
            TextField("Drug name", text: $viewModel.editableDrugName)
                .textFieldStyle(.roundedBorder)
                .font(.headline)
                .accessibilityLabel("Identified drug name")

            if let rawText = viewModel.recognizedText {
                DisclosureGroup("Raw OCR Text") {
                    Text(rawText)
                        .font(.caption.monospaced())
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Button("Retake") {
                viewModel.retake()
            }
            .buttonStyle(.bordered)

            Button {
                let name = viewModel.editableDrugName.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }

                if let drug = viewModel.extractedDrug,
                   drug.name.localizedCaseInsensitiveCompare(name) == .orderedSame {
                    // Name unchanged — use the full DrugResult
                    drugInputViewModel.setDrug(index: slot, drug: drug)
                } else {
                    // User edited the name — use manual entry
                    drugInputViewModel.setManualName(index: slot, name: name)
                }

                navigator.pop()
            } label: {
                Text("Use This Drug")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.editableDrugName.trimmingCharacters(in: .whitespaces).isEmpty)
        } else if !viewModel.isProcessing && viewModel.error != nil {
            // Error state — offer retake only
            Button("Retake") {
                viewModel.retake()
            }
            .buttonStyle(.bordered)
        }
    }
}

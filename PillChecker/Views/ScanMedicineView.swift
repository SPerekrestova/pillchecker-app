import SwiftUI

struct ScanMedicineView: View {
    let slot: Int
    let drugInputViewModel: DrugInputViewModel
    @Environment(AppNavigator.self) private var navigator
    @State private var viewModel: ScanViewModel
    @State private var showSourcePicker = true
    @State private var imageSource: UIImagePickerController.SourceType = .camera

    init(slot: Int, drugInputViewModel: DrugInputViewModel, apiClient: APIClient, ocrService: OCRService) {
        self.slot = slot
        self.drugInputViewModel = drugInputViewModel
        self._viewModel = State(initialValue: ScanViewModel(apiClient: apiClient, ocrService: ocrService))
    }

    var body: some View {
        VStack(spacing: 20) {
            if let image = viewModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if viewModel.isProcessing {
                    ProgressView("Analyzing...")
                } else if let error = viewModel.error {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.callout)
                }

                if viewModel.extractedDrug != nil || viewModel.editableDrugName.isEmpty == false {
                    TextField("Drug name", text: $viewModel.editableDrugName)
                        .textFieldStyle(.roundedBorder)
                        .font(.headline)

                    if let rawText = viewModel.recognizedText {
                        DisclosureGroup("Raw OCR Text") {
                            Text(rawText)
                                .font(.caption.monospaced())
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    HStack(spacing: 16) {
                        Button("Retake") {
                            viewModel.retake()
                            showSourcePicker = true
                        }
                        .buttonStyle(.bordered)

                        Button("Use This Drug") {
                            let name = viewModel.editableDrugName.trimmingCharacters(in: .whitespaces)
                            guard !name.isEmpty else { return }

                            if let drug = viewModel.extractedDrug {
                                drugInputViewModel.setDrug(index: slot, drug: drug)
                            } else {
                                drugInputViewModel.setManualName(index: slot, name: name)
                            }

                            navigator.pop()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                ContentUnavailableView(
                    "Scan Medicine",
                    systemImage: "camera.viewfinder",
                    description: Text("Take a photo of the medicine packaging to identify the drug.")
                )
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Scan Medicine")
        .confirmationDialog("Choose Source", isPresented: $showSourcePicker) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Camera") {
                    imageSource = .camera
                    viewModel.showCamera = true
                }
            }
            Button("Photo Library") {
                imageSource = .photoLibrary
                viewModel.showCamera = true
            }
        }
        .sheet(isPresented: $viewModel.showCamera) {
            ImagePicker(sourceType: imageSource) { image in
                Task { await viewModel.processImage(image) }
            }
        }
    }
}

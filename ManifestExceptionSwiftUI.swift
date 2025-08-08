import SwiftUI
import UniformTypeIdentifiers

// MARK: - SwiftUI View Model

@MainActor
class ManifestExceptionViewModel: ObservableObject {
    @Published var selectedPDFName: String = ""
    @Published var isProcessing: Bool = false
    @Published var status: String = "Ready"
    @Published var results: BatchResponse?
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var processType: ProcessType = .synchronous
    
    enum ProcessType: String, CaseIterable {
        case synchronous = "Synchronous"
        case asynchronous = "Asynchronous"
    }
    
    private let processor = ManifestExceptionProcessor(
        baseURL: "https://docker.nacompanies.com:452",
        username: "aidoctest",
        password: "AiD0cTest2025!"
    )
    
    private var selectedPDFPath: String?
    
    init() {
        Task {
            await authenticate()
        }
    }
    
    func authenticate() async {
        status = "Authenticating..."
        do {
            _ = try await processor.authenticate()
            isAuthenticated = true
            status = "Authenticated. Ready to process."
        } catch {
            errorMessage = "Authentication failed: \(error.localizedDescription)"
            showError = true
            status = "Authentication failed"
        }
    }
    
    func selectPDF(url: URL) {
        // Copy to app's documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsPath.appendingPathComponent(url.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Start accessing security-scoped resource
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            selectedPDFPath = destinationURL.path
            selectedPDFName = url.lastPathComponent
            status = "PDF selected: \(url.lastPathComponent)"
            
        } catch {
            errorMessage = "Failed to copy PDF: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func processDocument() async {
        guard let pdfPath = selectedPDFPath else { return }
        
        isProcessing = true
        results = nil
        
        do {
            if processType == .synchronous {
                status = "Processing document synchronously..."
                results = try await processor.processSync(
                    pdfPath: pdfPath,
                    identifier: "SWIFTUI_\(Date().timeIntervalSince1970)"
                )
                status = "Processing complete"
            } else {
                status = "Submitting document for async processing..."
                let submitResult = try await processor.processAsync(
                    pdfPath: pdfPath,
                    identifier: "SWIFTUI_\(Date().timeIntervalSince1970)"
                )
                
                let batchId = submitResult.metadata.identifier
                status = "Batch submitted: \(batchId). Polling for results..."
                
                results = try await processor.waitForCompletion(batchId: batchId)
                status = "Processing complete"
            }
        } catch {
            errorMessage = "Processing failed: \(error.localizedDescription)"
            showError = true
            status = "Processing failed"
        }
        
        isProcessing = false
    }
}

// MARK: - SwiftUI View

struct ManifestExceptionView: View {
    @StateObject private var viewModel = ManifestExceptionViewModel()
    @State private var showDocumentPicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Manifest Exception Processor")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(viewModel.status)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // PDF Selection
                    VStack(spacing: 12) {
                        Button(action: {
                            showDocumentPicker = true
                        }) {
                            HStack {
                                Image(systemName: "doc.fill")
                                Text("Select PDF")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        if !viewModel.selectedPDFName.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(viewModel.selectedPDFName)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Processing Type
                    Picker("Processing Type", selection: $viewModel.processType) {
                        ForEach(ManifestExceptionViewModel.ProcessType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Process Button
                    Button(action: {
                        Task {
                            await viewModel.processDocument()
                        }
                    }) {
                        if viewModel.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray)
                                .cornerRadius(10)
                        } else {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Process Document")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isAuthenticated && !viewModel.selectedPDFName.isEmpty ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .disabled(!viewModel.isAuthenticated || viewModel.selectedPDFName.isEmpty || viewModel.isProcessing)
                    .padding(.horizontal)
                    
                    // Results
                    if let results = viewModel.results {
                        ResultsView(results: results)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(onPick: viewModel.selectPDF)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
}

// MARK: - Results View

struct ResultsView: View {
    let results: BatchResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Processing Results")
                .font(.headline)
            
            if let output = results.output {
                // Manifest Info
                GroupBox("Manifest Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "Trip Number", value: output.general.manifestInfo.tripNumber)
                        InfoRow(label: "Manifest Number", value: output.general.manifestInfo.manifestNumber)
                        InfoRow(label: "Trailer Number", value: output.general.manifestInfo.trailerNumber)
                        InfoRow(label: "Shipments", value: "\(output.general.manifestInfo.expectedShipments) expected / \(output.general.manifestInfo.actualShipments) actual")
                        InfoRow(label: "Handling Units", value: "\(output.general.manifestInfo.expectedHandlingUnits) expected / \(output.general.manifestInfo.actualHandlingUnits) actual")
                    }
                    .padding(.vertical, 4)
                }
                
                // Summary
                GroupBox("Exception Summary") {
                    VStack(alignment: .leading, spacing: 8) {
                        SummaryRow(
                            icon: "minus.circle.fill",
                            color: .orange,
                            label: "Shortages",
                            count: output.general.summary.totalShortages,
                            pieces: output.general.summary.totalShortagePieces
                        )
                        SummaryRow(
                            icon: "plus.circle.fill",
                            color: .blue,
                            label: "Overages",
                            count: output.general.summary.totalOverages,
                            pieces: output.general.summary.totalOveragePieces
                        )
                        SummaryRow(
                            icon: "exclamationmark.triangle.fill",
                            color: .red,
                            label: "Damages",
                            count: output.general.summary.totalDamages,
                            pieces: output.general.summary.totalDamagedPieces
                        )
                    }
                    .padding(.vertical, 4)
                }
                
                // Exception Details
                let exceptions = output.general.shipments.filter { $0.exceptionType != "ok" }
                if !exceptions.isEmpty {
                    GroupBox("Exception Details") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(exceptions, id: \.proNumber) { shipment in
                                ExceptionDetailView(shipment: shipment)
                                if shipment.proNumber != exceptions.last?.proNumber {
                                    Divider()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                Text("No output available")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Helper Views

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
        .font(.system(size: 14))
    }
}

struct SummaryRow: View {
    let icon: String
    let color: Color
    let label: String
    let count: Int
    let pieces: Int
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
            
            Text(label)
                .fontWeight(.medium)
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(count) shipments")
                    .font(.system(size: 14))
                Text("\(pieces) pieces")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ExceptionDetailView: View {
    let shipment: Shipment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PRO: \(shipment.proNumber)")
                    .fontWeight(.bold)
                Spacer()
                Text(shipment.exceptionType.uppercased())
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(exceptionColor)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            
            Text(shipment.description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            HStack {
                Text("Expected: \(shipment.expectedPieces)")
                Text("•")
                Text("Actual: \(shipment.actualPieces)")
                Text("•")
                Text("Weight: \(shipment.weight) lbs")
            }
            .font(.system(size: 12))
            
            if !shipment.markupNotations.isEmpty {
                Text("Markups: \(shipment.markupNotations.joined(separator: ", "))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            if let notes = shipment.handwrittenNotes {
                Text("Notes: \(notes)")
                    .font(.system(size: 12))
                    .italic()
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var exceptionColor: Color {
        switch shipment.exceptionType {
        case "shortage":
            return .orange
        case "overage":
            return .blue
        case "damage":
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.onPick(url)
            }
        }
    }
}
import UIKit

// MARK: - UIKit View Controller Example

class ManifestExceptionViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Manifest Exception Processor"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let selectPDFButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Select PDF", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()
    
    private let processTypeSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Synchronous", "Asynchronous"])
        control.selectedSegmentIndex = 0
        return control
    }()
    
    private let processButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Process Document", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.isEnabled = false
        return button
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Ready"
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    private let resultsTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 8
        textView.contentInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return textView
    }()
    
    // MARK: - Properties
    
    private let processor = ManifestExceptionProcessor(
        baseURL: "https://docker.nacompanies.com:452",
        username: "aidoctest",
        password: "AiD0cTest2025!"
    )
    
    private var selectedPDFPath: String?
    private var isAuthenticated = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        authenticate()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add scroll view
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        [titleLabel, selectPDFButton, processTypeSegmentedControl, 
         processButton, statusLabel, activityIndicator, resultsTextView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Select PDF button
            selectPDFButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            selectPDFButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            selectPDFButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            selectPDFButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Processing type
            processTypeSegmentedControl.topAnchor.constraint(equalTo: selectPDFButton.bottomAnchor, constant: 20),
            processTypeSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            processTypeSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Process button
            processButton.topAnchor.constraint(equalTo: processTypeSegmentedControl.bottomAnchor, constant: 20),
            processButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            processButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            processButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Status label
            statusLabel.topAnchor.constraint(equalTo: processButton.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            
            // Results text view
            resultsTextView.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20),
            resultsTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            resultsTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            resultsTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),
            resultsTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // Add targets
        selectPDFButton.addTarget(self, action: #selector(selectPDFTapped), for: .touchUpInside)
        processButton.addTarget(self, action: #selector(processDocumentTapped), for: .touchUpInside)
    }
    
    // MARK: - Authentication
    
    private func authenticate() {
        Task {
            do {
                updateStatus("Authenticating...")
                showLoading(true)
                
                _ = try await processor.authenticate()
                isAuthenticated = true
                updateStatus("Authenticated. Ready to process.")
                
            } catch {
                updateStatus("Authentication failed: \(error.localizedDescription)")
                showAlert(title: "Authentication Error", message: error.localizedDescription)
            }
            showLoading(false)
        }
    }
    
    // MARK: - Actions
    
    @objc private func selectPDFTapped() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    @objc private func processDocumentTapped() {
        guard let pdfPath = selectedPDFPath else { return }
        
        if processTypeSegmentedControl.selectedSegmentIndex == 0 {
            processSynchronously(pdfPath: pdfPath)
        } else {
            processAsynchronously(pdfPath: pdfPath)
        }
    }
    
    // MARK: - Processing Methods
    
    private func processSynchronously(pdfPath: String) {
        Task {
            do {
                updateStatus("Processing document synchronously...")
                showLoading(true)
                processButton.isEnabled = false
                
                let result = try await processor.processSync(
                    pdfPath: pdfPath,
                    identifier: "IOS_\(Date().timeIntervalSince1970)"
                )
                
                displayResults(result)
                updateStatus("Processing complete")
                
            } catch {
                updateStatus("Processing failed: \(error.localizedDescription)")
                showAlert(title: "Processing Error", message: error.localizedDescription)
            }
            
            showLoading(false)
            processButton.isEnabled = true
        }
    }
    
    private func processAsynchronously(pdfPath: String) {
        Task {
            do {
                updateStatus("Submitting document for async processing...")
                showLoading(true)
                processButton.isEnabled = false
                
                let submitResult = try await processor.processAsync(
                    pdfPath: pdfPath,
                    identifier: "IOS_\(Date().timeIntervalSince1970)"
                )
                
                let batchId = submitResult.metadata.identifier
                updateStatus("Batch submitted: \(batchId). Polling for results...")
                
                let finalResult = try await processor.waitForCompletion(batchId: batchId)
                
                displayResults(finalResult)
                updateStatus("Processing complete")
                
            } catch {
                updateStatus("Processing failed: \(error.localizedDescription)")
                showAlert(title: "Processing Error", message: error.localizedDescription)
            }
            
            showLoading(false)
            processButton.isEnabled = true
        }
    }
    
    // MARK: - Display Results
    
    private func displayResults(_ result: BatchResponse) {
        guard let output = result.output else {
            resultsTextView.text = "No output available"
            return
        }
        
        var resultText = "PROCESSING RESULTS\n"
        resultText += "================\n\n"
        
        // Metadata
        resultText += "Batch ID: \(result.metadata.identifier)\n"
        resultText += "State: \(result.metadata.state)\n"
        resultText += "Result: \(result.metadata.result)\n\n"
        
        // Manifest Info
        let manifestInfo = output.general.manifestInfo
        resultText += "MANIFEST INFORMATION\n"
        resultText += "-------------------\n"
        resultText += "Trip Number: \(manifestInfo.tripNumber)\n"
        resultText += "Manifest Number: \(manifestInfo.manifestNumber)\n"
        resultText += "Trailer Number: \(manifestInfo.trailerNumber)\n"
        resultText += "Expected/Actual Shipments: \(manifestInfo.expectedShipments)/\(manifestInfo.actualShipments)\n"
        resultText += "Expected/Actual Units: \(manifestInfo.expectedHandlingUnits)/\(manifestInfo.actualHandlingUnits)\n\n"
        
        // Summary
        let summary = output.general.summary
        resultText += "EXCEPTION SUMMARY\n"
        resultText += "----------------\n"
        resultText += "Total Shortages: \(summary.totalShortages) (\(summary.totalShortagePieces) pieces)\n"
        resultText += "Total Overages: \(summary.totalOverages) (\(summary.totalOveragePieces) pieces)\n"
        resultText += "Total Damages: \(summary.totalDamages) (\(summary.totalDamagedPieces) pieces)\n"
        resultText += "Has OS&D Notation: \(summary.hasOSDNotation ? "Yes" : "No")\n\n"
        
        // Exception Details
        let exceptions = output.general.shipments.filter { $0.exceptionType != "ok" }
        if !exceptions.isEmpty {
            resultText += "EXCEPTION DETAILS\n"
            resultText += "----------------\n"
            
            for shipment in exceptions {
                resultText += "\nPRO: \(shipment.proNumber)\n"
                resultText += "Description: \(shipment.description)\n"
                resultText += "Exception Type: \(shipment.exceptionType.uppercased())\n"
                resultText += "Expected/Actual: \(shipment.expectedPieces)/\(shipment.actualPieces)\n"
                resultText += "Weight: \(shipment.weight) lbs\n"
                
                if !shipment.markupNotations.isEmpty {
                    resultText += "Markups: \(shipment.markupNotations.joined(separator: ", "))\n"
                }
                
                if let notes = shipment.handwrittenNotes {
                    resultText += "Notes: \(notes)\n"
                }
            }
        }
        
        resultsTextView.text = resultText
    }
    
    // MARK: - Helper Methods
    
    private func updateStatus(_ status: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = status
        }
    }
    
    private func showLoading(_ show: Bool) {
        DispatchQueue.main.async {
            if show {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - Document Picker Delegate

extension ManifestExceptionViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        // Copy to app's documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsPath.appendingPathComponent(url.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            selectedPDFPath = destinationURL.path
            processButton.isEnabled = isAuthenticated
            updateStatus("PDF selected: \(url.lastPathComponent)")
            
        } catch {
            showAlert(title: "File Error", message: "Failed to copy PDF: \(error.localizedDescription)")
        }
    }
}
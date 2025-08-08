# Manifest Exception Processor - Swift Implementation

A comprehensive Swift implementation for integrating with the AI Document Processor API to extract OS&D (Overage, Shortage & Damage) information from manifest exception PDFs.

## Features

- **Authentication**: JWT token-based authentication
- **Synchronous Processing**: Real-time document processing with immediate results
- **Asynchronous Processing**: Queue-based processing with polling for results
- **Full Data Extraction**: Extracts manifest info, shipment details, and exception summaries
- **UI Support**: Includes both UIKit and SwiftUI implementations
- **Error Handling**: Comprehensive error handling and status reporting

## Components

### 1. Core Processor (`ManifestExceptionProcessor.swift`)

The main class that handles:
- API authentication
- Document submission (sync/async)
- Status checking
- Result polling
- Health checks

### 2. UIKit Implementation (`ManifestExceptionUIKit.swift`)

Traditional UIKit-based view controller with:
- Document picker integration
- Processing mode selection
- Real-time status updates
- Results display

### 3. SwiftUI Implementation (`ManifestExceptionSwiftUI.swift`)

Modern SwiftUI implementation with:
- Reactive UI updates
- Document picker integration
- Clean, modern interface
- Comprehensive results view

## Usage

### Basic Integration

```swift
// Initialize processor
let processor = ManifestExceptionProcessor(
    baseURL: "https://docker.nacompanies.com:452",
    username: "aidoctest",
    password: "AiD0cTest2025!"
)

// Authenticate
let token = try await processor.authenticate()

// Process synchronously
let result = try await processor.processSync(
    pdfPath: "/path/to/manifest.pdf",
    identifier: "MANIFEST_001"
)

// Access results
if let output = result.output {
    print("Trip Number: \(output.general.manifestInfo.tripNumber)")
    print("Total Shortages: \(output.general.summary.totalShortages)")
}
```

### UIKit Integration

```swift
// In your view controller
let viewController = ManifestExceptionViewController()
navigationController?.pushViewController(viewController, animated: true)
```

### SwiftUI Integration

```swift
// In your SwiftUI app
struct ContentView: View {
    var body: some View {
        ManifestExceptionView()
    }
}
```

## Data Models

The implementation includes comprehensive data models for:

- **TokenResponse**: Authentication response
- **BatchRequest**: Document submission request
- **BatchResponse**: Processing results
- **ManifestInfo**: Manifest header information
- **Shipment**: Individual shipment details
- **Summary**: Exception statistics

## Error Handling

The processor includes typed errors for:
- Authentication failures
- Network errors
- Processing timeouts
- API errors
- Invalid responses

## Security Notes

- The current implementation accepts self-signed certificates for the test environment
- For production use, remove the SSL pinning delegate and use proper certificate validation
- Never hardcode credentials in production code

## Requirements

- iOS 13.0+ / macOS 10.15+
- Swift 5.0+
- Network access to the API endpoints

## Test Environment

- Base URL: `https://docker.nacompanies.com:452`
- API Version: `/api/v1`
- Test Credentials are provided in the guide

## Processing Flow

1. **Authentication**: Obtain JWT token
2. **Document Preparation**: Convert PDF to base64
3. **Submission**: Send document with metadata
4. **Processing**: Wait for results (sync) or poll status (async)
5. **Results**: Parse and display extracted data
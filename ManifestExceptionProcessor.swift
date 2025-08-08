import Foundation

// MARK: - Models

struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
}

struct BatchRequest: Codable {
    let batchIdentifier: String?
    let batchType: String
    let documentType: String
    let processingType: String
    let executionType: String
    let identifier: String
    let fileType: String
    let document: String
}

struct BatchMetadata: Codable {
    let identifier: String
    let originalFilename: String?
    let state: String
    let result: String
    let createdAt: String
    let stateUpdatedAt: String?
    let documentCount: Int
    let processingMode: String
    let batchType: String
}

struct ManifestInfo: Codable {
    let manifestNumber: String
    let tripNumber: String
    let trailerNumber: String
    let expectedShipments: Int
    let expectedHandlingUnits: Int
    let actualShipments: Int
    let actualHandlingUnits: Int
}

struct ExceptionDetails: Codable {
    let shortagePieces: Int?
    let overagePieces: Int?
    let damagedPieces: Int?
}

struct Shipment: Codable {
    let proNumber: String
    let expectedPieces: Int
    let actualPieces: Int
    let weight: Int
    let description: String
    let exceptionType: String
    let exceptionDetails: ExceptionDetails?
    let markupNotations: [String]
    let handwrittenNotes: String?
    let highlightColor: String
}

struct Summary: Codable {
    let totalOverages: Int
    let totalShortages: Int
    let totalDamages: Int
    let totalOveragePieces: Int
    let totalShortagePieces: Int
    let totalDamagedPieces: Int
    let hasOSDNotation: Bool
}

struct GeneralOutput: Codable {
    let manifestInfo: ManifestInfo
    let shipments: [Shipment]
    let summary: Summary
}

struct OutputMetadata: Codable {
    let documentType: String
    let state: String
    let result: String
    let processedAt: String
}

struct Output: Codable {
    let metadata: OutputMetadata
    let general: GeneralOutput
}

struct BatchResponse: Codable {
    let metadata: BatchMetadata
    let output: Output?
}

struct ErrorResponse: Codable {
    let detail: String
}

// MARK: - ManifestExceptionProcessor

class ManifestExceptionProcessor {
    private let baseURL: String
    private let username: String
    private let password: String
    private var token: String?
    private let session: URLSession
    
    enum ProcessingError: Error {
        case authenticationFailed
        case invalidResponse
        case processingTimeout
        case apiError(String)
        case networkError(Error)
        case invalidPDF
    }
    
    init(baseURL: String, username: String, password: String) {
        self.baseURL = baseURL
        self.username = username
        self.password = password
        
        // Configure session to accept self-signed certificates for test environment
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 300
        
        self.session = URLSession(configuration: configuration, delegate: SSLPinningDelegate(), delegateQueue: nil)
    }
    
    // MARK: - Authentication
    
    func authenticate() async throws -> String {
        let url = URL(string: "\(baseURL)/api/v1/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "username=\(username)&password=\(password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? password)"
        request.httpBody = bodyString.data(using: .utf8)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ProcessingError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                self.token = tokenResponse.accessToken
                return tokenResponse.accessToken
            } else {
                throw ProcessingError.authenticationFailed
            }
        } catch {
            throw ProcessingError.networkError(error)
        }
    }
    
    // MARK: - Synchronous Processing
    
    func processSync(pdfPath: String, identifier: String) async throws -> BatchResponse {
        guard let token = self.token else {
            throw ProcessingError.authenticationFailed
        }
        
        let pdfData = try Data(contentsOf: URL(fileURLWithPath: pdfPath))
        let base64String = pdfData.base64EncodedString()
        
        let batchRequest = BatchRequest(
            batchIdentifier: nil,
            batchType: "manifestExceptions",
            documentType: "manifestException",
            processingType: "single_pass",
            executionType: "sync",
            identifier: identifier,
            fileType: "pdf",
            document: base64String
        )
        
        let url = URL(string: "\(baseURL)/api/v1/batches")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(batchRequest)
        request.timeoutInterval = 120
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ProcessingError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                return try JSONDecoder().decode(BatchResponse.self, from: data)
            } else {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw ProcessingError.apiError(errorResponse.detail)
                }
                throw ProcessingError.apiError("HTTP \(httpResponse.statusCode)")
            }
        } catch {
            throw ProcessingError.networkError(error)
        }
    }
    
    // MARK: - Asynchronous Processing
    
    func processAsync(pdfPath: String, identifier: String, batchIdentifier: String? = nil) async throws -> BatchResponse {
        guard let token = self.token else {
            throw ProcessingError.authenticationFailed
        }
        
        let pdfData = try Data(contentsOf: URL(fileURLWithPath: pdfPath))
        let base64String = pdfData.base64EncodedString()
        
        let batchRequest = BatchRequest(
            batchIdentifier: batchIdentifier ?? UUID().uuidString.lowercased(),
            batchType: "manifestExceptions",
            documentType: "manifestException",
            processingType: "single_pass",
            executionType: "async",
            identifier: identifier,
            fileType: "pdf",
            document: base64String
        )
        
        let url = URL(string: "\(baseURL)/api/v1/batches")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(batchRequest)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ProcessingError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                return try JSONDecoder().decode(BatchResponse.self, from: data)
            } else {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw ProcessingError.apiError(errorResponse.detail)
                }
                throw ProcessingError.apiError("HTTP \(httpResponse.statusCode)")
            }
        } catch {
            throw ProcessingError.networkError(error)
        }
    }
    
    // MARK: - Status Checking
    
    func getBatchStatus(batchId: String) async throws -> BatchResponse {
        guard let token = self.token else {
            throw ProcessingError.authenticationFailed
        }
        
        let url = URL(string: "\(baseURL)/api/v1/batches/\(batchId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ProcessingError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                return try JSONDecoder().decode(BatchResponse.self, from: data)
            } else {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw ProcessingError.apiError(errorResponse.detail)
                }
                throw ProcessingError.apiError("HTTP \(httpResponse.statusCode)")
            }
        } catch {
            throw ProcessingError.networkError(error)
        }
    }
    
    // MARK: - Wait for Completion
    
    func waitForCompletion(batchId: String, timeout: TimeInterval = 300) async throws -> BatchResponse {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            let result = try await getBatchStatus(batchId: batchId)
            
            if result.metadata.state == "finalized" || result.metadata.state == "failed" {
                return result
            }
            
            // Wait 10 seconds before next poll
            try await Task.sleep(nanoseconds: 10_000_000_000)
        }
        
        throw ProcessingError.processingTimeout
    }
    
    // MARK: - Health Check
    
    func healthCheck() async throws -> Bool {
        let url = URL(string: "\(baseURL)/api/v1/health")!
        let request = URLRequest(url: url)
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            
            return httpResponse.statusCode == 200
        } catch {
            return false
        }
    }
}

// MARK: - SSL Pinning Delegate (for test environment only)

class SSLPinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // WARNING: This accepts self-signed certificates. Use only for test environment!
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                return
            }
        }
        completionHandler(.performDefaultHandling, nil)
    }
}

// MARK: - Usage Example

/*
// Example usage:

let processor = ManifestExceptionProcessor(
    baseURL: "https://docker.nacompanies.com:452",
    username: "aidoctest",
    password: "AiD0cTest2025!"
)

// Authenticate
Task {
    do {
        // 1. Authenticate
        let token = try await processor.authenticate()
        print("Authenticated successfully")
        
        // 2. Synchronous processing
        let syncResult = try await processor.processSync(
            pdfPath: "/path/to/manifest_exception.pdf",
            identifier: "EXCEPTION_001"
        )
        
        if let output = syncResult.output {
            print("Manifest Number: \(output.general.manifestInfo.manifestNumber)")
            print("Trip Number: \(output.general.manifestInfo.tripNumber)")
            print("Total Shortages: \(output.general.summary.totalShortages)")
            print("Total Shortage Pieces: \(output.general.summary.totalShortagePieces)")
            
            for shipment in output.general.shipments {
                if shipment.exceptionType != "ok" {
                    print("\nPRO: \(shipment.proNumber)")
                    print("Exception: \(shipment.exceptionType)")
                    print("Expected: \(shipment.expectedPieces), Actual: \(shipment.actualPieces)")
                }
            }
        }
        
        // 3. Asynchronous processing
        let asyncResult = try await processor.processAsync(
            pdfPath: "/path/to/manifest_exception.pdf",
            identifier: "EXCEPTION_002"
        )
        
        let batchId = asyncResult.metadata.identifier
        print("Async batch submitted: \(batchId)")
        
        // 4. Wait for completion
        let finalResult = try await processor.waitForCompletion(batchId: batchId)
        print("Processing complete: \(finalResult.metadata.state)")
        
    } catch ManifestExceptionProcessor.ProcessingError.authenticationFailed {
        print("Authentication failed")
    } catch ManifestExceptionProcessor.ProcessingError.processingTimeout {
        print("Processing timeout")
    } catch ManifestExceptionProcessor.ProcessingError.apiError(let message) {
        print("API Error: \(message)")
    } catch {
        print("Error: \(error)")
    }
}
*/
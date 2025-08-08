import Foundation

// Command Line Interface for Manifest Exception Processor
await runManifestProcessor()

func runManifestProcessor() async {
        print("🚀 Manifest Exception Processor - Command Line Interface")
        print(String(repeating: "=", count: 60))
        
        let processor = ManifestExceptionProcessor(
            baseURL: "https://docker.nacompanies.com:452",
            username: "aidoctest",
            password: "AiD0cTest2025!"
        )
        
        do {
            // Test authentication
            print("🔐 Authenticating with API...")
            let token = try await processor.authenticate()
            print("✅ Authentication successful!")
            print("📋 Token: \(String(token.prefix(20)))...")
            
            // Health check
            print("\n🏥 Checking API health...")
            let isHealthy = try await processor.healthCheck()
            print(isHealthy ? "✅ API is healthy" : "❌ API health check failed")
            
            // Demo mode - show what the processor can do
            print("\n📖 Available Operations:")
            print("• Synchronous PDF Processing")
            print("• Asynchronous PDF Processing") 
            print("• Batch Status Monitoring")
            print("• Health Checks")
            
            print("\n📁 To process a PDF, add the file path as an argument:")
            print("swift run manifest-processor /path/to/your/manifest.pdf")
            
            // Check for PDF argument
            let arguments = CommandLine.arguments
            if arguments.count > 1 {
                let pdfPath = arguments[1]
                await processPDF(processor: processor, pdfPath: pdfPath)
            }
            
        } catch {
            print("❌ Error: \(error)")
            exit(1)
        }
}

func processPDF(processor: ManifestExceptionProcessor, pdfPath: String) async {
        print("\n📄 Processing PDF: \(pdfPath)")
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: pdfPath) else {
            print("❌ File not found: \(pdfPath)")
            return
        }
        
        do {
            print("⏳ Processing document synchronously...")
            let result = try await processor.processSync(
                pdfPath: pdfPath,
                identifier: "CLI_\(Date().timeIntervalSince1970)"
            )
            
            print("✅ Processing complete!")
            displayResults(result)
            
        } catch {
            print("❌ Processing failed: \(error)")
        }
}

func displayResults(_ result: BatchResponse) {
        guard let output = result.output else {
            print("⚠️  No output available")
            return
        }
        
        print("\n📊 PROCESSING RESULTS")
        print(String(repeating: "-", count: 40))
        
        // Manifest Info
        let manifest = output.general.manifestInfo
        print("🚛 Trip Number: \(manifest.tripNumber)")
        print("📋 Manifest: \(manifest.manifestNumber)")
        print("🚚 Trailer: \(manifest.trailerNumber)")
        print("📦 Shipments: \(manifest.expectedShipments) expected / \(manifest.actualShipments) actual")
        print("📊 Units: \(manifest.expectedHandlingUnits) expected / \(manifest.actualHandlingUnits) actual")
        
        // Summary
        let summary = output.general.summary
        print("\n⚠️  EXCEPTIONS SUMMARY")
        print("🔍 Shortages: \(summary.totalShortages) (\(summary.totalShortagePieces) pieces)")
        print("➕ Overages: \(summary.totalOverages) (\(summary.totalOveragePieces) pieces)")  
        print("💔 Damages: \(summary.totalDamages) (\(summary.totalDamagedPieces) pieces)")
        print("📝 Has OS&D: \(summary.hasOSDNotation ? "Yes" : "No")")
        
        // Exception Details
        let exceptions = output.general.shipments.filter { $0.exceptionType != "ok" }
        if !exceptions.isEmpty {
            print("\n📋 EXCEPTION DETAILS")
            for (index, shipment) in exceptions.enumerated() {
                print("\n\(index + 1). PRO: \(shipment.proNumber)")
                print("   Type: \(shipment.exceptionType.uppercased())")
                print("   Expected/Actual: \(shipment.expectedPieces)/\(shipment.actualPieces)")
                print("   Description: \(shipment.description)")
                if let notes = shipment.handwrittenNotes {
                    print("   Notes: \(notes)")
                }
            }
        }
}
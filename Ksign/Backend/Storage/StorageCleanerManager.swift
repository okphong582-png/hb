//
//  StorageCleanerManager.swift
//  HighSign
//
//  Created for HighSign.
//

import Foundation
import SwiftUI
import CoreData
import Nuke

final class StorageCleanerManager: ObservableObject {
    static let shared = StorageCleanerManager()
    
    @AppStorage("HighSign.autoCleanOnInstall") var autoCleanOnInstall: Bool = true
    @Published var totalDiskUsage: String = "0 MB"
    @Published var isCleaning: Bool = false
    
    private let fileManager = FileManager.default
    
    init() {
        refreshStorageInfo()
    }
    
    /// Calculate total size of directory in bytes
    func sizeOfDirectory(at url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]) else {
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
               resourceValues.isRegularFile == true,
               let size = resourceValues.fileSize {
                total += Int64(size)
            }
        }
        return total
    }
    
    /// Returns total reclaimable size
    func calculateReclaimableBytes() -> Int64 {
        var total: Int64 = 0
        
        // Work / Temp directory
        total += sizeOfDirectory(at: fileManager.temporaryDirectory)
        
        // App Archives
        total += sizeOfDirectory(at: fileManager.archives)
        
        // App Signed
        total += sizeOfDirectory(at: fileManager.signed)
        
        // App Unsigned
        total += sizeOfDirectory(at: fileManager.unsigned)
        
        // Network Cache
        total += Int64(URLCache.shared.currentDiskUsage)
        
        // Image Cache
        if let nukeCache = ImagePipeline.shared.configuration.dataCache as? DataCache {
            total += Int64(nukeCache.totalSize)
        }
        
        return total
    }
    
    func refreshStorageInfo() {
        DispatchQueue.global(qos: .userInitiated).async {
            let bytes = self.calculateReclaimableBytes()
            let formatted = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
            DispatchQueue.main.async {
                self.totalDiskUsage = formatted
            }
        }
    }
    
    /// Quick clean: cleans temporary work files, build artifacts, network and image caches.
    /// Does not delete user's imported certificates.
    @discardableResult
    func performQuickClean() -> String {
        let beforeBytes = calculateReclaimableBytes()
        
        // 1. Temporary directory files
        let tmp = fileManager.temporaryDirectory
        if let files = try? fileManager.contentsOfDirectory(atPath: tmp.path) {
            for file in files {
                try? fileManager.removeItem(at: tmp.appendingPathComponent(file))
            }
        }
        
        // 2. Network & Image Caches
        URLCache.shared.removeAllCachedResponses()
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        if let dataCache = ImagePipeline.shared.configuration.dataCache as? DataCache {
            dataCache.removeAll()
        }
        if let imageCache = ImagePipeline.shared.configuration.imageCache as? Nuke.ImageCache {
            imageCache.removeAll()
        }
        
        let afterBytes = calculateReclaimableBytes()
        let freedBytes = max(0, beforeBytes - afterBytes)
        refreshStorageInfo()
        
        return ByteCountFormatter.string(fromByteCount: freedBytes, countStyle: .file)
    }
    
    /// Deep clean: removes all cached payloads, archives, unsigned apps, signed apps, and temp files.
    @discardableResult
    func performDeepClean() -> String {
        let beforeBytes = calculateReclaimableBytes()
        
        // 1. Quick clean first
        performQuickClean()
        
        // 2. Clear Archives
        try? fileManager.removeFileIfNeeded(at: fileManager.archives)
        try? fileManager.createDirectoryIfNeeded(at: fileManager.archives)
        
        // 3. Clear Signed Apps
        Storage.shared.clearContext(request: Signed.fetchRequest())
        try? fileManager.removeFileIfNeeded(at: fileManager.signed)
        try? fileManager.createDirectoryIfNeeded(at: fileManager.signed)
        
        // 4. Clear Unsigned Apps
        Storage.shared.clearContext(request: Imported.fetchRequest())
        try? fileManager.removeFileIfNeeded(at: fileManager.unsigned)
        try? fileManager.createDirectoryIfNeeded(at: fileManager.unsigned)
        
        let afterBytes = calculateReclaimableBytes()
        let freedBytes = max(0, beforeBytes - afterBytes)
        refreshStorageInfo()
        
        return ByteCountFormatter.string(fromByteCount: freedBytes, countStyle: .file)
    }
    
    /// Auto clean triggered after install if enabled
    func autoCleanAfterInstallation() {
        guard autoCleanOnInstall else { return }
        DispatchQueue.global(qos: .background).async {
            self.performQuickClean()
        }
    }
}

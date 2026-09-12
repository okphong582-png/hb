//
//  BackgroundTaskManager.swift
//  HighSign
//

import Foundation
import CryptoKit

class BackgroundTaskManager: ObservableObject {
    static let shared = BackgroundTaskManager()
    
    func startTask(for downloadId: String, filename: String) {}
    func updateProgress(for downloadId: String, progress: Double) {}
    func stopTask(for downloadId: String, success: Bool) {}
}

extension String {
    var md5: String {
        Insecure.MD5.hash(data: Data(self.utf8)).map { String(format: "%02hhx", $0) }.joined()
    }
}

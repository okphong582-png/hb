//
//  ZipCompression+cases.swift
//  Feather
//
//  Created by samara on 22.04.2025.
//

import Zip

extension ZipCompression {
	static var allCases: [ZipCompression] {
		return [.NoCompression, .BestSpeed, .DefaultCompression, .BestCompression]
	}
	
	var label: String {
		switch self {
		case .NoCompression: return "Không nén (Siêu tốc 1s)"
		case .BestSpeed: return "Ký siêu nhanh (Khuyên dùng)"
		case .DefaultCompression: return "Mặc định"
		case .BestCompression: return "Nén tối đa (Chậm)"
		}
	}
}

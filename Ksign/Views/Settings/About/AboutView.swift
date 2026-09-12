//
//  AboutView.swift
//  HighSign
//
//  Created for HighSign.
//

import SwiftUI
import NimbleViews

// MARK: - View
struct AboutView: View {
	var body: some View {
		NBList(.localized("About")) {
			NBSection("HighSign") {
				Text("HighSign là công cụ ký và quản lý ứng dụng iOS tối ưu với tốc độ siêu nhanh và khả năng dọn dẹp bộ nhớ chuyên sâu.")
					.foregroundStyle(.secondary)
					.padding(.vertical, 4)
			}
		}
	}
}

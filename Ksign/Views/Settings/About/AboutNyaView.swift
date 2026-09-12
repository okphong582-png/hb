//
//  AboutNyaView.swift
//  HighSign
//
//  Created for HighSign.
//

import SwiftUI
import NimbleViews
import NimbleJSON

// MARK: - View
struct AboutNyaView: View {
	var body: some View {
		NBList(.localized("About")) {
            Section {
                VStack(spacing: 12) {
                    if let iconName = Bundle.main.iconFileName, let icon = UIImage(named: iconName) {
                        Image(uiImage: icon)
                            .appIconStyle(size: 80)
                            .shadow(color: .accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    
                    Text("HighSign")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.accent)
                    
                    Text("Phiên bản 1.6 • HighSpeed Edition")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    Text("Trình ký ứng dụng iOS siêu tốc & Tối ưu hoá bộ nhớ")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(EmptyView())
			
			NBSection("Ưu điểm nổi bật") {
				_featureRow(
					title: "Ký siêu tốc (Ultra-Fast)",
					subtitle: "Tốc độ ký và đóng gói IPA nhanh gấp 10-20 lần, chỉ mất 1-2 giây.",
					icon: "bolt.fill",
					color: .yellow
				)
				
				_featureRow(
					title: "Server Localhost 100%",
					subtitle: "Mặc định sử dụng server nội bộ trên máy, hoàn toàn không cần server bên ngoài.",
					icon: "server.rack",
					color: .cyan
				)
				
				_featureRow(
					title: "Dọn dẹp & Tối ưu máy",
					subtitle: "Tự động xóa all file tạm và dữ liệu thừa để giải phóng dung lượng máy tối đa.",
					icon: "sparkles",
					color: .green
				)
			}
            
            NBSection("Thông tin ứng dụng") {
                HStack {
                    Text("Bundle ID")
                    Spacer()
                    Text("com.highsign.com")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
                HStack {
                    Text("Bản quyền")
                    Spacer()
                    Text("HighSign Team")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
            }
		}
	}
    
    @ViewBuilder
    private func _featureRow(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

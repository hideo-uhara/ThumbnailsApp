//
// ThumbnailGenerator.swift
//

import QuickLookThumbnailing
import UIKit

//
// thumbnailの生成をシリアルに行う
//
actor ThumbnailGenerator: NSObject {
	
	func thumbnail(url: URL, size: CGSize = CGSize(width: 64.0, height: 64.0), scale: CGFloat) async -> UIImage? {
		
		if FileManager.default.fileExists(atPath: url.fullPath()) {
			do {
				let request: QLThumbnailGenerator.Request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: scale, representationTypes: .thumbnail)
				let thumbnailRepresentation = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
				
				return thumbnailRepresentation.uiImage
				
			} catch let error as NSError {
				NSLog("Error:%@[file=%@, line=%d]", error.localizedDescription, URL(withPath: #file).lastPathComponent, #line)
			}
		}
		
		return nil
	}
}


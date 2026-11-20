//
// ThumbnailGenerator.swift
//

import QuickLookThumbnailing
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

//
// thumbnailの生成を行う
//
/*
class ThumbnailGenerator: NSObject {

	@concurrent func thumbnail(url: URL, size: CGSize = CGSize(width: 64.0, height: 64.0), scale: CGFloat) async throws -> Image? {
		
		//try? await Task.sleep(nanoseconds: UInt64(1.0 * 1_000_000_000))
		
		try Task.checkCancellation()
		
		if FileManager.default.fileExists(atPath: url.fullPath()) {
			do {
				let request: QLThumbnailGenerator.Request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: scale, representationTypes: .thumbnail)
				let thumbnailRepresentation = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
				
				#if os(iOS)
				return Image(uiImage: thumbnailRepresentation.uiImage)
				#elseif os(macOS)
				return Image(nsImage: thumbnailRepresentation.nsImage)
				#endif
				
			} catch let error as NSError {
				NSLog("Error:%@[file=%@, line=%d]", error.localizedDescription, URL(withPath: #file).lastPathComponent, #line)
			}
		}
		
		return nil
	}
	
}
*/

//
// thumbnailの生成をシリアルに行う
//
actor ThumbnailGenerator: NSObject {
	let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
	
	func thumbnail(url: URL, size: CGSize = CGSize(width: 64.0, height: 64.0), scale: CGFloat) throws -> Image? {
		print("Called thumbnail \(url.lastPathComponent)")
		
		try Task.checkCancellation()
		
		nonisolated(unsafe) var image: Image! = nil
		
		if FileManager.default.fileExists(atPath: url.fullPath()) {
			let request: QLThumbnailGenerator.Request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: scale, representationTypes: .thumbnail)
			
			QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { (representation, error) in
				print("Generated thumbnail \(url.lastPathComponent)")
				
				//Thread.sleep(forTimeInterval: 1.0)
				
				if let error = error {
					NSLog("Error:%@[file=%@, line=%d]", error.localizedDescription, URL(withPath: #file).lastPathComponent, #line)
				}
				
				#if os(iOS)
				if let uiImage: UIImage = representation?.uiImage {
					image = Image(uiImage: uiImage)
				}
				#elseif os(macOS)
				if let nsImage: NSImage = representation?.nsImage {
					image = Image(nsImage: nsImage)
				}
				#endif
				
				self.semaphore.signal()
			}
			
			self.semaphore.wait()
		}
		
		return image
	}
}


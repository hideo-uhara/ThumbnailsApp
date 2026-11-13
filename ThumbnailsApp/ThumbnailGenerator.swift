//
// ThumbnailGenerator.swift
//

import QuickLookThumbnailing
import UIKit

//
// thumbnailの生成をシリアルに行う
//
actor ThumbnailGenerator: NSObject {
	let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
	
	func thumbnail(url: URL, size: CGSize = CGSize(width: 64.0, height: 64.0), scale: CGFloat) throws -> UIImage? {
		print("Called thumbnail \(url.lastPathComponent)")
		
		try Task.checkCancellation()
		
		nonisolated(unsafe) var image: UIImage! = nil
		
		if FileManager.default.fileExists(atPath: url.fullPath()) {
			let request: QLThumbnailGenerator.Request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: scale, representationTypes: .thumbnail)
			
			QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { (representation, error) in
				print("Generated thumbnail \(url.lastPathComponent)")
				
				//Thread.sleep(forTimeInterval: 1.0)
				
				if let error = error {
					NSLog("Error:%@[file=%@, line=%d]", error.localizedDescription, URL(withPath: #file).lastPathComponent, #line)
				}
				
				image = representation?.uiImage
				self.semaphore.signal()
			}
			
			self.semaphore.wait()
		}
		
		return image
	}
}


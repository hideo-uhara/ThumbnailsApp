//
// Extensions.swift
//

import Foundation

nonisolated extension URL {
	
	init(withPath: String) {
		if #available(iOS 16.0, *) {
			self.init(filePath: withPath)
		} else {
			self.init(fileURLWithPath: withPath)
		}
	}
	
	func fullPath() -> String {
		if #available(iOS 16.0, *) {
			return self.path(percentEncoded: false)
		} else {
			return self.path
		}
	}
	
}


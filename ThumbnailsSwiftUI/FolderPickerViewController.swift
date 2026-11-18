//
// FolderPickerViewController.swift
//

import UniformTypeIdentifiers
import UIKit
import SwiftUI

struct FolderPickerViewController: UIViewControllerRepresentable {
	var didPick: ([URL]) -> Void
	
	func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
		let pickerViewController: UIDocumentPickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
		
		pickerViewController.delegate = context.coordinator
		
		return pickerViewController
	}
	
	func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(parent: self)
	}
	
	class Coordinator: NSObject, UIDocumentPickerDelegate {
		var parent: FolderPickerViewController! = nil
		
		init(parent: FolderPickerViewController) {
			self.parent = parent
		}
		
		func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
			self.parent.didPick(urls)
		}
		
	}
	
}

//
// ViewController.swift
//

import UniformTypeIdentifiers
import UIKit

class FileItem {
	let url: URL
	var thumbnail: UIImage! = nil
	
	init(url: URL) {
		self.url = url
	}
}

class TableViewCell: UITableViewCell {
	var fileItem: FileItem! = nil
	var thumbnailTask: Task<Void, Never>? = nil
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		self.fileItem = nil
		self.thumbnailTask?.cancel() // 以前のタスクはキャンセル
		self.thumbnailTask = nil
		
		let activityIndicatorView: UIActivityIndicatorView = self.viewWithTag(1) as! UIActivityIndicatorView
		let imageView: UIImageView = self.viewWithTag(2) as! UIImageView
		let fileNameLabel: UILabel = self.viewWithTag(3) as! UILabel
		
		activityIndicatorView.stopAnimating()
		imageView.image = nil
		fileNameLabel.text = ""
	}
}

class ViewController: UIViewController {
	let thumbnailGenerator: ThumbnailGenerator = ThumbnailGenerator()
	var fileItems: [FileItem] = []
	
	@IBOutlet var folderLabel: UILabel!
	@IBOutlet var folderButton: UIButton!
	@IBOutlet var tableView: UITableView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let navigationBarAppearance: UINavigationBarAppearance = UINavigationBarAppearance()
		
		navigationBarAppearance.configureWithTransparentBackground()
		self.navigationController?.navigationBar.standardAppearance = navigationBarAppearance
		self.navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance
		self.navigationController?.navigationBar.compactAppearance = navigationBarAppearance
		
		self.navigationController?.setNavigationBarHidden(false, animated: true)
		
		self.folderLabel.text = String(localized: "Folder: Not Set")
		
		if #available(iOS 26.0, *) {
			self.folderButton.configuration = .glass()
			self.folderButton.configuration?.buttonSize = .medium
			self.folderButton.setImage(UIImage(systemName: "folder")?.withRenderingMode(.alwaysTemplate), for: .normal)
		}
	}

	@IBAction func folderButtonAction(_ sender: Any) {
		let pickerViewController: UIDocumentPickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
		
		pickerViewController.delegate = self
		
		self.present(pickerViewController, animated: true, completion: nil)
	}
	
}

extension ViewController: UIDocumentPickerDelegate {
	
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		
		if let url = urls.first {
			self.folderLabel.text = String(localized: "Folder:") + FileManager.default.displayName(atPath: url.fullPath())
			
			if let enumerator: FileManager.DirectoryEnumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) {
				
				self.fileItems = []
				
				for case let url as URL in enumerator {
					self.fileItems.append(FileItem(url: url))
				}
				
				self.tableView.reloadData()
			}
			
		}
	}
	
}

extension ViewController: UITableViewDataSource {

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.fileItems.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let fileItem: FileItem = self.fileItems[indexPath.row]
		let tableViewcell: TableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell
		let activityIndicatorView: UIActivityIndicatorView = tableViewcell.viewWithTag(1) as! UIActivityIndicatorView
		let imageView: UIImageView = tableViewcell.viewWithTag(2) as! UIImageView
		let fileNameLabel: UILabel = tableViewcell.viewWithTag(3) as! UILabel
		
		tableViewcell.fileItem = fileItem
		
		imageView.image = fileItem.thumbnail
		fileNameLabel.text = FileManager.default.displayName(atPath: fileItem.url.fullPath())
		
		if fileItem.thumbnail == nil {
			activityIndicatorView.startAnimating()
			
			tableViewcell.thumbnailTask?.cancel()
			tableViewcell.thumbnailTask  = Task(priority: .utility) {
				do {
					let scale: CGFloat = self.view?.window?.windowScene?.screen.scale ?? UIScreen.main.scale
					
					fileItem.thumbnail = try await self.thumbnailGenerator.thumbnail(url: fileItem.url, scale: scale) ?? UIImage(systemName: "xmark.circle")
					
					// imageは非同期で作成されるので、作成された時点でcellのfileItemが同じかチェック
					if tableViewcell.fileItem === fileItem {
						imageView.image = fileItem.thumbnail
						activityIndicatorView.stopAnimating()
					} else {
						// 違う場合は、cellは再利用されている(prepareForReuseが呼ばれている)
					}
				} catch {
					print(error.localizedDescription + " \(fileItem.url.lastPathComponent)")
				}
			}
		}
		
		return tableViewcell
	}
}

extension ViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 72.0
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
	}
}


//
// Thumbnails.swift
//

import UniformTypeIdentifiers
import SwiftUI

#if DEBUG
//var borderWith: CGFloat = 1.0
var borderWith: CGFloat = 0.0
#else
var borderWith: CGFloat = 0.0
#endif

struct GlassEffectWhenPossible: ViewModifier {
	func body(content: Content) -> some View {
		if #available(iOS 26, macOS 26, *) {
			content
				.buttonStyle(.glass)
				.buttonBorderShape(.circle)
		} else {
			content
		}
	}
}

extension View {
	func glassEffectWhenPossible() -> some View {
		modifier(GlassEffectWhenPossible())
	}
}

@Observable class FileItem: Identifiable {
	let id: UUID = UUID()
	let url: URL
	var thumbnail: Image! = nil
	
	init(url: URL) {
		self.url = url
	}
}

struct ThumbnailsView: View {
	var body: some View {
		NavigationStack {
			ThumbnailsContentView()
				.border(Color.gray, width: borderWith)
				.navigationTitle(Text("Thumbnails"))
				#if os(iOS)
				.navigationBarTitleDisplayMode(.inline)
				#endif
				.safeAreaPadding(.vertical)
		}
	}
}

struct ThumbnailsContentView: View {
	let thumbnailGenerator: ThumbnailGenerator = ThumbnailGenerator()
	#if os(iOS)
	let allowedContentTypes: [UTType] = [.folder]
	#elseif os(macOS)
	let allowedContentTypes: [UTType] = [.directory]
	#endif
	
	@Environment(\.displayScale) var displayScale
	@State private var selectedId: UUID?
	@State private var folderUrl: URL! = nil
	@State private var isPresented: Bool = false
	@State private var fileItems: [FileItem] = [
		//FileItem(url: URL(fileURLWithPath: "a.txt")),
		//FileItem(url: URL(fileURLWithPath: "b.txt")),

	]
	@State var isStartAccessingSecurityScopedResource: Bool = false
	@State var url: URL! = nil {
		didSet {
			if self.isStartAccessingSecurityScopedResource {
				oldValue.stopAccessingSecurityScopedResource()
			}
			
			self.isStartAccessingSecurityScopedResource = url.startAccessingSecurityScopedResource()
		}
	}
	
	var body: some View {
		VStack {
			HStack {
				Group {
					if self.folderUrl != nil {
						Text("Folder: " + FileManager.default.displayName(atPath: folderUrl.fullPath()))
					} else {
						Text("Folder: Not Set")
					}
				}
				.border(Color.gray, width: borderWith)
				.lineLimit(1)
				
				Spacer()
				
				Button(action: {
					self.isPresented.toggle()
				}) {
					Image(systemName: "folder")
						.font(.system(size: 22))
				}
				.border(Color.gray, width: borderWith)
				//.padding(10.0)
				.glassEffectWhenPossible()
				.controlSize(.regular)
				.fileImporter(isPresented: self.$isPresented, allowedContentTypes: self.allowedContentTypes, allowsMultipleSelection: false) { result in
					switch result {
					case .success(let urls):
						if let url: URL = urls.first {
							self.url = url
							self.folderUrl = url
							
							if let enumerator: FileManager.DirectoryEnumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) {
								
								self.fileItems = []
								
								for case let url as URL in enumerator {
									self.fileItems.append(FileItem(url: url))
								}
							}
						}
					case .failure(let error):
						print(error.localizedDescription)
					}
				}
			}
			.border(Color.gray, width: borderWith)
			.padding([.top, .bottom], 10.0)
			.padding([.leading, .trailing], 20.0)
			
			List(selection: $selectedId) {
				ForEach(self.fileItems) { fileItem in
					HStack {
						Group {
							if fileItem.thumbnail != nil {
								fileItem.thumbnail
									.resizable()
									.scaledToFit()
									.frame(width: 60.0, height: 60.0)
							} else {
								ProgressView()
									.frame(width: 60.0, height: 60.0)
									.task {
										do {
											fileItem.thumbnail = try await self.thumbnailGenerator.thumbnail(url: fileItem.url, scale: self.displayScale) ?? Image(systemName: "xmark.circle")
											
										} catch {
											print(error.localizedDescription + " \(fileItem.url.lastPathComponent)")
										}
									}
							}
						}
						.border(Color.gray, width: borderWith)
						
						Text(FileManager.default.displayName(atPath: fileItem.url.fullPath()))
							.border(Color.gray, width: borderWith)
							.lineLimit(1)
						
					}
					.border(Color.gray, width: borderWith)
					.listRowInsets(EdgeInsets())
					.padding([.top, .bottom], 5.0)
				}
				.border(Color.gray, width: borderWith)
				.padding([.leading, .trailing], 10.0)
			}
			.border(Color.gray, width: borderWith)
			.listStyle(.plain)
		}
	}
}

#Preview {
	ThumbnailsView()
}

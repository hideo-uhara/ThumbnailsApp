//
// SplashViewController.swift
//

// LaunchScreenでテキストのローカライズは不可なので、こちらでアプリ名を表示(LaunchScreenは空)
// https://developer.apple.com/design/human-interface-guidelines/launching#Launch-screens

import UIKit

// 起動画面
class SplashViewController: UIViewController {
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		Task {
			try? await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
			
			let mainViewController = self.storyboard?.instantiateViewController(withIdentifier: "ViewController")
			self.navigationController?.setViewControllers([mainViewController!], animated: false)
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.setNavigationBarHidden(true, animated: true)
		self.navigationItem.title = ""
	}
	
}

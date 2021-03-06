//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 10.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import JGProgressHUD
import Kingfisher
import LocalAuthentication
import SafariServices
import SPAlert
import SwiftKeychainWrapper
import SwiftUI
import UIKit

class SettingsViewController: UITableViewController {
    @IBOutlet var accountProfilePicture: UIImageView!
    @IBOutlet var accountNametag: UILabel!
    @IBOutlet var versionBuildLabel: UILabel!
    @IBOutlet var biometricSwitch: UISwitch!
    @IBOutlet var showFlagOnPostSwitch: UISwitch!
    @IBOutlet var rickrollDetectionSwitch: UISwitch!
	@IBOutlet weak var imageCompressionControl: UISegmentedControl!
	
    var loadingHud: JGProgressHUD!

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true

        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String

        versionBuildLabel.text = "Version \(version) Build \(build)"

        let authContext = LAContext()
        var authError: NSError?
        if authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            biometricSwitch.isEnabled = true
        } else {
            biometricSwitch.isEnabled = false
        }

        biometricSwitch.setOn(UserDefaults.standard.bool(forKey: "biometricAuthEnabled"), animated: false)

        showFlagOnPostSwitch.setOn(!UserDefaults.standard.bool(forKey: "disablePostFlagLoading"), animated: false)

        rickrollDetectionSwitch.setOn(!UserDefaults.standard.bool(forKey: "rickrollDetectionDisabled"), animated: false)
		let savedImageCompression = UserDefaults.standard.double(forKey: "imageCompressionValue")
		if savedImageCompression == 0 {
			UserDefaults.standard.set(0.5, forKey: "imageCompressionValue")
			imageCompressionControl.selectedSegmentIndex = 2
		}
		else {
			switch savedImageCompression {
				case 0.25:
					imageCompressionControl.selectedSegmentIndex = 3
				case 0.5:
					imageCompressionControl.selectedSegmentIndex = 2
				case 0.75:
					imageCompressionControl.selectedSegmentIndex = 1
				case 1:
					imageCompressionControl.selectedSegmentIndex = 0
				default:
					UserDefaults.standard.set(0.5, forKey: "imageCompressionValue")
					imageCompressionControl.selectedSegmentIndex = 2
			}
		}

        let id = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id") ?? "_"
        let name = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.name") ?? ""
        let tag = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.tag") ?? ""

        accountNametag.text = "\(name)#\(tag)"
        accountProfilePicture.kf.setImage(with: URL(string: "https://avatar.alles.cc/\(id)?size=50"))
    }

    @IBAction func clearCache(_: Any) {
        Kingfisher.ImageCache.default.clearCache {
            SPAlert.present(title: "Cache cleared!", preset: .done)
        }
    }

    @IBAction func changePfpFlag(_: Any) {
        //navigationController?.pushViewController(SelectFlagViewController(style: .insetGrouped), animated: true)
		navigationController?.pushViewController(UIHostingController(rootView: SelectFlagView()), animated: true)
    }

    @IBAction func gotoNotificationSettings(_: Any) {
        navigationController?.pushViewController(UIHostingController(rootView: NotificationSettingsView(controller: .init())), animated: true)
    }

    @IBAction func showFlagOnPostSwitchChanged(_: Any) {
        UserDefaults.standard.set(!showFlagOnPostSwitch.isOn, forKey: "disablePostFlagLoading")
    }

    @IBAction func rickrollDetectionSwitchChanged(_: Any) {
        UserDefaults.standard.set(!rickrollDetectionSwitch.isOn, forKey: "rickrollDetectionDisabled")
    }

    @IBAction func biometricAuthChanged(_: Any) {
        let authContext = LAContext()
        var authError: NSError?
        let sceneDelegate = view.window!.windowScene!.delegate as! SceneDelegate

        if authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            UserDefaults.standard.set(biometricSwitch.isOn, forKey: "biometricAuthEnabled")
            sceneDelegate.sessionAuthorized = true
            SPAlert.present(title: "Biometric authentication \(biometricSwitch.isOn ? String("enabled") : String("disabled"))!", preset: .done)
        } else {
            sceneDelegate.sessionAuthorized = true
            biometricSwitch.isEnabled = false
            biometricSwitch.setOn(false, animated: true)
            UserDefaults.standard.set(false, forKey: "biometricAuthEnabled")

            var type = "FaceID / TouchID"
            let biometric = biometricType()
            switch biometric {
            case .face:
                type = "FaceID"
            case .touch:
                type = "TouchID"
            case .none:
                type = "FaceID / TouchID"
            }
            EZAlertController.alert("Device error", message: String(format: "\(type) is not enrolled on your device. Please verify it's enabled in your devices' settings"))
        }
    }
	
	@IBAction func changedImageCompressionValue(_ sender: UISegmentedControl) {
		switch sender.selectedSegmentIndex {
			case 0: // Best
				UserDefaults.standard.set(1, forKey: "imageCompressionValue")
			case 1: // Good
				UserDefaults.standard.set(0.75, forKey: "imageCompressionValue")
			case 2: // Normal
				UserDefaults.standard.set(0.5, forKey: "imageCompressionValue")
			case 3: // Bad
				UserDefaults.standard.set(0.25, forKey: "imageCompressionValue")
			default:
				UserDefaults.standard.set(0.5, forKey: "imageCompressionValue")
		}
	}
	

    var colorPickerController: ColorPickerController!
    var changeAccentColorSheet = UIAlertController(title: "Change accent color", message: "", preferredStyle: .actionSheet)

    @IBAction func changeAccentColor(_: UIButton) {
        changeAccentColorSheet = UIAlertController(title: "Change accent color", message: "", preferredStyle: .actionSheet)

        let currentAccentColor = UserDefaults.standard.colorForKey(key: "globalTintColor")
        colorPickerController = ColorPickerController(color: Color(currentAccentColor ?? UIColor.systemBlue))
        colorPickerController.delegate = self

        if let popoverController = changeAccentColorSheet.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }

        let height: NSLayoutConstraint = NSLayoutConstraint(item: changeAccentColorSheet.view!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 200)
        changeAccentColorSheet.view.addConstraint(height)

        let exitBtn: UIButton! = {
            let btn = UIButton(type: .close)
            btn.tintColor = .gray
            btn.addTarget(self, action: #selector(closeAccentSheet), for: .touchUpInside)
            return btn
        }()

        changeAccentColorSheet.view.addSubview(exitBtn)
        exitBtn.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.trailing.equalTo(-16)
        }

        let colorPickerView = UIHostingController(rootView: ColorPickerView(controller: colorPickerController)).view
        colorPickerView?.backgroundColor = .none

        changeAccentColorSheet.view.addSubview(colorPickerView!)
        colorPickerView?.snp.makeConstraints { make in
            make.center.equalTo(changeAccentColorSheet.view.snp.center)
            make.top.equalTo(changeAccentColorSheet.view.snp.top).offset(48)
            make.leading.equalTo(changeAccentColorSheet.view.snp.leading).offset(8)
            make.trailing.equalTo(changeAccentColorSheet.view.snp.trailing).offset(-8)
            make.bottom.equalTo(changeAccentColorSheet.view.snp.bottom).offset(-8)
        }

        present(changeAccentColorSheet, animated: true, completion: nil)
    }

    @objc func closeAccentSheet() {
        changeAccentColorSheet.dismiss(animated: true, completion: nil)
    }

    @IBAction func spicaButtons(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            let url = URL(string: "https://spica.li/privacy")!
            let vc = SFSafariViewController(url: url)
            present(vc, animated: true)
        case 1:
            //navigationController?.pushViewController(LegalNoticeViewController(), animated: true)
			navigationController?.pushViewController(UIHostingController(rootView: LegalNoticeView()), animated: true)
        case 2:
            let url = URL(string: "https://spica.li/")!
            let vc = SFSafariViewController(url: url)
            present(vc, animated: true)
        default: break
        }
    }

    @IBAction func signOut(_: Any) {
        loadingHud.show(in: view)

        var storedDeviceTokens = UserDefaults.standard.stringArray(forKey: "pushNotificationDeviceTokens") ?? []
        storedDeviceTokens.append(UserDefaults.standard.string(forKey: "pushNotificationCurrentDevice") ?? "")
        SpicaPushAPI.default.deleteDevices(storedDeviceTokens) { result in
            switch result {
            case let .failure(err):
                self.loadingHud.dismiss()
                EZAlertController.alert("Error", message: "The following error occurred while trying to revoke the push device tokens:\n\n\(err.error.humanDescription)")
            case .success:
				let domain = Bundle.main.bundleIdentifier!
				UserDefaults.standard.removePersistentDomain(forName: domain)
				UserDefaults.standard.synchronize()
                KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.name")
                KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.tag")
                KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.token")
                KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.id")
                UserDefaults.standard.set(false, forKey: "biometricAuthEnabled")
                self.loadingHud.dismiss()
                let sceneDelegate = self.view.window!.windowScene!.delegate as! SceneDelegate
                sceneDelegate.window?.rootViewController = sceneDelegate.loadInitialViewController()
                sceneDelegate.window?.makeKeyAndVisible()
            }
        }
    }

    @IBAction func allesMicroButtons(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            let url = URL(string: "https://files.alles.cc/Documents/Privacy%20Policy.txt")!
            let vc = SFSafariViewController(url: url)
            present(vc, animated: true)
        case 1:
            let url = URL(string: "https://files.alles.cc/Documents/Terms%20of%20Service.txt")!
            let vc = SFSafariViewController(url: url)
            present(vc, animated: true)
        case 2:
            let url = URL(string: "https://micro.alles.cx")!
            let vc = SFSafariViewController(url: url)
            present(vc, animated: true)
        default: break
        }
    }

    @IBAction func gotoCredits(_: Any) {
        //navigationController?.pushViewController(CreditsViewController(style: .insetGrouped), animated: true)
		navigationController?.pushViewController(UIHostingController(rootView: CreditsView()), animated: true)
    }

    @IBAction func gotoUsedLibraries(_: Any) {
        //navigationController?.pushViewController(UsedLibrariesViewController(style: .insetGrouped), animated: true)
		navigationController?.pushViewController(UIHostingController(rootView: UsedLibrariesView()), animated: true)
    }

    @IBAction func githubAction(_: Any) {
        let url = URL(string: "https://github.com/SpicaApp/Spica-iOS")!
        let vc = SFSafariViewController(url: url)
        present(vc, animated: true)
    }

    @IBAction func contactAction(_: Any) {
        let url = URL(string: "mailto:adrian@abmgrt.dev")!
        if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
    }

    @IBAction func joinBetaAction(_: Any) {
        let url = URL(string: "https://go.abmgrt.dev/spica-beta")!
        if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = "Loading..."
        loadingHud.interactionType = .blockNoTouches
    }
}

extension SettingsViewController {
    override func numberOfSections(in _: UITableView) -> Int {
        return 6
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2 // Account
        case 1: return 8 // Settings
        case 2: return 3 // Spica
        case 3: return 3 // Alles Micro
        case 4: return 5 // Other
        case 5: return 2 // About
        default: return 0
        }
    }
}

extension SettingsViewController: ColorPickerControllerDelegate {
    func changedColor(_ color: UIColor) {
        UserDefaults.standard.setColor(color: color, forKey: "globalTintColor")
        guard let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate else { return }
        sceneDelegate.window?.tintColor = color
    }
}

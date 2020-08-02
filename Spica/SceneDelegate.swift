//
//  SceneDelegate.swift
//  Spica
//
//  Created by Adrian Baumgart on 29.06.20.
//

import SwiftKeychainWrapper
import UIKit

@available(iOS 14.0, *)
var globalSplitViewController: GlobalSplitViewController!
@available(iOS 14.0, *)
var globalSideBarController: SidebarViewController!

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var toolbarDelegate = ToolbarDelegate()

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene

        if !UserDefaults.standard.bool(forKey: "hasRunBefore") {
            // Remove login data for security

            KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.token")
            KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.id")
            KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.username")
        }

        UserDefaults.standard.set(true, forKey: "hasRunBefore")

        // DEBUG: REMOVE KEY TO TEST LOGIN - DO NOT USE IN PRODUCTION
        /* KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.token")
         KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.id")
         KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.username") */

        if KeychainWrapper.standard.hasValue(forKey: "dev.abmgrt.spica.user.token"), KeychainWrapper.standard.hasValue(forKey: "dev.abmgrt.spica.user.id") {
            let initialView = setupInitialView()
            window?.rootViewController = initialView
            window?.makeKeyAndVisible()
        } else {
            window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
            window?.makeKeyAndVisible()
        }

        _ = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(sendOnline), userInfo: nil, repeats: true)
    }

    func setupTabView() -> UITabBarController {
        let tabBar = UITabBarController()
        let homeView = UINavigationController(rootViewController: TimelineViewController())
        homeView.tabBarItem = UITabBarItem(title: SLocale(.HOME), image: UIImage(systemName: "house"), tag: 0)
        let mentionView = UINavigationController(rootViewController: MentionsViewController())
        mentionView.tabBarItem = UITabBarItem(title: SLocale(.NOTIFICATIONS), image: UIImage(systemName: "bell"), tag: 1)
        let bookmarksView = UINavigationController(rootViewController: BookmarksViewController())
        bookmarksView.tabBarItem = UITabBarItem(title: SLocale(.BOOKMARKS), image: UIImage(systemName: "bookmark"), tag: 2)

        let userProfileVC = UserProfileViewController()
        let username = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.username")
        userProfileVC.user = User(id: "", username: username!, displayName: username!, nickname: username!, imageURL: URL(string: "https://avatar.alles.cx/u/\(username!)")!, isPlus: false, rubies: 0, followers: 0, image: ImageLoader.loadImageFromInternet(url: URL(string: "https://avatar.alles.cx/u/\(username!)")!), isFollowing: false, followsMe: false, about: "", isOnline: false)

        let accountView = UINavigationController(rootViewController: userProfileVC)
        accountView.tabBarItem = UITabBarItem(title: SLocale(.ACCOUNT), image: UIImage(systemName: "person"), tag: 3)
        tabBar.viewControllers = [homeView, mentionView, bookmarksView, accountView]
        return tabBar
    }

    func setupInitialView() -> UIViewController? {
        if #available(iOS 14.0, *) {
            let tabBar = setupTabView()
            globalSplitViewController = GlobalSplitViewController(style: .doubleColumn)
            globalSideBarController = SidebarViewController()
            // splitViewController.presentsWithGesture = false
            globalSplitViewController.setViewController(globalSideBarController, for: .primary)
            globalSplitViewController.setViewController(TimelineViewController(), for: .secondary)
            globalSplitViewController.setViewController(tabBar, for: .compact)
            globalSplitViewController.primaryBackgroundStyle = .sidebar

            globalSplitViewController.navigationItem.largeTitleDisplayMode = .always
            return globalSplitViewController
        } else {
            let tabBar = setupTabView()
            return tabBar
        }
    }

    @objc func sendOnline() {
        AllesAPI.default.sendOnlineStatus()
    }

    func sceneDidDisconnect(_: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}

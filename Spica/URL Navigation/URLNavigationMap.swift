//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 10.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import URLNavigator

struct URLNavigationMap {
    static func initialize(navigator: Navigator, sceneDelegate _: SceneDelegate) {
        navigator.register("spica://post/<string:id>") { _, values, _ in
            let postDetail = PostDetailViewController(style: .insetGrouped)
            guard let postID = values["id"] as? String else { return nil }
            postDetail.mainpost = Post(id: postID)
            return postDetail
        }

        navigator.register("spica://user/<string:id>") { _, values, _ in
            let userDetail = UserProfileViewController(style: .insetGrouped)
            guard let userID = values["id"] as? String else { return nil }
            userDetail.user = User(id: userID)
            return userDetail
        }
		
        navigator.register("spica://followers") { _, _, _ in
            let followers = FollowersFollowingViewController()
            followers.selectedIndex = 0
            return followers
        }

        navigator.register("spica://following") { _, _, _ in
            let followers = FollowersFollowingViewController()
            followers.selectedIndex = 1
            return followers
        }
    }
}

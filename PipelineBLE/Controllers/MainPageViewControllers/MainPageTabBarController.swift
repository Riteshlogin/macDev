//
//  MainPageTabBarController.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 8/8/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit

class MainPageTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  Add all navigation controllers to the tab bar controller. Specify details about each
        viewControllers = [createNavController(title: "Available Devices", imageName: "Available_Devices_Icon", rootView: AvailableDevicesViewController()),
                           createNavController(title: "Saved Devices", imageName: "Saved_Devices_Icon", rootView: SavedDevicesViewController()),
                           createNavController(title: "Past Data", imageName: "Past_Data_Icon", rootView: PastDataViewController())]
    }
    
    private func createNavController(title: String, imageName: String, rootView: UIViewController) -> UINavigationController {
        //  Create navigation controller with given root view, title, and image
        let navController = UINavigationController(rootViewController: rootView)
        navController.tabBarItem.title = title
        navController.tabBarItem.image = UIImage(named: imageName)
        return navController
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

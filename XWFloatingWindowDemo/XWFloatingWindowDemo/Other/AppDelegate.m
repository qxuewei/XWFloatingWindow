//
//  AppDelegate.m
//  XWFloatingWindowDemo
//
//  Created by 邱学伟 on 2018/7/22.
//  Copyright © 2018 邱学伟. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    ViewController *vc = [[ViewController alloc] init];
    UINavigationController *naviController = [[UINavigationController alloc] initWithRootViewController:vc];
    naviController.navigationBar.tintColor = [UIColor whiteColor];
    naviController.navigationBar.barStyle = UIBarStyleBlack;
    self.window.rootViewController = naviController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end

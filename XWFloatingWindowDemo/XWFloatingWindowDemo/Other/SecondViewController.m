//
//  SecondViewController.m
//  XWFloatingWindowDemo
//
//  Created by 邱学伟 on 2018/7/25.
//  Copyright © 2018年 邱学伟. All rights reserved.
//

#import "SecondViewController.h"
#import "XWFloatingWindowView.h"


@interface SecondViewController ()

@end

@implementation SecondViewController

#pragma mark - system
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIImageView *imageV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"girl_726.JPG"]];
    imageV.frame = self.view.bounds;
    [self.view addSubview:imageV];
    
    self.navigationItem.title = @"这是2号视图";
    
    UIButton *more = [UIButton buttonWithType:UIButtonTypeCustom];
    more.frame = CGRectMake(0, 0, 64, 30);
    [more setImage:[UIImage imageNamed:@"更多"] forState:UIControlStateNormal];
    [more addTarget:self action:@selector(moreClick:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:more];
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)dealloc {
    NSLog(@"%s",__func__);
}

#pragma mark - private
- (void)moreClick:(UIButton *)btn {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    NSString *title;
    BOOL isShowing = [XWFloatingWindowView isShowingWithViewController:self];
    if (isShowing) {
        title = @"取消浮窗";
    }else{
        title = @"浮窗";
    }
    [alert addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        if (isShowing) {
            NSLog(@"移除 浮窗");
            // 移除
            [XWFloatingWindowView remove];
        }else{
            NSLog(@"添加 浮窗");
            // 添加
            [XWFloatingWindowView showWithViewController:self];
        }
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"关闭视图保留浮窗" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"关闭视图保留浮窗");
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"关闭视图移除浮窗" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"关闭视图移除浮窗");
        [XWFloatingWindowView remove];
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"取消");
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

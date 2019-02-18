//
//  DistanceVC.m
//  传感器
//
//  Created by Mac on 2019/1/24.
//  Copyright © 2019 DuWenliang. All rights reserved.
//

#import "DistanceVC.h"


@interface DistanceVC ()

@end


@implementation DistanceVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    if (![UIDevice currentDevice].proximityMonitoringEnabled)
    {
        // 开启距离感应功能
        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    }
    // 监听距离感应的通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(proximityChange:)
                                                 name:UIDeviceProximityStateDidChangeNotification
                                               object:nil];
}

- (void)proximityChange:(NSNotification *)notification
{
    UIDevice *device = notification.object;
    if ([device isKindOfClass:[UIDevice class]])
    {
        if ([UIDevice currentDevice].proximityState == YES)
        {
            NSLog(@"某个物体靠近了设备屏幕"); // 屏幕会自动锁住
        }
        else
        {
            NSLog(@"某个物体远离了设备屏幕"); // 屏幕会自动解锁
        }
    }
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSLog(@"%@ 释放",[self class]);
}


@end

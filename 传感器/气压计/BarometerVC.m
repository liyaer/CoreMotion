//
//  BarometerVC.m
//  传感器
//
//  Created by Mac on 2019/2/22.
//  Copyright © 2019 DuWenliang. All rights reserved.
//

#import "BarometerVC.h"
#import <CoreMotion/CMAltimeter.h>


@interface BarometerVC ()

@property (nonatomic,strong) CMAltimeter *altimeter;

@end


@implementation BarometerVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    //检查iOS系统是否支持
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0)
    {
        //检查设备是否支持气压计
        if ([CMAltimeter isRelativeAltitudeAvailable])
        {
            self.altimeter = [[CMAltimeter alloc]init];
            
            //启用气压计
            __weak typeof(self) weakSelf = self;
            
            [self.altimeter startRelativeAltitudeUpdatesToQueue:NSOperationQueue.mainQueue withHandler:^(CMAltitudeData * _Nullable altitudeData, NSError * _Nullable error)
             {
                 if (error)
                 {
                     [weakSelf.altimeter stopRelativeAltitudeUpdates];
                 }
                 else
                 {
                     NSLog(@"--%lf \n--%lf",[altitudeData.relativeAltitude floatValue],[altitudeData.pressure floatValue]);
                 }
             }];
        }
    }
    else
    {
        NSLog(@"当前设备iOS系统低于8.0，不支持气压计！");
    }
}

- (void)dealloc
{
    [self.altimeter stopRelativeAltitudeUpdates];
    
    NSLog(@"%@ 释放",[self class]);
}

@end

//
//  StepCountVC.m
//  传感器
//
//  Created by Mac on 2019/1/24.
//  Copyright © 2019 DuWenliang. All rights reserved.
//

#import "StepCountVC.h"
#import <CoreMotion/CoreMotion.h>


@interface StepCountVC ()

@property (weak, nonatomic) IBOutlet UILabel *pedometerStartLbl;
@property (weak, nonatomic) IBOutlet UILabel *pedometerEndLbl;
@property (weak, nonatomic) IBOutlet UILabel *pedometerNowLbl;
@property (weak, nonatomic) IBOutlet UILabel *pedometerStepCountLbl;
@property (weak, nonatomic) IBOutlet UILabel *pedometerDistanceLbl;
@property (weak, nonatomic) IBOutlet UILabel *pedometerSpeedLbl;

@property (nonatomic, strong) CMPedometer       *pedometer;

@end


@implementation StepCountVC

#pragma mark - 懒加载

- (CMPedometer *)pedometer
{
    if (!_pedometer)
    {
        _pedometer = [[CMPedometer alloc] init];
    }
    return _pedometer;
}




#pragma mark - 视图加载

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    /*
          使用计步器需添加权限NSMotionUsageDescription描述
          第一次使用的时候系统自动会向用户请求授权
          授权判断：[CMSensorRecorder isAuthorizedForRecording];
     */
    
    // 可用性检测
    if(![CMPedometer isStepCountingAvailable])
    {
        [self showWithTitle:@"计步器不可用" message:nil];
        return;
    }
    // pedometer第一次被使用时，才会由系统提示用户授权“运动与健康”;但没找到授权的相关方法，通过该方式也可以实现需求
    __weak typeof (self) weakSelf = self;
    [self.pedometer queryPedometerDataFromDate:[NSDate date] toDate:[NSDate date] withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error)
    {
#warning 用户选择了授权与否之后，该block才会被调用，不在主线程
        
        dispatch_async(dispatch_get_main_queue(), ^
        {
            // 授权判断（即便用户点击了允许，isAuthorizedForRecording仍未NO，所以注释掉这里，以后慢慢探究）
//            if(![CMSensorRecorder isAuthorizedForRecording])
//            {
//                [weakSelf showWithTitle:@"未授权" message:@"前往设置－>隐私->运动与健康，点击允许访问"];
//                return;
//            }
            
            // 监测计步器状态：暂停、恢复
            [weakSelf.pedometer startPedometerEventUpdatesWithHandler:^(CMPedometerEvent * _Nullable pedometerEvent, NSError * _Nullable error)
            {
                NSLog(@"%@",pedometerEvent.type == CMPedometerEventTypePause? @"暂停":@"继续");
            }];
            
            // 监测计步器数据
            [weakSelf.pedometer startPedometerUpdatesFromDate:[NSDate date] withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error)
            {
                if (pedometerData)
                {
                    // 回调不在主线程，所以需要回到主线程处理
                    dispatch_async(dispatch_get_main_queue(), ^
                    {
                        NSDateFormatter *df = [[NSDateFormatter alloc] init];
                        df.dateFormat = @"HH:mm:ss";
                        weakSelf.pedometerStartLbl.text = [NSString stringWithFormat:@"当前时间：%@",[df stringFromDate:pedometerData.startDate]];
                        weakSelf.pedometerEndLbl.text = [NSString stringWithFormat:@"结束时间：%@",[df stringFromDate:pedometerData.endDate]];
                        weakSelf.pedometerNowLbl.text = [NSString stringWithFormat:@"现在：%@",[df stringFromDate:[NSDate date]]];
                        weakSelf.pedometerStepCountLbl.text = [NSString stringWithFormat:@"步数：%d", pedometerData.numberOfSteps.integerValue];
                        weakSelf.pedometerDistanceLbl.text = [NSString stringWithFormat:@"距离m：%f", pedometerData.distance.floatValue];
                        weakSelf.pedometerSpeedLbl.text = [NSString stringWithFormat:@"速度km/h：%f",3.6/pedometerData.averageActivePace.floatValue];
                    });
                }
            }];
        });
    }];
}




#pragma mark - 封装方法调用集合

// 显示提示信息
- (void)showWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}




#pragma mark - dealloc

-(void)dealloc
{
    [self.pedometer stopPedometerUpdates];
    [self.pedometer stopPedometerEventUpdates];
    
    NSLog(@"%@ 释放",[self class]);
}


@end

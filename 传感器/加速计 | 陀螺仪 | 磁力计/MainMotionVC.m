
//
//  MainMotionVC.m
//  传感器
//
//  Created by Mac on 2019/1/25.
//  Copyright © 2019 DuWenliang. All rights reserved.
//

#import "MainMotionVC.h"
#import <CoreMotion/CoreMotion.h>


@interface MainMotionVC ()

@property (weak, nonatomic) IBOutlet UILabel *accelerationXLbl;
@property (weak, nonatomic) IBOutlet UILabel *accelerationYLbl;
@property (weak, nonatomic) IBOutlet UILabel *accelerationZLbl;
@property (weak, nonatomic) IBOutlet UIImageView *santaClausImgV;

@property (nonatomic, strong) CMMotionManager   *motionManage;

@end


@implementation MainMotionVC

#pragma mark - 懒加载

- (CMMotionManager *)motionManage
{
    if (!_motionManage)
    {
        _motionManage = [[CMMotionManager alloc] init];
        // 控制传感器的更新间隔
        _motionManage.accelerometerUpdateInterval = 0.2;
        _motionManage.gyroUpdateInterval = 0.5;
        _motionManage.magnetometerUpdateInterval = 0.5;
        
        _motionManage.deviceMotionUpdateInterval = 0.2;
    }
    return _motionManage;
}




#pragma mark - 视图加载

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
#warning 测试以下任一效果时，请将其他注释掉
//    [self accelerometerTest];
    [self gyroTest];
//    [self magnetometerTest];
    
//    [self deviceMotionTest];
}

//加速计（deviceMotionTest中重力加速度和用户施加的加速度分开了，这里是在一起的，手机在水平桌面移动，X,Y轴数据会变化）
-(void)accelerometerTest
{
    // 可用性检测
    if(![self.motionManage isAccelerometerAvailable])
    {
        [self showWithTitle:@"加速计不可用" message:nil];
        return;
    }
    // 更新比较频繁，建议不使用主线程
    __weak typeof (self) weakSelf = self;
    [self.motionManage startAccelerometerUpdatesToQueue:[NSOperationQueue new] withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error)
     {
         // 回到主线程
         dispatch_async(dispatch_get_main_queue(), ^
            {
                weakSelf.accelerationXLbl.text = [NSString stringWithFormat:@"X轴加速度：%.2f", accelerometerData.acceleration.x];
                weakSelf.accelerationYLbl.text = [NSString stringWithFormat:@"Y轴加速度：%.2f", accelerometerData.acceleration.y];
                weakSelf.accelerationZLbl.text = [NSString stringWithFormat:@"Z轴加速度：%.2f", accelerometerData.acceleration.z];
                
                //模拟人所受的重力
                [UIView animateWithDuration:0.02 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction animations:^
                 {
                     CGFloat x = accelerometerData.acceleration.x;
                     CGFloat y = accelerometerData.acceleration.y;
                     if(y<0)
                     {
                         weakSelf.santaClausImgV.transform = CGAffineTransformMakeRotation(-x*M_PI_2);
                     }
                     else
                     {
                         weakSelf.santaClausImgV.transform = CGAffineTransformMakeRotation(-M_PI_2-(1-x)*M_PI_2);
                     }
                 } completion:nil];
            });
     }];
}

//陀螺仪
-(void)gyroTest
{
    // 可用性检测
    if(![self.motionManage isGyroAvailable]){
        [self showWithTitle:@"陀螺仪不可用" message:nil];
        return;
    }
    
    if (![self.motionManage isGyroActive])
    {
        __weak typeof (self) weakSelf = self;
        [self.motionManage startGyroUpdatesToQueue:[NSOperationQueue new] withHandler:^(CMGyroData * _Nullable gyroData, NSError * _Nullable error)
        {
            CGFloat x = gyroData.rotationRate.x;
            CGFloat y = gyroData.rotationRate.y;
            CGFloat z = gyroData.rotationRate.z;
            CGFloat rate = sqrt(x*x + y*y + z*z);
            // 回到主线程
            dispatch_async(dispatch_get_main_queue(), ^
            {
                weakSelf.accelerationXLbl.text = [NSString stringWithFormat:@"绕X轴旋转的角速度：%.2f", x];
                weakSelf.accelerationYLbl.text = [NSString stringWithFormat:@"绕Y轴旋转的角速度：%.2f", y];
                weakSelf.accelerationZLbl.text = [NSString stringWithFormat:@"绕Z轴旋转的角速度：%.2f", z];
                NSLog(@"%@",[NSString stringWithFormat:@"%.2f", rate]);
            });
        }];
    }
}

//磁力计
-(void)magnetometerTest
{
    if(![self.motionManage isMagnetometerAvailable])
    {
        [self showWithTitle:@"磁力计不可用" message:nil];
        return;
    }
    if (![self.motionManage isMagnetometerActive])
    {
        __weak typeof (self) weakSelf = self;
        [self.motionManage startMagnetometerUpdatesToQueue:[NSOperationQueue new] withHandler:^(CMMagnetometerData * _Nullable magnetometerData, NSError * _Nullable error)
         {
             CGFloat x = magnetometerData.magneticField.x;
             CGFloat y = magnetometerData.magneticField.y;
             CGFloat z = magnetometerData.magneticField.z;
             
             // 回到主线程
             dispatch_async(dispatch_get_main_queue(), ^
                {
                    weakSelf.accelerationXLbl.text = [NSString stringWithFormat:@"X方向磁力：%.2f", x];
                    weakSelf.accelerationYLbl.text = [NSString stringWithFormat:@"Y方向磁力：%.2f", y];
                    weakSelf.accelerationZLbl.text = [NSString stringWithFormat:@"Z方向磁力：%.2f", z];
                });
         }];
    }
}

//一次性获取所有
-(void)deviceMotionTest
{
    // 检测加速计和陀螺仪，由于设备都有加速计，所以等效于陀螺仪检测
    if(![self.motionManage isDeviceMotionAvailable])
    {
        return;
    }
    
    if (![self.motionManage isDeviceMotionActive])
    {
        __weak typeof (self) weakSelf = self;
        // 获取的数据综合了加速计、陀螺仪、磁力计
        [self.motionManage startDeviceMotionUpdatesToQueue:[NSOperationQueue new] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error)
         {
             /*
                 设备当前的空间方位(包含下面三个欧拉角的值，手机正面朝上放置在水平的桌面上时，三个值都是0)
                    roll：手机绕 Y 轴旋转的角度值,逆时针绕一周取值依次是：0 -> π/2 -> π（-π）-> -π/2 -> 0
                    pitch：.....X..............................：0 -> π/2 -> 0 -> -π/2 -> 0
                    yaw：.......Z..............................：0 -> π/2 -> π（-π）-> -π/2 -> 0
              */
             CMAttitude *attitude =  motion.attitude;
             
             //陀螺仪
             CMRotationRate rotationRate = motion.rotationRate;
             
             /*
                  CMCalibratedMagneticField结构体变量, 包括field和accuracy两个字段, 其中field代表X,Y,Z轴上的磁场强度, accuracy则代表磁场强度的精度
              */
             CMCalibratedMagneticField magnet = motion.magneticField;
             
             //地球重力对该设备在X,Y,Z轴上施加的重力加速度
             CMAcceleration gravity = motion.gravity;
             
             //用户外力对该设备在X,Y,Z轴上施加的重力加速度
             CMAcceleration userAcceleration = motion.userAcceleration;
             
             
             dispatch_async(dispatch_get_main_queue(), ^
             {
#warning 测试以下任一效果时，请将其他注释掉
//                 weakSelf.accelerationXLbl.text = [NSString stringWithFormat:@"roll(绕Y)：%.4f", attitude.roll];
//                 weakSelf.accelerationYLbl.text = [NSString stringWithFormat:@"pitch(绕X)：%.4f", attitude.pitch];
//                 weakSelf.accelerationZLbl.text = [NSString stringWithFormat:@"yaw(绕Z)：%.4f", attitude.yaw];
                 
//                 weakSelf.accelerationXLbl.text = [NSString stringWithFormat:@"绕X轴旋转的角速度：%.4f", rotationRate.x];
//                 weakSelf.accelerationYLbl.text = [NSString stringWithFormat:@"绕Y轴旋转的角速度：%.4f", rotationRate.y];
//                 weakSelf.accelerationZLbl.text = [NSString stringWithFormat:@"绕Z轴旋转的角速度：%.4f", rotationRate.z];
                 
                 //这一组没有数据，为啥？
                 weakSelf.accelerationXLbl.text = [NSString stringWithFormat:@"X方向磁力：%.2f", magnet.field.x];
                 weakSelf.accelerationYLbl.text = [NSString stringWithFormat:@"Y方向磁力：%.2f", magnet.field.y];
                 weakSelf.accelerationZLbl.text = [NSString stringWithFormat:@"Z方向磁力：%.2f", magnet.field.z];
                 NSLog(@"磁力精确度：%d",magnet.accuracy);
                 
//                 weakSelf.accelerationXLbl.text = [NSString stringWithFormat:@"X轴重力加速度：%.2f", gravity.x];
//                 weakSelf.accelerationYLbl.text = [NSString stringWithFormat:@"Y轴重力加速度：%.2f", gravity.y];
//                 weakSelf.accelerationZLbl.text = [NSString stringWithFormat:@"Z轴重力加速度：%.2f", gravity.z];
                 
                 if (userAcceleration.x < -0.5)
                 {
                     [weakSelf.navigationController popViewControllerAnimated:YES];
                 }
             });
        }];
    }
}




#pragma mark - 封装方法调用集合

// 显示提示信息
- (void)showWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}




#pragma mark - 释放

-(void)dealloc
{
    [self.motionManage stopAccelerometerUpdates];
    [self.motionManage stopMagnetometerUpdates];
    [self.motionManage stopGyroUpdates];
    
    [self.motionManage stopDeviceMotionUpdates];
    
    NSLog(@"%@ 释放",[self class]);
}

@end

//
//  TouchIDVC.m
//  传感器
//
//  Created by Mac on 2019/2/18.
//  Copyright © 2019 DuWenliang. All rights reserved.
//

#import "TouchIDVC.h"
#import <LocalAuthentication/LocalAuthentication.h>


static NSString *_localizedReason = @"通过Home键验证已有手机指纹";


@interface TouchIDVC ()

@end


@implementation TouchIDVC

- (void)viewDidLoad
{
    [super viewDidLoad];

}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    //第一步：检查iOS系统版本是否支持
    if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0)
    {
        [self createAlterView:@"不支持指纹识别"];
    }
    else
    {
        //第二步：创建LAContext对象
        LAContext *ctx = [[LAContext alloc] init];
        //设置 输入密码 按钮的标题
        ctx.localizedFallbackTitle = @"验证登录密码";
        //设置 取消 按钮的标题 iOS10之后
        ctx.localizedCancelTitle = @"取消";
        
        //第三步：检查设备硬件是否支持
        /*
         *   在这里简单介绍一下LAPolicy,它是一个枚举.我们根据自己的需要选择LAPolicy，它提供两个值:
         <1>. LAPolicyDeviceOwnerAuthenticationWithBiometrics是支持iOS8以上系统,使用该设备的“TouchID”进行验证,当输入TouchID验证5次失败后,TouchID被锁定,只能通过 设置 -> 触控ID与密码 输入正确锁屏密码来解锁TouchID。（TouchID验证失败时，会有localizedCancelTitle、localizedFallbackTitle两个选项，但是点击localizedFallbackTitle也不会弹出设备密码验证页面，因为该方式只支持TouchID验证）
         <2>.LAPolicyDeviceOwnerAuthentication是支持iOS9以上系统,使用该设备的“TouchID”或“设备密码”进行验证，当输入TouchID验证5次失败后，TouchID被锁定，会触发设备密码页面进行验证。
         */
        NSError *error;
        if (NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_9_0)//iOS 8
        {
            if ([ctx canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error])
            {
                [ctx evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:_localizedReason reply:^(BOOL success, NSError * error)
                {
                    if (success)
                    {
                        [self createAlterView:@"指纹验证成功"];
                    }
                    else
                    {
                        NSLog(@"指纹识别错误描述 %@",error.description);
                        // -1: 连续三次指纹识别错误
                        // -2: 在TouchID对话框中点击了取消按钮
                        // -3: 在TouchID对话框中点击了输入密码按钮
                        // -4: TouchID对话框被系统取消，例如按下Home或者电源键
                        // -8: 连续五次指纹识别错误，TouchID功能被锁定，下一次需要输入系统密码
                        NSString *message;
                        switch (error.code)
                        {
                            case -1://LAErrorAuthenticationFailed
                                message = @"已经连续三次指纹识别错误了（不会弹出密码验证页面）";
                                break;
                            case -2:
                                message = @"在TouchID对话框中点击了取消按钮";
                                return ;
                                break;
                            case -3:
                                message = @"在TouchID对话框中点击了输入密码按钮（不会弹出密码验证页面）";
                                break;
                            case -4:
                                message = @"TouchID对话框被系统取消，例如按下Home或者电源键";
                                break;
                            case -8:
                                message = @"TouchID已经被锁定,请前往 设置->触控ID与密码 重新启用";
                                break;
                            default:
                                break;
                        }
                        [self createAlterView:message];
                    }
                }];
            }
            else
            {
                if (error.code == -8)
                {
                    [self createAlterView:@"由于五次识别错误TouchID已经被锁定,请前往 设置->触控ID与密码 重新启用"];
                }
                else
                {
                    [self createAlterView:@"TouchID不可用，可能的原因：1，没有设置指纹,请前往设置；2，设备不支持"];
                }
            }
        }
        else//iOS 9 及以上
        {
            if ([ctx canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&error])
            {
                [ctx evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:_localizedReason reply:^(BOOL success, NSError * error)
                 {
                     if (success)
                     {
                         [self createAlterView:@"指纹验证成功"];
                     }
                     else
                     {
                         NSLog(@"指纹识别错误描述 %@",error.description);
                         NSString *message;
                         switch (error.code)
                         {
                            //连续三次识别错误，直接弹出密码验证页面，不会出现error，因此不会走进case=-1的情况
                                 
                             case -2:
                                 message = @"在TouchID对话框中点击了取消按钮、密码验证页面点击取消、按下Home键";
                                 return ;
                                 break;
                                 
                            //在TouchID对话框中点击了输入密码按钮，。。。。。。。。。。。。。。。。case=-3。。。

                             case -4:
                                 message = @"TouchID对话框被系统取消，例如按下电源键";
                                 break;

                            //因为会弹出密码验证页面，且密码验证页面错误次数和TouchID错误次数无关，因此不会出现case=-8的情况
                                 
                             default:
                                 break;
                         }
                         [self createAlterView:message];
                     }
                 }];
            }
            else
            {
                //若设备支持，但未设置TouchID，那么会自动弹出密码验证页面，不会走进这里
                [self createAlterView:@"TouchID不可用，设备不支持"];
            }
        }
    }
}

- (void)createAlterView:(NSString *)message
{
    UIAlertController *vc = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [vc addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
    {
        [vc dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:vc animated:NO completion:nil];
}

- (void)dealloc
{    
    NSLog(@"%@ 释放",[self class]);
}

@end

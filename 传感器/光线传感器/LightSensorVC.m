//
//  LightSensorVC.m
//  传感器
//
//  Created by Mac on 2019/1/23.
//  Copyright © 2019 DuWenliang. All rights reserved.
//

#import "LightSensorVC.h"
#import <AVFoundation/AVFoundation.h>

/*
    1.  <GraphicsServices/GraphicsServices.h>提供光线强度的检测，但为苹果私有api，不允许上架产品使用，所以使用其它方式检测
 
    2. 检测屏幕亮度
        1. 对手机自动亮度调节进行设置，设置-->显示与亮度-->允许自动亮度调节
        2. 当手机感受到外界光线亮度变化时，会自动调节屏幕亮度；或手动调节屏幕亮度
        3. 通过[UIScreen mainScreen].brightness，可以获取屏幕亮度
 
    3. 摄像头检测：通过对摄像头捕获的视频流进行分析
 */

@interface LightSensorVC ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) IBOutlet UIView      *lightVideoV;
@property (weak, nonatomic) IBOutlet UILabel     *screenBightnessLbl;
@property (weak, nonatomic) IBOutlet UILabel     *cameraBightnessLbl;

@property (nonatomic, strong) AVCaptureSession   *captureSession;

@end


@implementation LightSensorVC

#pragma mark - 懒加载

// 初始化视频流
- (AVCaptureSession *)captureSession
{
    // 第一次创建AVCaptureDeviceInput对象时系统会自动向用户请求授权
    if (!_captureSession)
    {
        // 创建会话
        NSError *error;
        AVCaptureSession *captureSession = [AVCaptureSession new];
        _captureSession = captureSession;
        
        // 输入：摄像头
        AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        AVCaptureDeviceInput *cameraDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:cameraDevice error:&error];
        if ([captureSession canAddInput:cameraDeviceInput])
        {
            [captureSession addInput:cameraDeviceInput];
        }
        
        // 输出：视频数据
        // "当有视频数据输出时，会调用AVCaptureVideoDataOutputSampleBufferDelegate代理方法"
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
        [output setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        if ([captureSession canAddOutput:output])
        {
            [captureSession addOutput:output];
        }
        
        // 实时预览：展现给用户
        AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
        previewLayer.frame = self.lightVideoV.bounds;
        [self.lightVideoV.layer addSublayer:previewLayer];
    }
    return _captureSession;
}




#pragma mark - 视图加载

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //摄像头光线检测
    BOOL cameraAvailable = [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
    if (!cameraAvailable)
    {
        [self showWithTitle:@"摄像头不可用" message:nil];
        return;
    }
    __weak typeof (self) weakSelf = self;
    // 第一次会弹框请求授权，之后直接获取授权状态；如果未授权，视频为黑色画面，音频没声音
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted)
    {
        // 非主线程
        NSLog(@"-------%@", [NSThread currentThread]);
        dispatch_async(dispatch_get_main_queue(), ^
        {
            //获取授权状态
            //AVAuthorizationStatus cameraAS = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            if (!granted)
            {
                [weakSelf showWithTitle:@"摄像头未被授权" message:@"前往设置-->隐私-->相机 选择允许访问"];
                return ;
            }
            [weakSelf.captureSession startRunning];
        });
    }];
    
    //屏幕光线检测
    self.screenBightnessLbl.text = [NSString stringWithFormat:@"屏幕光线检测：%.2f",[UIScreen mainScreen].brightness];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(brightnessChangeNoti:) name:UIScreenBrightnessDidChangeNotification object:nil];
}

- (void)brightnessChangeNoti:(NSNotification *)noti
{
    UIScreen *screen = noti.object;
    if (![screen isKindOfClass:[UIScreen class]])
    {
        screen = nil;
    }
    self.screenBightnessLbl.text = [NSString stringWithFormat:@"屏幕光线检测：%.2f", screen.brightness];
}




#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

// 输出视频流
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
    CFRelease(metadataDict);
    
    NSDictionary *exifMetadata = [metadata[(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
    float brightnessValue = [exifMetadata[(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
    self.cameraBightnessLbl.text = [NSString stringWithFormat:@"摄像头光线检测：%.2f",brightnessValue];
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
    [self.captureSession stopRunning];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenBrightnessDidChangeNotification object:nil];
    
    NSLog(@"%@ 释放",[self class]);
}

@end

//
//  ViewController.m
//  传感器
//
//  Created by Mac on 2019/1/22.
//  Copyright © 2019 DuWenliang. All rights reserved.
//

#import "AccelerationVC.h"
#import <CoreMotion/CoreMotion.h>


/*
 *   关于两张图片的说明：手机都是水平放置在桌面上，坐标轴是相对于水平放置的手机而言，因此手机翻转，坐标轴跟随手机一起翻转
     加速度坐标轴：当手机呈水平放置的时候，X轴从左（负值）到右（正值），Y周从下（负值）到上（正值），还有就是Z轴垂直方向上从背屏（负值）到屏幕（正值）
     角速度坐标轴：右手法则，大拇指指向坐标轴正方向，四指所指方向即为角速度正方向
 */

@interface AccelerationVC ()
{
    NSTimer *_updateTimer;
}
@property (weak, nonatomic) IBOutlet UIStackView *stackView;
@property (weak, nonatomic) IBOutlet UIView *ball;

@property (nonatomic,strong) CMMotionManager *motionManger;
@property (nonatomic,strong) UIDynamicAnimator *animator;
@property (nonatomic,strong) UIGravityBehavior *grayityBehavior;
@property (nonatomic,strong) UICollisionBehavior *collisionBehavior;

@end


@implementation AccelerationVC

#pragma mark - 懒加载

-(CMMotionManager *)motionManger
{
    if (!_motionManger)
    {
        _motionManger = [[CMMotionManager alloc] init];
    }
    return _motionManger;
}




#pragma mark - 加载视图

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //写法一：主动获取（pull）--- MainMotionVC中的四个例子也都有这两种写法，但写法一略显繁琐，而且要考虑定时器的释放问题，因此都用了写法二
    if (self.motionManger.isAccelerometerAvailable)
    {
        if (!self.motionManger.isAccelerometerActive)
        {
            [self.motionManger startAccelerometerUpdates];

            _updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 repeats:YES block:^(NSTimer * _Nonnull timer)
            {
                [self setData:self.motionManger.accelerometerData];
            }];
        }
    }
    
    //写法二：基于代码块获取（push）
//    //设置更新频率
//    self.motionManger.accelerometerUpdateInterval = 1;
//
//    //按更新频率从硬件读取值
//    if (self.motionManger.isAccelerometerAvailable)
//    {
//        if (!self.motionManger.isAccelerometerActive)
//        {
//            //在主队列启动，block回调也在主线程（MainMotionVC中是在非主队列启动，因此block回调在子线程，刷新UI需要切换到主线程）
//            __weak typeof(self) weakSelf = self;
//            [self.motionManger startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error)
//            {
//                if (error)
//                {
//                    [weakSelf.motionManger stopAccelerometerUpdates];
//                }
//                else
//                {
//                    [weakSelf setData:accelerometerData];
//                }
//            }];
//        }
//    }
    
    [self initAnimation];
}




#pragma mark - 封装方法调用集合

//动画
-(void)initAnimation
{
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    self.grayityBehavior = [[UIGravityBehavior alloc] init];
    [self.grayityBehavior addItem:self.ball];
    self.grayityBehavior.gravityDirection = CGVectorMake(0, 0);
    [self.animator addBehavior:self.grayityBehavior];
    
    self.collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.ball]];
    self.collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    [self.animator addBehavior:self.collisionBehavior];
}

-(void)setData:(CMAccelerometerData *)data
{
    [self setX:data.acceleration.x];
    [self setY:data.acceleration.y];
    [self setZ:data.acceleration.z];
    
    self.grayityBehavior.gravityDirection = CGVectorMake(data.acceleration.x, -data.acceleration.y);
}

-(void)setX:(double)x
{
    [self setValue:x atIndex:0];
}

-(void)setY:(double)y
{
    [self setValue:y atIndex:1];
}

-(void)setZ:(double)z
{
    [self setValue:z atIndex:2];
}

-(void)setValue:(double)value atIndex:(NSInteger)index
{
    NSString *text = [NSString stringWithFormat:@"%@轴加速度: %f",index == 0 ? @"X" : (index == 1 ? @"Y" : @"Z"),value];
    [(UILabel *)self.stackView.arrangedSubviews[index] setText:text];
}




#pragma mark - 释放

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
//    [self.motionManger stopAccelerometerUpdates];
    
    if (_updateTimer && [_updateTimer isValid])
    {
        [_updateTimer invalidate];
    }
}

-(void)dealloc
{
//#error stopAccelerometerUpdates写在这里VC不释放，和startAccelerometerUpdatesToQueue是否在主队列启动没关系（MainMotionVC修改到主队列可以释放已验证）；写在viewWillDisappear可以释放，到底什么原因？答：block循环引用，VC（self）持有_motionManger，_motionManger的block中又用了self，因此写在这里无法释放，而写在viewWillDisappear中解除了_motionManger对self的强引用，循环引用解除了，所以可以释放
    [self.motionManger stopAccelerometerUpdates];
    
    NSLog(@"%@ 释放",[self class]);
}

@end

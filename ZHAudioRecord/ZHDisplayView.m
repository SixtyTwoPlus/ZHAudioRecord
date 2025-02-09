//
//  ZHDisplayView.m
//  ZHDisplayView
//
//  Created by ZHL on 2025/2/8.
//  Copyright © 2025 ZHL. All rights reserved.
//

#import "ZHDisplayView.h"
#import "ZHCurveView.h"
#import "ZHSpectrumView.h"
#import "ZHAudioRecordMarco.h"
#import <Accelerate/Accelerate.h>
#import <Masonry/Masonry.h>

#define CURVE_HEIGHT 133.5
#define CURVE_SIZE CGSizeMake(ZHRECORD_WIDTH, CURVE_HEIGHT)

@interface ZHDisplayView()

@property (nonatomic,strong) ZHCurveView                *curveView;
@property (nonatomic,strong) UILabel                    *titleLab;
@property (nonatomic,strong) UIButton                   *closeBtn;
@property (nonatomic,strong) ZHSpectrumView             *spectrumView;
@property (nonatomic,strong) UILabel                    *timeLab;
@property (nonatomic,strong) UIImageView                *recordImgView;
@property (nonatomic,strong) UIImageView                *spectrumViewBg;

@property (nonatomic,assign) CGRect                     curveInitFrame;

@end

@implementation ZHDisplayView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = ZHRECORD_COLOR_HEX_ALPHA(0x292929, 0.5);
        [self setupSubViews];
    }
    return self;
}

#pragma mark - methods

- (void)setupSubViews{
    CGFloat scale = 200 / CURVE_SIZE.width;
    
    CGSize initalSize = CGSizeApplyAffineTransform(CURVE_SIZE, CGAffineTransformMakeScale(scale, scale));
    CGFloat y = ZHRECORD_HEIGHT- initalSize.height;
    CGFloat x = (ZHRECORD_WIDTH - 200) / 2;
    
    self.curveInitFrame = CGRectMake(x, y, initalSize.width, initalSize.height);
    self.curveView = [[ZHCurveView alloc]initWithFrame:self.curveInitFrame];
    [self addSubview:self.curveView];
    
    self.titleLab = [UILabel new];
    self.titleLab.text = @"上滑 取消\n松开 发送";
    self.titleLab.numberOfLines = 0;
    self.titleLab.textColor = UIColor.whiteColor;
    self.titleLab.font = [UIFont systemFontOfSize:14];
    [self addSubview:self.titleLab];
    
    self.closeBtn = [UIButton new];
    [self.closeBtn setImage:[UIImage imageNamed:@"zh_recorder_cancel"] forState:UIControlStateNormal];
    [self addSubview:self.closeBtn];
    
    CGRect spectrumRect = CGRectMake((ZHRECORD_WIDTH - 160) / 2, (ZHRECORD_HEIGHT - 66) / 2, 160, 66);
    self.spectrumViewBg = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"zh_record_wave_bg"]];
    self.spectrumViewBg.frame = spectrumRect;
    [self addSubview:self.spectrumViewBg];

    CGRect spectrumRect2 = CGRectMake(20, 12 , 120, 30);
    self.spectrumView = [[ZHSpectrumView alloc]initWithFrame:spectrumRect2];
    self.spectrumView.barColor = ZHRECORD_COLOR_HEX(0x292929);
    [self.spectrumViewBg addSubview:self.spectrumView];
    
    self.timeLab = [UILabel new];
    self.timeLab.text = @"00:01";
    self.timeLab.textColor = UIColor.whiteColor;
    self.timeLab.font = [UIFont systemFontOfSize:14];
    [self addSubview:self.timeLab];
    
    self.recordImgView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"zh_record_ic"]];
    self.recordImgView.hidden = YES;
    [self addSubview:self.recordImgView];
    
    [self.titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.curveView.mas_top).offset(-12);
        make.centerX.equalTo(self);
    }];
    
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.titleLab.mas_top).offset(-24);
        make.centerX.equalTo(self);
        make.width.height.mas_equalTo(60);
    }];
    
    [self.timeLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.spectrumViewBg.mas_bottom).offset(11);
        make.centerX.equalTo(self);
    }];
    
    [self.recordImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.curveView);
    }];
}

#pragma mark - ZHDisplayViewProtocol

- (void)upgradeGesturePoint:(CGPoint)point{
    CGPoint localPoint = [self convertPoint:point toView:self];
    if (_isCancel) {
        _isCancel = !CGRectContainsPoint(self.curveView.frame, point);
    }else{
        _isCancel = CGRectContainsPoint(self.closeBtn.frame, localPoint);
    }
    self.spectrumViewBg.image = _isCancel ? [UIImage imageNamed:@"zh_record_wave_bg_red"] : [UIImage imageNamed:@"zh_record_wave_bg"];
}

- (void)show{
    _isCancel = NO;
    self.frame = CGRectMake(0, 0, ZHRECORD_WIDTH, ZHRECORD_HEIGHT);
    [UIApplication.sharedApplication.delegate.window addSubview:self];
    
    CGFloat y = self.frame.size.height - CURVE_SIZE.height;
    [UIView animateWithDuration:0.1 animations:^{
        self.alpha = 1;
    }];
    [UIView animateWithDuration:0.2 animations:^{
        self.curveView.frame = CGRectMake(0, y, CURVE_SIZE.width, CURVE_SIZE.height);
        self.recordImgView.hidden = NO;
    }];
}

- (void)dismiss{
    [UIView animateWithDuration:0.1 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        self.curveView.frame = self.curveInitFrame;
        self.recordImgView.hidden = YES;
        [self removeFromSuperview];
    }];
}

- (void)setRecordTime:(NSInteger)second {
    NSInteger min = second / 60;
    NSInteger minSecond = second % 60;
    self.timeLab.text = [NSString stringWithFormat:@"%02ld:%02ld",min,minSecond];
}

- (void)setFrequencyBands:(NSArray<NSNumber *> *)frequencyBands{
    self.spectrumView.frequencyBands = frequencyBands;
}

- (NSInteger)bandCount{
    return self.spectrumView.bandCount;
}

@synthesize isCancel = _isCancel;

@end

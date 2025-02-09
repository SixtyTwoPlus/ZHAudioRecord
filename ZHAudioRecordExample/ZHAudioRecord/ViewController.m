//
//  ViewController.m
//  ZHAudioRecord
//
//  Created by ZHL on 2025/2/8.
//

#import "ViewController.h"
#import "ZHAudioRecord.h"
#import <Masonry/Masonry.h>

@interface ViewController ()<ZHAudioRecordDelegate>

@property (nonatomic,strong) UIButton *button;
@property (nonatomic,strong) UIButton *norlmalBtn;
@property (nonatomic,strong) UIButton *engineBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self) weakSelf = self;
    
    UIStackView *stackView = [UIStackView new];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionEqualSpacing;
    stackView.spacing = 6;
    [self.view addSubview:stackView];
    
    UIButton *normalBtn = [UIButton new];
    [normalBtn setTitle:@"AVAudioRecorder" forState:UIControlStateNormal];
    [normalBtn setTitleColor:UIColor.redColor forState:UIControlStateNormal];
    normalBtn.layer.cornerRadius = 8;
    normalBtn.layer.masksToBounds = YES;
    normalBtn.layer.borderWidth = 1;
    normalBtn.layer.borderColor = UIColor.redColor.CGColor;
    [normalBtn addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        weakSelf.engineBtn.layer.borderWidth = 0;
        weakSelf.norlmalBtn.layer.borderWidth = 1;
        ZHAudioRecord.record.recordType = ZHAudioRecordTypeNormal;
    }] forControlEvents:UIControlEventTouchUpInside];
    self.norlmalBtn = normalBtn;
    [stackView addArrangedSubview:normalBtn];
    
    UIButton *engineBtn = [UIButton new];
    [engineBtn setTitle:@"AVAudioEngine" forState:UIControlStateNormal];
    [engineBtn setTitleColor:UIColor.redColor forState:UIControlStateNormal];
    engineBtn.layer.cornerRadius = 8;
    engineBtn.layer.masksToBounds = YES;
    engineBtn.layer.borderWidth = 0;
    engineBtn.layer.borderColor = UIColor.redColor.CGColor;
    [engineBtn addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        weakSelf.engineBtn.layer.borderWidth = 1;
        weakSelf.norlmalBtn.layer.borderWidth = 0;
        ZHAudioRecord.record.recordType = ZHAudioRecordTypeEngine;
    }] forControlEvents:UIControlEventTouchUpInside];
    self.engineBtn = engineBtn;
    [stackView addArrangedSubview:engineBtn];
    
    self.button = [UIButton new];
    [self.button setTitle:@"按住开始录音" forState:UIControlStateNormal];
    [self.button setTitleColor:UIColor.redColor forState:UIControlStateNormal];
    self.button.layer.cornerRadius = 8;
    self.button.layer.masksToBounds = YES;
    self.button.layer.borderWidth = 1;
    self.button.layer.borderColor = UIColor.redColor.CGColor;
    [self.button addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureAction:)]];
    [self.view addSubview:self.button];
    
    [self.button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.centerX.equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(200, 60));
    }];
    
    [stackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    
    [normalBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(200, 60));
    }];
    
    [engineBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(normalBtn);
    }];
    
    ZHAudioRecord.record.delegate = self;
}

#pragma mark - action

- (void)gestureAction:(UILongPressGestureRecognizer *)gesture{
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"example"];
    
    CGPoint point = [gesture locationInView:self.view];
    [ZHAudioRecord.record.displayView upgradeGesturePoint:point];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [ZHAudioRecord.record startRecordWithFilePath:filePath];
        return;
    }
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        [ZHAudioRecord.record stopRecord];
    }
}

#pragma mark - ZHAudioRecordDelegate

- (void)audioRecord:(ZHAudioRecord *)record didFinishRecordWithUrlPath:(NSString *)urlPath status:(ZHRecordFinishStatus)status{
    
    
}

- (void)audioRecord:(ZHAudioRecord *)record didErrored:(NSError *)error{
    
}

@end

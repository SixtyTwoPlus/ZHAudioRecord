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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    
    ZHAudioRecord.record.delegate = self;
}

#pragma mark - action

- (void)gestureAction:(UILongPressGestureRecognizer *)gesture{
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"123"];
    
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

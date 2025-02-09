//
//  ZHAudioRecordManager.m
//  ZHAudioRecordManager
//
//  Created by ZHL on 2025/2/8.
//  Copyright © 2025 ZHL. All rights reserved.
//


#import "ZHAudioRecordInternal.h"
#import "ZHDisplayView.h"
#import <AVFoundation/AVFoundation.h>

@interface ZHAudioRecord()<AVAudioRecorderDelegate>

@property (nonatomic,strong) AVAudioRecorder            *recorder;
@property (nonatomic) dispatch_source_t                 timer;
@property (nonatomic,assign) NSInteger                  recordTime;
@property (nonatomic) dispatch_queue_t                  queue;

@property (nonatomic,assign) float                      averagePower;

@end

@implementation ZHAudioRecord

+ (instancetype)record{
    static dispatch_once_t onceToken;
    static ZHAudioRecord *record;
    dispatch_once(&onceToken, ^{
        record = [ZHAudioRecord new];
    });
    return record;
}

+ (BOOL)checkRecordPrivacy{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (status == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            
        }];
        return NO;
    }
    if (status == AVAuthorizationStatusAuthorized) {
        return YES;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"录音权限未开启" message:@"未启用录音访问权限。请前往'设置'应用程序以启用位置权限。" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if([[UIApplication sharedApplication] canOpenURL:url]) {
            NSURL *url =[NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
    }]];
    return NO;
}

#pragma mark - implement methods

- (instancetype)init
{
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create("com.treehole.recordQueue", DISPATCH_QUEUE_SERIAL);
        _maxRecordSec = 60;
        _minRecordSec = 2;
    }
    return self;
}

#pragma mark - record

- (BOOL)startRecordWithFilePath:(NSString *)filePath{
    return [self startRecordWithFilePath:filePath settings:nil];
}

- (BOOL)startRecordWithFilePath:(NSString *)filePath settings:(NSDictionary *)settings{
    BOOL hasPrivacy = [ZHAudioRecord checkRecordPrivacy];
    if (!hasPrivacy) {
        return NO;
    }
    
    if (!settings) {
        settings = @{
            AVFormatIDKey:@(kAudioFormatMPEG4AAC),
            AVSampleRateKey: @(44100),
            AVNumberOfChannelsKey:@(1),
            AVEncoderAudioQualityKey:@(kAudioCodecQuality_Medium)
        };
    }
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    NSError *error;
    self.recorder = [[AVAudioRecorder alloc]initWithURL:[NSURL fileURLWithPath:filePath]
                                                 settings:settings
                                                    error:&error];
    if (error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecord:didErrored:)]) {
            [self.delegate audioRecord:self didErrored:error];
        }
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
        return NO;
    }
    [self.displayView show];
    
    self.recorder.delegate = self;
    self.recorder.meteringEnabled = YES;
    [self.recorder prepareToRecord];
    [self.recorder record];
    
    [self startTimer];
    return YES;
}

- (void)stopRecord{
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    
    [self.displayView dismiss];
    [self.recorder stop];
    [self stopTimer];
}

#pragma mark - timer

- (void)startTimer{
    __weak typeof(self) weakSelf = self;
    if (self.timer) {
        return;
    }
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.queue);
    dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(self.timer, ^{
        weakSelf.recordTime += 1;
        if ((weakSelf.recordTime / 10) == weakSelf.maxRecordSec) {
            [weakSelf stopRecord];
            return;
        }
        [weakSelf.recorder updateMeters];
        float averagePower = [weakSelf.recorder averagePowerForChannel:0];
        weakSelf.averagePower = averagePower;
        //设置
        float minDB = -60.0;
        float normalized = (averagePower < minDB) ? 0 : (averagePower - minDB) / (-minDB);
        NSArray *bands = [weakSelf generateFrequencyBandsWithAvgPower:normalized];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.displayView setFrequencyBands:bands];
            [weakSelf.displayView setRecordTime:(weakSelf.recordTime / 10)];
        });
    });
    dispatch_activate(self.timer);
}

- (void)stopTimer{
    self.recordTime = 0;
    if (!self.timer) {
        return;
    }
    dispatch_source_cancel(self.timer);
    self.timer = nil;
}

#pragma mark - privacy methods

- (NSArray <NSNumber *> *)generateFrequencyBandsWithAvgPower:(float)averagePower{
    NSMutableArray *bands = [NSMutableArray arrayWithCapacity:self.displayView.bandCount];
    for (NSInteger i = 0; i < self.displayView.bandCount; i++) {
        float randomFactor = 0.2 + (arc4random_uniform(100)/100.0) * 0.8; // 添加随机波动
        float bandValue = averagePower * randomFactor;
        [bands addObject:@(bandValue)];
    }
    NSArray *sortedArray = [self sortArrayWithLargestInMiddle:bands];
    return sortedArray;
}

- (NSArray<NSNumber *> *)sortArrayWithLargestInMiddle:(NSArray<NSNumber *> *)array{
    // 降序排序数组
    NSArray *sortedArray = [array sortedArrayUsingComparator:^NSComparisonResult(NSNumber *num1, NSNumber *num2) {
        return [num2 compare:num1]; // 降序排列
    }];
    
    if (sortedArray.count == 0) {
        return @[];
    }
    
    NSMutableArray *result = [NSMutableArray array];
    // 添加最大的元素作为初始元素
    [result addObject:sortedArray[0]];
    
    BOOL shouldInsertAtEnd = YES; // 控制插入方向，先向右（后端）
    for (NSInteger i = 1; i < sortedArray.count; i++) {
        NSNumber *number = sortedArray[i];
        if (shouldInsertAtEnd) {
            [result addObject:number]; // 插入到右端
        } else {
            [result insertObject:number atIndex:0]; // 插入到左端
        }
        shouldInsertAtEnd = !shouldInsertAtEnd; // 切换方向
    }
    return [result copy];
}

#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    ZHRecordFinishStatus status = [[NSFileManager defaultManager] fileExistsAtPath:recorder.url.path] ? ZHRecordFinishStatusSuccess : ZHRecordFinishStatusFailed;
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecord:didFinishRecordWithUrlPath:status:)]) {
        [self.delegate audioRecord:self didFinishRecordWithUrlPath:recorder.url.path status:status];
    }
}

#pragma mark - lazy

- (UIView<ZHDisplayViewProtocol> *)displayView{
    if (!_displayView) {
        _displayView = [ZHDisplayView new];
    }
    return _displayView;
}

@end

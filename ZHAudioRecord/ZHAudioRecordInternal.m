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
#import <Accelerate/Accelerate.h>

#define FFT_SIZE 1024

@interface ZHAudioRecord()<AVAudioRecorderDelegate>

@property (nonatomic,strong) AVAudioRecorder            *recorder;
@property (nonatomic,strong) AVAudioEngine              *engine;
@property (nonatomic, strong) AVAudioInputNode          *inputNode;

@property (nonatomic) dispatch_source_t                 timer;
@property (nonatomic,assign) NSInteger                  recordTime;
@property (nonatomic) dispatch_queue_t                  queue;

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
        _recordType = ZHAudioRecordTypeNormal;
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
    
    if (self.recordType == ZHAudioRecordTypeNormal) {
        BOOL record = [self setupRecorderWithFilePath:filePath settings:settings];
        if (!record) {
            [[AVAudioSession sharedInstance] setActive:NO error:nil];
            return NO;
        }
    }else{
        [self setupEngineWithFilePath:filePath settings:settings];
    }
    
    [self startTimer];
    [self.displayView show];
    return YES;
}

- (void)stopRecord{
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    if (self.recordType == ZHAudioRecordTypeNormal) {
        [self.recorder stop];
    }else{
        [self.engine stop];
    }
    [self.displayView dismiss];
    [self stopTimer];
}

#pragma mark - setup


- (BOOL)setupRecorderWithFilePath:(NSString *)filePath settings:(NSDictionary *)settings{
    NSError *error;
    self.recorder = [[AVAudioRecorder alloc]initWithURL:[NSURL fileURLWithPath:filePath]
                                                 settings:settings
                                                    error:&error];
    if (error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecord:didErrored:)]) {
            [self.delegate audioRecord:self didErrored:error];
        }
        return NO;
    }
    
    self.recorder.delegate = self;
    self.recorder.meteringEnabled = YES;
    [self.recorder prepareToRecord];
    [self.recorder record];
    return YES;
}

- (BOOL)setupEngineWithFilePath:(NSString *)filePath settings:(NSDictionary *)settings{
    __weak typeof(self) weakSelf = self;
    self.engine = [[AVAudioEngine alloc] init];
    self.inputNode = self.engine.inputNode;
    
    AVAudioFormat *format = [self.inputNode inputFormatForBus:0];
    [self.inputNode installTapOnBus:0 bufferSize:1024 format:format block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        NSArray *bands = [self processAudioBuffer:buffer];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.displayView setFrequencyBands:bands];
        });
    }];
    
    NSError *error = nil;
    [self.engine startAndReturnError:&error];
    if (error) {
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
        return NO;
    }
    return YES;
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
        if (weakSelf.recordType == ZHAudioRecordTypeNormal) {
            [weakSelf.recorder updateMeters];
            float averagePower = [weakSelf.recorder averagePowerForChannel:0];
            //设置
            float minDB = -60.0;
            float normalized = (averagePower < minDB) ? 0 : (averagePower - minDB) / (-minDB);
            NSArray *bands = [weakSelf generateFrequencyBandsWithAvgPower:normalized];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [weakSelf.displayView setFrequencyBands:bands];
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
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

- (NSArray <NSNumber *> *)processAudioBuffer:(AVAudioPCMBuffer *)buffer {
    float *audioData = buffer.floatChannelData[0];
    UInt32 frameLength = buffer.frameLength;
            
    // 对音频数据进行 FFT 或其他频谱分析
    NSArray *spectrum = [self performFFTOnAudioData:audioData frameLength:frameLength];
    return spectrum;
}

- (NSArray *)performFFTOnAudioData:(float *)audioData frameLength:(UInt32)frameLength {
    // 准备 FFT 输入和输出
    DSPSplitComplex splitComplex;
    splitComplex.realp = (float *)malloc(FFT_SIZE * sizeof(float));
    splitComplex.imagp = (float *)malloc(FFT_SIZE * sizeof(float));
    
    // 将音频数据复制到实部，虚部置零
    vDSP_ctoz((DSPComplex *)audioData, 2, &splitComplex, 1, FFT_SIZE);
    
    // 创建 FFT 设置
    vDSP_Length log2n = log2f(FFT_SIZE);
    FFTSetup fftSetup = vDSP_create_fftsetup(log2n, FFT_RADIX2);
    
    // 执行 FFT
    vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFT_FORWARD);
    
    // 计算幅度
    float magnitudes[FFT_SIZE / 2];
    vDSP_zvmags(&splitComplex, 1, magnitudes, 1, FFT_SIZE / 2);
    
    // 归一化幅度
    float normalizedMagnitudes[FFT_SIZE / 2];
    vDSP_vsmul(magnitudes, 1, &(float){2.0f / FFT_SIZE}, normalizedMagnitudes, 1, FFT_SIZE / 2);
    
    // 转换为 NSArray
    NSMutableArray *spectrum = [NSMutableArray arrayWithCapacity:FFT_SIZE / 2];
    for (UInt32 i = 0; i < FFT_SIZE / 2; i++) {
        NSLog(@"%f",normalizedMagnitudes[i]);
        [spectrum addObject:@(normalizedMagnitudes[i])];
    }
    // 释放内存
    free(splitComplex.realp);
    free(splitComplex.imagp);
    vDSP_destroy_fftsetup(fftSetup);
    
    return spectrum;
}


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
    if ((self.recordTime / 10) < self.minRecordSec) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:recorder.url.path]) {
            [[NSFileManager defaultManager] removeItemAtPath:recorder.url.path error:nil];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecord:didErrored:)]) {
            [self.delegate audioRecord:self didErrored:[NSError errorWithDomain:@"The recording duration is too short" code:999 userInfo:nil]];
        }
        return;
    }
    ZHRecordFinishStatus status = [[NSFileManager defaultManager] fileExistsAtPath:recorder.url.path] ? ZHRecordFinishStatusSuccess : ZHRecordFinishStatusFailed;
    if (status == ZHRecordFinishStatusSuccess) {
        status = self.displayView.isCancel ? ZHRecordFinishStatusCancel : ZHRecordFinishStatusSuccess;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecord:didFinishRecordWithUrlPath:duration:status:)]) {
        [self.delegate audioRecord:self didFinishRecordWithUrlPath:recorder.url.path duration:(self.recordTime / 10.0) status:status];
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

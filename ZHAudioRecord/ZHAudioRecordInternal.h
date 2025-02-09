//
//  ZHAudioRecordManager.h
//  ZHAudioRecordManager
//
//  Created by ZHL on 2025/2/8.
//  Copyright © 2025 ZHL. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "ZHDisplayViewProtocol.h"
#import <UIKit/UIKit.h>
@class ZHAudioRecord;

typedef enum : NSUInteger {
    ZHRecordFinishStatusSuccess,
    ZHRecordFinishStatusFailed,
    ZHRecordFinishStatusCancel,
} ZHRecordFinishStatus;

typedef enum : NSUInteger {
    ZHAudioRecordTypeNormal,
    ZHAudioRecordTypeEngine,
} ZHAudioRecordType;

NS_ASSUME_NONNULL_BEGIN

@protocol ZHAudioRecordDelegate <NSObject>

- (void)audioRecord:(ZHAudioRecord *)record didFinishRecordWithUrlPath:(NSString *)urlPath duration:(NSTimeInterval)duration status:(ZHRecordFinishStatus)status;

- (void)audioRecord:(ZHAudioRecord *)record didErrored:(NSError *)error;

@end


@interface ZHAudioRecord : NSObject

+ (instancetype)record;

@property (nonatomic,weak) id <ZHAudioRecordDelegate>                   delegate;
//开始录音默认遮罩
@property (nonatomic,strong,nullable) UIView  <ZHDisplayViewProtocol>   *displayView;
//最大录制时长，默认为60s
@property (nonatomic,assign) NSInteger                                  maxRecordSec;
//最小录制时长，默认2s
@property (nonatomic,assign) NSInteger                                  minRecordSec;
//录制方式，默认为normal AVRecorder
@property (nonatomic,assign) ZHAudioRecordType                          recordType;

- (BOOL)startRecordWithFilePath:(NSString *)filePath;

- (BOOL)startRecordWithFilePath:(NSString *)filePath settings:(NSDictionary * _Nullable)settings;

- (void)stopRecord;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

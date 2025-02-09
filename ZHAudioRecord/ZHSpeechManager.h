//
//  ZHSpeechManager.h
//  ZHAudioRecord
//
//  Created by ZHL on 2025/2/10.
//

#import <Foundation/Foundation.h>
@class AVAudioPCMBuffer ,ZHSpeechManager;

NS_ASSUME_NONNULL_BEGIN

@protocol ZHSpeechManagerDelegate <NSObject>

- (void)speechManager:(ZHSpeechManager *)manager recognizingStr:(NSString *)str finish:(BOOL)finish;

@end

@interface ZHSpeechManager : NSObject

@property (nonatomic,weak) id <ZHSpeechManagerDelegate> delegate;

- (void)setupSpeechWithLocal:(NSLocale *)local;

- (void)appendAudioData:(AVAudioPCMBuffer *)buffer;

- (void)stopRecognize;

@end

NS_ASSUME_NONNULL_END

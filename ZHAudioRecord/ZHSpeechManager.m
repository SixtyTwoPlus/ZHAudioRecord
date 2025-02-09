//
//  ZHSpeechManager.m
//  ZHAudioRecord
//
//  Created by ZHL on 2025/2/10.
//

#import "ZHSpeechManager.h"
#import <Speech/Speech.h>

@interface ZHSpeechManager()

@property (nonatomic,strong) SFSpeechRecognizer                     *recognizer;
@property (nonatomic,strong) SFSpeechAudioBufferRecognitionRequest  *bufferRequest;

@end

@implementation ZHSpeechManager

- (void)setupSpeechWithLocal:(NSLocale *)local{
    __weak typeof(self) weakSelf = self;
    
    self.recognizer = [[SFSpeechRecognizer alloc]initWithLocale:local];
    self.bufferRequest = [[SFSpeechAudioBufferRecognitionRequest alloc]init];
    BOOL supportLocalRecognize = self.recognizer.supportsOnDeviceRecognition;
    self.bufferRequest.requiresOnDeviceRecognition = supportLocalRecognize;
    [self.recognizer recognitionTaskWithRequest:self.bufferRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        
        NSString *resultStr = result.bestTranscription.formattedString;
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(speechManager:recognizingStr:finish:)]) {
            [weakSelf.delegate speechManager:weakSelf recognizingStr:resultStr finish:result.final];
        }
    }];
}

- (void)appendAudioData:(AVAudioPCMBuffer *)buffer{
    if (!self.bufferRequest) {
        return;
    }
    [self.bufferRequest appendAudioPCMBuffer:buffer];
}

- (void)stopRecognize{
    if (!self.bufferRequest) {
        return;
    }
    [self.bufferRequest endAudio];
}

@end

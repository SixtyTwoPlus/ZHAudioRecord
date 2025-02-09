//
//  ZHDisplayViewProtocol.h
//  ZHAudioRecord
//
//  Created by ZHL on 2025/2/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZHDisplayViewProtocol <NSObject>

@required

@property (nonatomic,assign,readonly) BOOL          isCancel;

- (void)show;

- (void)dismiss;

- (void)upgradeGesturePoint:(CGPoint)point;

- (void)setFrequencyBands:(NSArray<NSNumber *> *)frequencyBands;

- (void)setRecordTime:(NSInteger)second;

- (NSInteger)bandCount;

@end

NS_ASSUME_NONNULL_END

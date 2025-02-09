//
//  ZHSpectrumView.h
//  ZHSpectrumView
//
//  Created by ZHL on 2025/2/8.
//  Copyright © 2025 ZHL. All rights reserved.
//


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZHSpectrumView : UIView

@property (nonatomic, assign) CGFloat               barWidth;
@property (nonatomic, strong) UIColor               *barColor;
@property (nonatomic, assign) CGFloat               spacing;
@property (nonatomic, assign,readonly) NSInteger    bandCount;
@property (nonatomic, copy) NSArray<NSNumber *>     *frequencyBands;

@end

NS_ASSUME_NONNULL_END

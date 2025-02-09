//
//  ZHSpectrumView.m
//  ZHSpectrumView
//
//  Created by ZHL on 2025/2/8.
//  Copyright © 2025 ZHL. All rights reserved.
//


#import "ZHSpectrumView.h"

@interface ZHSpectrumView()

@property (nonatomic, assign) NSInteger         bandCount;

@end

@implementation ZHSpectrumView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _barWidth = 3.0;
        _spacing = 2.0;
        _bandCount = frame.size.width / (_spacing + _barWidth);
        _barColor = [UIColor greenColor];
        self.backgroundColor = UIColor.clearColor;
    }
    return self;
}


#pragma mark - methods

- (void)setFrequencyBands:(NSArray<NSNumber *> *)frequencyBands {
    _frequencyBands = [frequencyBands copy];
    [UIView animateWithDuration:0.1 animations:^{
        [self setNeedsDisplay];
    }];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    CGContextSetFillColorWithColor(context, self.barColor.CGColor);
    
    CGFloat totalWidth = (self.barWidth + self.spacing) * self.bandCount - self.spacing;
    CGFloat startX = (rect.size.width - totalWidth) / 2.0;
    
    for (NSInteger i = 0; i < self.bandCount; i++) {
        CGFloat height = 0;
        if (i < self.frequencyBands.count) {
            height = [self.frequencyBands[i] floatValue] * rect.size.height;
        }
        CGRect barRect = CGRectMake(startX + i * (self.barWidth + self.spacing),
                                    (rect.size.height - height) / 2,
                                    self.barWidth,
                                    height);
        
        UIBezierPath *roundedRectPath = [UIBezierPath bezierPathWithRoundedRect:barRect
                                                              byRoundingCorners:UIRectCornerAllCorners
                                                                    cornerRadii:CGSizeMake(self.barWidth / 2, self.barWidth / 2)];
        [roundedRectPath fill]; // 使用fill方法填充
    }
}


@end

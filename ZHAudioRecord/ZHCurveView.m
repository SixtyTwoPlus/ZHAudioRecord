//
//  ZHCurveView.m
//  ZHCurveView
//
//  Created by ZHL on 2025/2/8.
//  Copyright © 2025 ZHL. All rights reserved.
//


#import "ZHCurveView.h"
#import "ZHAudioRecordMarco.h"

#define CURVE_HEIGHT 30

@implementation ZHCurveView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        _strokeColor = ZHRECORD_COLOR_HEX(0xD8D8D8);
        _fillColor = ZHRECORD_COLOR_HEX(0xF7F7F7);
    }
    return self;
}

#pragma mark - override


- (void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat mid = self.frame.size.width / 2;
    
    CGPoint startPoint = CGPointMake(0, CURVE_HEIGHT);
    CGPoint midPoint = CGPointMake(mid, 0);
    CGPoint endPoint = CGPointMake(width, CURVE_HEIGHT);
    
    [self.fillColor setStroke];
    [self.fillColor setFill];
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:startPoint];
    [bezierPath addCurveToPoint:endPoint controlPoint1:midPoint controlPoint2:midPoint];
    [bezierPath addLineToPoint:CGPointMake(width, height)];
    [bezierPath addLineToPoint:CGPointMake(0, height)];
    [bezierPath closePath];
    [bezierPath fill];
    [bezierPath stroke];
    
    [self.strokeColor setStroke];
    UIBezierPath *bezierPath2 = [UIBezierPath bezierPath];
    [bezierPath2 moveToPoint:startPoint];
    [bezierPath2 addCurveToPoint:endPoint controlPoint1:midPoint controlPoint2:midPoint];
    bezierPath2.lineWidth = 2;
    [bezierPath2 stroke];
}

@end

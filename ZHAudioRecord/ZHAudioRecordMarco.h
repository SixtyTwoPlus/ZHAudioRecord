//
//  ZHAudioRecordMarco.h
//  ZHAudioRecord
//
//  Created by ZHL on 2025/2/8.
//

#ifndef ZHAudioRecordMarco_h
#define ZHAudioRecordMarco_h

#define ZHRECORD_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define ZHRECORD_HEIGHT ([UIScreen mainScreen].bounds.size.height)

#define ZHRECORD_COLOR_HEX(s) [UIColor colorWithRed:(((s & 0xFF0000) >> 16))/255.0 green:(((s & 0xFF00) >> 8))/255.0 blue:((s & 0xFF))/255.0  alpha:1.0]
#define ZHRECORD_COLOR_HEX_ALPHA(s,a) [UIColor colorWithRed:(((s & 0xFF0000) >> 16))/255.0 green:(((s & 0xFF00) >> 8))/255.0 blue:((s & 0xFF))/255.0  alpha:a]

#endif /* ZHAudioRecordMarco_h */

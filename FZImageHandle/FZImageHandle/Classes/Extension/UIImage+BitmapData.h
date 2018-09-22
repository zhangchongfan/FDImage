//
//  UIImage+BitmapData.h
//  FZImageHandle
//
//  Created by 张冲 on 2018/8/22.
//  Copyright © 2018年 zhangchong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (BitmapData)

- (NSData *)bitmapData;
- (NSData *)bitmapFileHeaderData;
- (NSData *)bitmapDataWithFileHeader;

@end

//
//  UIImage+BitmapData.m
//  FZImageHandle
//
//  Created by 张冲 on 2018/8/22.
//  Copyright © 2018年 zhangchong. All rights reserved.
//
/*
 https://stackoverflow.com/questions/23405609/how-to-convert-png-jpeg-to-bmp-in-ios
 https://www.cnblogs.com/ZXNblog/p/4046342.html
 https://blog.csdn.net/man9953211/article/details/51890216
 */

#import "UIImage+BitmapData.h"

# pragma pack(push, 1)
typedef struct s_bitmap_header
{
    // Bitmap file header
    UInt16 fileType;
    UInt32 fileSize;
    UInt16 reserved1;
    UInt16 reserved2;
    UInt32 bitmapOffset;
    
    // DIB Header
    UInt32 headerSize;
    UInt32 width;
    UInt32 height;
    UInt16 colorPlanes;
    UInt16 bitsPerPixel;
    UInt32 compression;
    UInt32 bitmapSize;
    UInt32 horizontalResolution;
    UInt32 verticalResolution;
    UInt32 colorsUsed;
    UInt32 colorsImportant;
} t_bitmap_header;
#pragma pack(pop)

@implementation UIImage (BitmapData)

- (NSData *)bitmapData {
    NSData          *bitmapData = nil;
    CGImageRef      image = self.CGImage;
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    UInt8           *rawData;
    
    size_t bitsPerPixel = 32;
    size_t bitsPerComponent = 8;
//    size_t bytesPerPixel = bitsPerPixel / bitsPerComponent;
    
    size_t bytesPerPixel = 4;
    
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    size_t bytesPerRow = width * bytesPerPixel;
    size_t bufferLength = bytesPerRow * height;
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (colorSpace)
    {
        // Allocate memory for raw image data
        rawData = (UInt8 *)calloc(bufferLength, sizeof(UInt8));
        
        if (rawData)
        {
            CGBitmapInfo bitmapInfo = kCGImageByteOrder32Little | kCGImageAlphaPremultipliedLast;
            context = CGBitmapContextCreate(rawData,
                                            width,
                                            height,
                                            bitsPerComponent,
                                            bytesPerRow,
                                            colorSpace,
                                            bitmapInfo);
           
            if (context)
            {
                CGRect rect = CGRectMake(0, 0, width, height);
                
                CGContextTranslateCTM(context, 0, height);
                CGContextScaleCTM(context, 1.0, -1.0);
                CGContextDrawImage(context, rect, image);
                
                bitmapData = [NSData dataWithBytes:rawData length:bufferLength];
                
                CGContextRelease(context);
            }
            
            free(rawData);
        }
        
        CGColorSpaceRelease(colorSpace);
    }
    
    return bitmapData;
}

- (NSData *)bitmapFileHeaderData
{
    CGImageRef image = self.CGImage;
    UInt32 width = (UInt32)CGImageGetWidth(image);
    UInt32 height = (UInt32)CGImageGetHeight(image);
    
    t_bitmap_header header;
    
    header.fileType = 0x4D42;
    header.fileSize = (height * width * 3) + 54;
    header.reserved1 = 0x0000;
    header.reserved2 = 0x0000;
    header.bitmapOffset = 0x00000036;
    
    header.headerSize = 40;
    header.width = width;
    header.height = height;
    header.colorPlanes = 0x0001;
    header.bitsPerPixel = 24;
    header.compression = 0x00000000;
//    header.bitmapSize = height * width * 4;
    header.bitmapSize = 0;
    header.horizontalResolution = 0x00000B13;
    header.verticalResolution = 0x00000B13;
    header.colorsUsed = 0x00000000;
    header.colorsImportant = 0x00000000;
    
    return [NSData dataWithBytes:&header length:sizeof(t_bitmap_header)];
}

- (NSData *)bitmapDataWithFileHeader
{
    NSMutableData *data = [NSMutableData dataWithData:[self bitmapFileHeaderData]];
    NSData *imageData = [self bitmapData];
    NSData *changeData = [self convertBitmap_24bit_dataWithBitmap_32bit_data:imageData];
    [data appendData:changeData];
    return data;
}

/**
 *获取由32位的BMP位图NSData数据转换得到24位的BMP位图NSData数据
 */
- (NSData *)convertBitmap_24bit_dataWithBitmap_32bit_data:(NSData*)bitmap_32bit_data {
    if(bitmap_32bit_data ==nil) {
        return nil;
    }
    NSMutableData *bitmap_24bit_mdata = [NSMutableData data];
    const unsigned char *p = [bitmap_32bit_data bytes];
    for(int i = 0; i < [bitmap_32bit_data length]; i++) {
        if((i % 4) != 0) {
            int value = p[i];
            [bitmap_24bit_mdata appendBytes:&value length:1];
        }
    }
    return bitmap_24bit_mdata;
}

/**
 *获取由32位的BMP位图NSData数据转换得到16位的BMP位图NSData数据
 */
- (NSData *)convertBitmap_16bit_dataWithBitmap_32bit_data:(NSData*)bitmap_32bit_data {
    if(bitmap_32bit_data ==nil) {
        return nil;
    }
    NSMutableData *bitmap_16bit_mdata = [NSMutableData data];
    const unsigned char *p = [bitmap_32bit_data bytes];
    int value = 0;
    for(int i = 0; i < [bitmap_32bit_data length]; i++) {
        if (i % 4 == 0) {
            if (i != 0) {
                [bitmap_16bit_mdata appendBytes:&value length:2];
            }
        }else if (i % 4 == 1) {//R
            int r = p[i] >> 3 ;
            value = r;
        }else if (i % 4 == 2) {//G
            int g = p[i] >> 2;
            value = value | (g << 5);
        }else if (i % 4 == 3) {//B
            int b = p[i] >> 3;
            value = (b << 11) | value ;
            if (i == bitmap_32bit_data.length - 1) {
                [bitmap_16bit_mdata appendBytes:&value length:2];
            }
        }
    }
    return bitmap_16bit_mdata;
}


@end


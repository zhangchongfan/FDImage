//
//  GZImageFormatChange.m
//  FZImageHandle
//
//  Created by 张冲 on 2018/8/22.
//  Copyright © 2018年 zhangchong. All rights reserved.
//

#import "GZImageFormatChange.h"

@implementation GZImageFormatChange

+ (instancetype)share {
    static GZImageFormatChange *imageHandle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageHandle = [[GZImageFormatChange alloc]init];
    });
    return imageHandle;
}

- (NSString *)docPath
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

-(void)saveToBMP:(UIImage*)editedImage andSaveFileName:(NSString *)fileName
{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *ImageCachePath = [[self docPath]stringByAppendingPathComponent:@"bmp"];
    if ([fileManager fileExistsAtPath:ImageCachePath])//判断目录是否存在
    {
        
    }
    else
    {
        [fileManager createDirectoryAtPath:ImageCachePath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    NSString *fileInCachePath = [ImageCachePath stringByAppendingPathComponent:fileName];
    [fileManager createFileAtPath:fileInCachePath contents:nil attributes:nil];
    int nWidth = editedImage.size.width;
    int nHeight = editedImage.size.height;
    
    int bufferSize = nHeight * (nWidth * 3 + nWidth % 4);
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:fileInCachePath];
    //bmp文件头
    int bfType = 0x4d42;
    int bfSize = 14 + 40 + bufferSize;
    int bfReserved1 = 0;
    int bfReserved2 = 0;
    int bfOffBits = 14 + 40;
//    int bfOffBits = 14+40+4*pow(2, 16);
    [self writeWord:fileHandle value:bfType];
    [self writeDword:fileHandle value:bfSize];
    [self writeWord:fileHandle value:bfReserved1];
    [self writeWord:fileHandle value:bfReserved2];
    [self writeDword:fileHandle value:bfOffBits];
    //bmp信息头
    long biSize = 40L;
    long biWidth = nWidth;
    long biHeight = nHeight;
    int biPlanes = 1;
    int biBitCount = 24; //这里是改色身位
    long biCompression = 0L;
//    long biSizeImage = 0L;
    long biSizeImage = (biWidth*biBitCount+31)/32*4*biHeight;
//    long biXpelsPerMeter = 0L;
//    long biYPelsPerMeter = 0L;
    long biXpelsPerMeter = 4000L;
    long biYPelsPerMeter = 4000L;
    long biClrUsed = 0L;
    long biClrImportant = 0L;
    [self writeDword:fileHandle value:biSize];
    [self writeLong:fileHandle value:biWidth];
    [self writeLong:fileHandle value:biHeight];
    [self writeWord:fileHandle value:biPlanes];
    [self writeWord:fileHandle value:biBitCount];
    [self writeDword:fileHandle value:biCompression];
    [self writeDword:fileHandle value:biSizeImage];
    [self writeLong:fileHandle value:biXpelsPerMeter];
    [self writeLong:fileHandle value:biYPelsPerMeter];
    [self writeDword:fileHandle value:biClrUsed];
    [self writeDword:fileHandle value:biClrImportant];
    
    Byte bmpData[bufferSize];
    int wWidth = (nWidth * 3 + nHeight % 4);
    
    
    for (int nCol = 0, nRealCol = nWidth - 1; nCol < nWidth; ++nCol, --nRealCol)
        for (int wRow = 0, wByteIdex = 0; wRow < nHeight; wRow++, wByteIdex += 4) {
            CGImageRef inImage = editedImage.CGImage;
            CGContextRef cgctx = [self createARGBBitmapContextFromImage:inImage];
            CGPoint point = CGPointMake(wRow, nCol);
            if (cgctx == NULL) { return;  }
            size_t w = CGImageGetWidth(inImage);
            size_t h = CGImageGetHeight(inImage);
            CGRect rect = {{0,0},{w,h}};
            CGContextDrawImage(cgctx, rect, inImage);
            unsigned char* data = CGBitmapContextGetData (cgctx);
            if (data != NULL) {
                @try {
                    int offset = 4*((w*round(point.y))+round(point.x));
                    int red =  data[offset];
                    int green = data[offset+1];
                    int blue = data[offset+2];
                    int alpha = data[offset+3]; //透明度 值始终为255
                    bmpData[nRealCol * wWidth + wByteIdex] = (Byte) red;
                    bmpData[nRealCol * wWidth + wByteIdex + 1] = (Byte) green;
                    bmpData[nRealCol * wWidth + wByteIdex + 2] = (Byte) blue;
                    bmpData[nRealCol * wWidth + wByteIdex + 3] = (Byte) alpha;
                }
                @catch (NSException * e) {
                    NSLog(@"出现错误");
                }
                
            }
            CGContextRelease(cgctx);
            if (data) { free(data); }
        }
    
    NSData *colorData = [[NSData alloc] initWithBytes:bmpData length:bufferSize];
    [fileHandle writeData:colorData];
    [fileHandle closeFile];
}

-(void)writeWord:(NSFileHandle *) handle value : (int) value{
    Byte byte[] = {value & 0xff , value >>8 & 0xff};
    NSData *data = [[NSData alloc] initWithBytes:byte length:2];
    [handle writeData:data];
}

-(void)writeDword:(NSFileHandle *) handle value : (long) value{
    Byte byte[] = {value & 0xff , value >>8 & 0xff ,value >>16 & 0xff,value >>24 & 0xff};
    NSData *data = [[NSData alloc] initWithBytes:byte length:4];
    [handle writeData:data];
}

-(void)writeLong:(NSFileHandle *) handle value : (long) value{
    Byte byte[] = {value & 0xff , value >>8 & 0xff ,value >>16 & 0xff,value >>24 & 0xff};
    NSData *data = [[NSData alloc] initWithBytes:byte length:4];
    [handle writeData:data];
}

- (CGContextRef)createARGBBitmapContextFromImage:(CGImageRef)inImage
{
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    void *bitmapData;
    unsigned long bitmapByteCount;
    unsigned long bitmapBytesPerRow;
    
    // Get image width, height. We'll use the entire image.
    size_t pixelsWide = CGImageGetWidth(inImage);
    size_t pixelsHigh = CGImageGetHeight(inImage);
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow   = (pixelsWide * 4);
    bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
    
    // Use the generic RGB color space.
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (colorSpace == NULL)
    {
        fprintf(stderr,"Error allocating color space\n");
        return NULL;
    }
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = malloc(bitmapByteCount);
    if (bitmapData == NULL)
    {
        fprintf(stderr,"Memory not allocated!");
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    context = CGBitmapContextCreate(bitmapData,
                                    pixelsWide,
                                    pixelsHigh,
                                    8,   // bits per component
                                    bitmapBytesPerRow,
                                    colorSpace,
                                    kCGImageAlphaPremultipliedLast);
    if (context == NULL)
    {
        free(bitmapData);
        fprintf(stderr,"Context not created!");
    }
    
    // Make sure and release colorspace before returning
    CGColorSpaceRelease(colorSpace);
    
    return context;
}


- (void)testFor {
    
    for (int nCol = 0, nRealCol = 5 - 1; nCol < 5; ++nCol, --nRealCol)
        for (int wRow = 0, wByteIdex = 0; wRow < 5; wRow++, wByteIdex += 3) {
            
        }
}




@end

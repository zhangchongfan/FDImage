//
//  ImageEditViewController.h
//  FileLibraryDemo
//
//  Created by 肖兆强 on 2017/6/10.
//  Copyright © 2017年 jwzt. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ImageEditViewController : UIViewController


@property (copy,nonatomic) NSString *imagePath;

@property (nonatomic, strong) UIImage *selectImage;

@property (nonatomic, copy) void(^SaveBlock)(NSData *editImageData, UIImage *editImage);

@end

//
//  PhotoDetailViewController.m
//  WYPHealthyThird
//
//  Created by bbigcd on 16/11/11.
//  Copyright © 2016年 veepoo. All rights reserved.
//

#import "PhotoDetailViewController.h"
#import "ImageEditViewController.h"
#import "iCarousel.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import "UIImage+BitmapData.h"
#import "GZImageFormatChange.h"
#import "FZImageHandle-Swift.h"
//#import "UIView+SetRect.h"
#define ScreenHeight [UIScreen mainScreen].bounds.size.height
#define ScreenWidth [UIScreen mainScreen].bounds.size.width

@interface PhotoDetailViewController ()<iCarouselDelegate,iCarouselDataSource,UIAlertViewDelegate>

{
    iCarousel *_icarousel;
    int i;
    BOOL transform;
}
@property (nonatomic, strong) FDInternalTransformModel *internalModel;

@property (nonatomic, strong) UIImageView *showImageView;

@property (nonatomic, strong) NSData *editBmpData;

@property (nonatomic, strong) FDBleManage *bleManager;

@property (nonatomic, strong) UILabel *stateLabel;

@end

@implementation PhotoDetailViewController


- (void)viewDidLoad {
    self.bleManager = [FDBleManage shareManager];
    self.internalModel = [FDInternalTransformModel lastSettingModel];
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor colorWithHue:0.00 saturation:0.00 brightness:0.97 alpha:1.00]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.assetsFetchResults.count == 0) {
            [self getAllPictures];
        }
    });
    [self setViewControllerUI];
    [self configBleManager];
}

- (void)setViewControllerUI {
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:215/255.0 green:234/255.0 blue:144/255.0 alpha:1];
    UILabel *leftItemLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 150, 25)];
    leftItemLabel.text = @"● The Badger";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:leftItemLabel];
    
    UIButton *rightItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    rightItemBtn.frame = CGRectMake(0, 0, 20, 30);
    rightItemBtn.contentMode = UIViewContentModeRight;
    [rightItemBtn addTarget:self action:@selector(rigthItemAction) forControlEvents:UIControlEventTouchUpInside];
    [rightItemBtn setImage:[UIImage imageNamed:@"navi_more_item"] forState:UIControlStateNormal];
    //    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"navi_more_item"] style:UIBarButtonItemStylePlain target:self action:@selector(rightItemAction)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:rightItemBtn];
    CGFloat naviHeight = [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.bounds.size.height;
    self.showImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, naviHeight, ScreenWidth, 250)];
    self.showImageView.contentMode = UIViewContentModeScaleAspectFit;
    //    self.showImageView.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.showImageView];
    
    _icarousel = [[iCarousel alloc] init];
//    [_icarousel setFrame:CGRectMake(0, self.showImageView.bottom, ScreenWidth, 150)];
    [_icarousel setFrame:CGRectMake(0, 250 + naviHeight, ScreenWidth, 150)];
    _icarousel.backgroundColor = [UIColor colorWithRed:215/255.0 green:234/255.0 blue:144/255.0 alpha:1];
    _icarousel.delegate = self;
    _icarousel.dataSource = self;
    _icarousel.type = iCarouselTypeLinear;
    _icarousel.pagingEnabled = YES;
    _icarousel.scrollEnabled = YES;
    [self.view addSubview:_icarousel];
    
    UIView *bottomView = [[UIView alloc]initWithFrame:CGRectMake(0, 250 + naviHeight + 150, ScreenWidth, ScreenHeight - (250 + naviHeight + 150))];
    bottomView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:200/255.0 alpha:1];
    [self.view addSubview:bottomView];
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 30, ScreenWidth, 60)];
    if (@available(iOS 8.2, *)) {
        label.font = [UIFont systemFontOfSize:22 weight:2];
    } else {
        // Fallback on earlier versions
    }
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.text = @"SEARCH\nGIF";
    [bottomView addSubview:label];
    
    UIButton *bottomBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    bottomBtn.frame = CGRectMake(0, 0, 150, 50);
    bottomBtn.center = CGPointMake(bottomView.frame.size.width/2, bottomView.frame.size.height/2 + 30);
    [bottomBtn setBackgroundColor:[UIColor colorWithRed:215/255.0 green:234/255.0 blue:144/255.0 alpha:1]];
    [bottomBtn setTitle:@"BADGERISE" forState:UIControlStateNormal];
    [bottomBtn addTarget:self action:@selector(enterInternalController) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:bottomBtn];
    
    _stateLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, self.view.bounds.size.height - 30, self.view.bounds.size.width, 30)];
    _stateLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_stateLabel];
}

- (void)configBleManager {
    [self.bleManager setBleDidUpdateState:^(PhoneBleState bleState) {
        switch (bleState) {
            case PhoneBleStatePoweredOn:
                NSLog(@"手机蓝牙开启");
                break;
            case PhoneBleStatePoweredOff:
                NSLog(@"手机蓝牙关闭");
                break;
            default:
                break;
        }
    }];

    __weak typeof(self) weakSelf = self;
    [self.bleManager setBleConnectState:^(ConnectState connectState) {
        switch (connectState) {
            case ConnectStateConnected:
                NSLog(@"连接成功");
                if (self.navigationController.childViewControllers.count > 1) {
                    [weakSelf.navigationController popToRootViewControllerAnimated:YES];
                }
                break;
            case ConnectStateFoundService:
                NSLog(@"发现服务");
                break;
            case ConnectStateConnectFailure:
                NSLog(@"连接失败");
                //连接失败
                //self?.disconnected()
                break;
            case ConnectStatePoweredOff:
                NSLog(@"手机蓝牙没打开");
                break;
            case ConnectStateDisconnected:
                NSLog(@"蓝牙断开");
                weakSelf.stateLabel.text = @"蓝牙已断开连接";
                //self?.disconnected()
                break;
            default:
                break;
        }
    }];
    
    [self.bleManager setReceivePeripheralDataUpdate:^(NSData *data) {
        const uint8_t *tbyte = data.bytes;
        if (tbyte[0] == 0xA1 && tbyte[1] == 0x01) {
            //开始传输
        }else {
            
        }
    }];
}

- (void)getAllPictures{
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    self.assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
    //相册读写的状态
    PHAuthorizationStatus photoAuthStatus = [PHPhotoLibrary authorizationStatus];
    if(photoAuthStatus != PHAuthorizationStatusAuthorized) {//相机或相册权限未打开
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self getAllPictures];
        });
    }else {
        [_icarousel reloadData];
    }
}

- (void)rightItemAction {
    
}

//处理数据
- (void)handleEditImageData:(NSData *)imageData andEidtImage:(UIImage *)editImage {
    NSData *data = [editImage bitmapDataWithFileHeader];
    self.showImageView.image = [UIImage imageWithData:data];
    NSString *savePath = [[GZImageFormatChange share]docPath];
    NSString *save = [NSString stringWithFormat:@"%@/test.png",savePath];
    savePath = [NSString stringWithFormat:@"%@/test.bmp",savePath];
    [data writeToFile:savePath atomically:YES];
    [imageData writeToFile:save atomically:YES];
    self.editBmpData = data;
    i = 0;
    transform = YES;
//    [self.bleManager writeValueWithData:[FDDataHandle transformImageDataWithStart:YES]];
    [self performSelector:@selector(startTransformData) withObject:nil afterDelay:1.0];
}

- (void)startTransformData {
    if (!transform) {
        return;
    }
    int rate = self.internalModel.speed / 1000.0;
    int byteCount = self.internalModel.byteCount;
    NSUInteger length = self.editBmpData.length;
    unsigned long count = (length % byteCount == 0) ? length / byteCount : length / byteCount + 1;
    NSUInteger rangeLength = byteCount;
    if (i == count - 1) {
        rangeLength = length - i * byteCount;
    }
    NSRange range = NSMakeRange(i * byteCount, rangeLength);
    NSData *sendData = [self.editBmpData subdataWithRange:range];
    NSLog(@"send:%@, length: %d, i: %d",sendData, length, i);
    [self.bleManager transformMassiveDataWithData:sendData];
    i++;
    _stateLabel.text = [NSString stringWithFormat:@"正在传输:%d%%",i*100 / count];
    if (i < count) {
        [self performSelector:@selector(startTransformData) withObject:nil afterDelay:rate];
    }else {
        _stateLabel.text = @"传输完成";
        NSLog(@"传输完成");
        transform = NO;
    }
}

- (void)enterInternalController {
    FDInternalController *vc = [[FDInternalController alloc]initWithNibName:@"FDInternalController" bundle:NSBundle.mainBundle];
    vc.model = self.internalModel;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)rigthItemAction {
    if (self.bleManager.connected) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"提示" message:[NSString stringWithFormat:@"%@已经连接，是否断开？",self.bleManager.connectPeripherModel.name] delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"断开", nil];
        [alertView show];
    }else {
        FDScanViewController *scanController = [[FDScanViewController alloc]initWithNibName:@"FDScanViewController" bundle:NSBundle.mainBundle];
        [self.navigationController pushViewController:scanController animated:YES];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self.bleManager disconnectPeripheral];
    }
}

#pragma mark --iCarouselDelegate--
/** 允许滚动 */
- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value{
    if (option == iCarouselOptionWrap) {
        return YES;
    }
    //    else if (option == iCarouselOptionSpacing){
    //        return 10;
    //    }
    return value;
    
}

/** 滚动到第几个 */
- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel{
    NSInteger index = carousel.currentItemIndex;
    if (index >= 0) {
        PHAsset *asset = self.assetsFetchResults[index];
        __weak typeof(self) weakSelf = self;
        [[PHImageManager defaultManager]requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            weakSelf.showImageView.image = result;
        }];
    }
}

#pragma mark --iCarouselDataSource--

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel{
    return self.assetsFetchResults.count;
}

// 最大有多少个可以显示
- (NSUInteger)numberOfVisibleItemsInCarousel:(iCarousel *)carousel{
    return 5;
}

- (CGFloat)carouselItemWidth:(iCarousel *)carousel {
    return 110;
    //    return ceil([UIScreen mainScreen].bounds.size.width / 2);
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(nullable UIView *)view{
    // 由于view只有一个superview,此处用tag来解决重用问题
    view = (UIImageView *)[view viewWithTag:1];
    if (view == nil) {
        view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 140)];
        view.center = CGPointMake(carousel.frame.size.width/2, carousel.frame.size.height/2);
        view.tag = 1;
        ((UIImageView *)view).contentMode = UIViewContentModeScaleAspectFit;
        view.layer.borderWidth = 2;
        view.layer.borderColor = [UIColor darkGrayColor].CGColor;
        ((UIImageView *)view).clipsToBounds = YES;
    }
    PHAsset *asset = self.assetsFetchResults[index];
    [[PHImageManager defaultManager]requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        ((UIImageView *)view).image = result;
    }];
    return view;
}

- (void)carousel:(__unused iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index {
    PHAsset *asset = self.assetsFetchResults[index];
    __weak typeof(self) weakSelf = self;
    [[PHImageManager defaultManager]requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        [weakSelf enterEditorWithImage:result];
    }];
    NSLog(@"Tapped view number: %ld", (long)index);
}

//进入图片编辑界面
- (void)enterEditorWithImage:(UIImage *)image {
    if (self.bleManager.connected == false) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"提示" message:@"蓝牙未连接，请先连接设备" delegate:nil cancelButtonTitle:@"我知道了" otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    ImageEditViewController *vc = [[ImageEditViewController alloc]init];
    vc.selectImage = image;
    __weak typeof(self) weakSelf = self;
    [vc setSaveBlock:^(NSData *editImageData, UIImage *editImage) {
        [weakSelf handleEditImageData:editImageData andEidtImage:editImage];
    }];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)dealloc{
    _icarousel = nil;
}

@end

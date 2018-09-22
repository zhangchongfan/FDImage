//
//  Test.c
//  FZImageHandle
//
//  Created by 张冲 on 2018/8/30.
//  Copyright © 2018年 zhangchong. All rights reserved.
//

#include "Test.h"

/**
 
 *获取由32位的BMP位图NSData数据转换得到24位的BMP位图NSData数据
 
 *在子线程执行任务，执行完后使用block回调
 
 *
 
 *
 
 *特别说明：传进来的参数和返回的数据都是不包括位图的头部文件Bitmap file header的
 
 *我这里是根据硬件那边的需要，已经把格式规定死了，是一个width*height->480*800大小的BMP图片
 
 *这个方法是使用block的回到
 
 *
 
 *@param bitmap_32bit_data32位的BMP位图NSData数据
 
 *@param ConvertBitmapBlock 24位的BMP位图NSData数据
 
 *
 
 *
 
 *实例：
 
 *32位的一个像素点数值是：123150ff --->传入参数
 
 *去掉alpha值后得到24位的一个像素点，其数值是：123150
 
 *然后将得到的24位像素点的数值转换成需要发送的数据类型即NSData类型
 
 *NSData里面的bytes存储的就是“123150”这个字符串每个数字对应的ASCII码49 50 51 49 53 48
 
 *的十六进制数31 32 33 31 35 30。
 
 */



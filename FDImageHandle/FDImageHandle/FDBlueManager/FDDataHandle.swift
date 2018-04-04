//
//  FDDataHandle.swift
//  FDCarCover
//
//  Created by 张冲 on 2018/1/23.
//  Copyright © 2018年 zhangchong. All rights reserved.
//

import UIKit

class FDDataHandle: NSObject {
    
    static func transformImageData(start: Bool) -> Data {
        var tbyte:[UInt8] = Array(repeatElement(0x00, count: 20))
        tbyte[0] = 0xA1
        tbyte[1] = start ? 0x01 : 0x00
        return Data(bytes: tbyte, count: tbyte.count)
    }
    
}

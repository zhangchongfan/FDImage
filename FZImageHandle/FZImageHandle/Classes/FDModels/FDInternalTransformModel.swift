//
//  FDInternalTransformModel.swift
//  FZImageHandle
//
//  Created by 张冲 on 2018/9/9.
//  Copyright © 2018年 zhangchong. All rights reserved.
//

import UIKit

@objc class FDInternalTransformModel: NSObject {

    @objc var speed: Int = 5
    @objc var byteCount: Int = 20
    
    @objc static func lastSettingModel() -> FDInternalTransformModel {
        let model = FDInternalTransformModel()
        let lastSpeed = UserDefaults.standard.integer(forKey: "FDLastSpeed")
        let lastByteCount = UserDefaults.standard.integer(forKey: "FDLastByteCount")
        if lastByteCount != 0 && lastSpeed != 0 {
            model.speed = lastSpeed
            model.byteCount = lastByteCount
        }
        return model;
    }
    
    @objc func saveSettingModel(){
        UserDefaults.standard.set(self.speed, forKey: "FDLastSpeed")
        UserDefaults.standard.set(self.byteCount, forKey: "FDLastByteCount")
        UserDefaults.standard.synchronize()
    }
    
}

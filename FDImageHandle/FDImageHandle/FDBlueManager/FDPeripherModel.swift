//
//  FDPeripherModel.swift
//  VPBluetoothTool
//
//  Created by 张冲 on 2017/12/20.
//  Copyright © 2017年 zhangchong. All rights reserved.
//

import UIKit
import CoreBluetooth

let PeripheralID = "PeripheralID"
let PeripheralName = "PeripheralName"
let PeripheralAuto = "PeripheralAuto"
let PeripheralInfo = "PeripheralInfo"

class FDPeripherModel: NSObject {
    
    var peripheral: CBPeripheral?
    
    var name: String = ""
    
    var address: String = ""
    
    var rssi: NSNumber?
    
    var manufacturerData: Data?
    
    init(peripheral: CBPeripheral,AdvertisementData advertisementData: [String : Any], RSSI rssi:NSNumber) {
        super.init()
        manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data
        self.peripheral = peripheral
        self.name = peripheral.name ?? ""
        self.rssi = rssi
        self.address = peripheral.identifier.uuidString
    }
    
    func savePeripheralMessage(autoConnect: Bool) {//存储基本的信息
        var infoDict: Dictionary<String,String> = [:]
        let peripheralID = address
        let peripheralName = name
        let autoConnectState = autoConnect ? "1" : "0"
        infoDict[PeripheralID] = peripheralID
        infoDict[PeripheralName] = peripheralName
        infoDict[PeripheralAuto] = autoConnectState
        UserDefaults.standard.set(infoDict, forKey: PeripheralInfo)
        UserDefaults.standard.synchronize()
    }
    
    class func notAutoConnect() {
        let lastConnectMessage = UserDefaults.standard.value(forKey: PeripheralInfo ) as? Dictionary<String, String>
        if let message = lastConnectMessage {
            var infoDict: Dictionary<String,String> = [:]
            infoDict[PeripheralID] = message[PeripheralID]
            infoDict[PeripheralName] = message[PeripheralName]
            infoDict[PeripheralAuto] = "0"
            UserDefaults.standard.set(infoDict, forKey: PeripheralInfo)
            UserDefaults.standard.synchronize()
        }
    }
    
    func lastConnectPeripheral() -> Bool {
        if let lastConnectPeripheralInfo = (UserDefaults.standard.value(forKey: PeripheralInfo) as? Dictionary<String, String>)  {
            let lastPeripheralID = lastConnectPeripheralInfo[PeripheralID]
            let autoConnectState = lastConnectPeripheralInfo[PeripheralAuto]
//            let lastPheralName = lastConnectPeripheralInfo[PeripheralName]
            if lastPeripheralID == address && (autoConnectState == "1") {//标志一样就是上次连接的设备,且自动重新连接
                return true
            }
        }
        return false
    }
    
    class func isScan() -> Bool {
        if let lastConnectPeripheralInfo = (UserDefaults.standard.value(forKey: PeripheralInfo) as? Dictionary<String, String>)  {
            let autoConnectState = lastConnectPeripheralInfo[PeripheralAuto]
            //            let lastPheralName = lastConnectPeripheralInfo[PeripheralName]
            if autoConnectState == "1" {//标志一样就是上次连接的设备,且自动重新连接
                return true
            }
        }
        return false
    }
    
}








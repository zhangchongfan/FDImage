//
//  FDBleManage.swift
//  VPBluetoothTool
//
//  Created by 张冲 on 2017/12/21.
//  Copyright © 2017年 zhangchong. All rights reserved.
//

import UIKit
import CoreBluetooth

//手机系统蓝牙状态
@objc enum PhoneBleState: Int {
    case unknown = 0
    case resetting
    case unsupported
    case unauthorized
    case poweredOff
    case poweredOn
}

@objc enum ConnectState: Int {
    case connected = 0//连接成功
    case connectFailure //连接失败
    case foundService //发现服务
    case notFoundService //未发现服务
    case disconnected //未发现服务
    case poweredOff //系统蓝牙没有开启
    case timeOut //连接超时
}
let serviceUUID = "FFD0"
let writeUUID = "FFD1"
let notifyUUID = "FFD2"
//let serviceUUID = "F0080001-0451-4000-B000-000000000000"
//let writeUUID = "F0080003-0451-4000-B000-000000000000"
//let notifyUUID = "F0080002-0451-4000-B000-000000000000"

let writeUUID1 = "FFD3"

//@objc protocol FDBleManagerDelegate: NSObjectProtocol {
//    func bleDidUpdateState() -> ()
//}

@objc class FDBleManage: NSObject {
    
    var centralManager: CBCentralManager?
    
    @objc var connectPeripherModel: FDPeripherModel?
    
    //系统蓝牙状态改变
    @objc var bleDidUpdateState: ((PhoneBleState) -> ())?
    
    //蓝牙连接状态改变
    @objc var bleConnectState: ((ConnectState) -> ())?
    
    //扫描回调
    @objc var scanResult: ((FDPeripherModel) -> ())?
    
    //接收到手环返回的数据回调
    @objc var receivePeripheralDataUpdate: ((Data) -> ())?
    
    @objc var connected = false //是否连接，只有连接成功并且发现指定的服务和特征才算连接
    
    @objc var autoConnect = true //是否自动重连，默认为true
    
    private var connectTimer: Timer?
    
    //单例
    @objc static let shareManager = FDBleManage.init()
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }

    func startScan(result:@escaping ((_ peripherModel: FDPeripherModel) -> ())) {//开始扫描
        scanResult = result
        let deviceUUID = CBUUID(string: serviceUUID)
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScan() {//停止扫描
        centralManager?.stopScan()
    }
    
    func connectPeripheral(peripheralModel: FDPeripherModel) {//开始连接设备
        if centralManager?.state != .poweredOn {//系统蓝牙未开启
            connectStateChange(connenctState: .poweredOff)
            return;
        }
        connectPeripherModel = peripheralModel
        stopScan()
        centralManager?.connect(peripheralModel.peripheral!, options: nil)
        //连接超时计时器
        if #available(iOS 10.0, *) {
            connectTimer = Timer(timeInterval: 10.0, repeats: false) { [weak self](timer) in
                self?.connectTimer?.invalidate()
                self?.connectTimer = nil
                self?.connectStateChange(connenctState: .timeOut)
                if peripheralModel.peripheral?.state == .connected {//如果连接就是没有找到服务，断开连接
                    self?.centralManager?.cancelPeripheralConnection(peripheralModel.peripheral!)
                }else {//没有连接上，连接超时
                    self?.centralManager?.cancelPeripheralConnection(peripheralModel.peripheral!)
                    self?.connectStateChange(connenctState: .timeOut)
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    @objc func disconnectPeripheral() {//断开连接，如果手动则不再自动重新连接
        if connectPeripherModel != nil {
           connectPeripherModel?.savePeripheralMessage(autoConnect: false)
            centralManager?.cancelPeripheralConnection((connectPeripherModel?.peripheral)!)
        }
    }
    
    func connectStateChange(connenctState: ConnectState) {//蓝牙连接状态发生改变
        if connenctState == .foundService {
            connectPeripherModel?.savePeripheralMessage(autoConnect: autoConnect)//连接成功后保存基本信息
            connected = true
        }else if connenctState == .connected {
            
        }else {
            connected = false
            connectPeripherModel = nil
            if FDPeripherModel.isScan() {//如果需要自动重新连接，则开始扫描
                centralManager?.scanForPeripherals(withServices: nil, options: nil)
            }
        }
        guard let bleConnectState = bleConnectState else {
            return
        }
        bleConnectState(connenctState)
    }
    
    @objc func writeValue(data: Data) {
        guard let model = connectPeripherModel else {
            return
        }
        if connected == false {
            return
        }
        for service in (model.peripheral?.services)! {
            if service.uuid.isEqual(CBUUID(string: serviceUUID)) {
                for characteristic in service.characteristics! {
                    if characteristic.uuid .isEqual(CBUUID(string: writeUUID)) {
                        model.peripheral?.writeValue(data, for: characteristic, type: .withResponse)
                    }
                }
            }
        }
    }
    
    @objc func transformMassiveData(data: Data) {
        guard let model = connectPeripherModel else {
            return
        }
        if connected == false {
            return
        }
        for service in (model.peripheral?.services)! {
            if service.uuid.isEqual(CBUUID(string: serviceUUID)) {
                for characteristic in service.characteristics! {
                    if characteristic.uuid .isEqual(CBUUID(string: writeUUID1)) {
                        model.peripheral?.writeValue(data, for: characteristic, type: .withoutResponse)
                    }
                }
            }
        }
    }
    
    
    func notifyValue(uuidString: String) {
        guard let model = connectPeripherModel else {
            return
        }
        if connected == false {
            return
        }
        for service in (model.peripheral?.services)! {
            if service.uuid.isEqual(CBUUID(string: serviceUUID)) {
                for characteristic in service.characteristics! {
                    if characteristic.uuid .isEqual(uuidString) {
                        model.peripheral?.setNotifyValue(true, for: characteristic)
                    }
                }
            }
        }
    }
    
    private func findService(peripheral: CBPeripheral) {//查找服务
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
}

//MARK:CBCentralManagerDelegate
extension FDBleManage: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard let bleDidUpdateState = bleDidUpdateState else {
            return;
        }
        switch central.state {
        case .unknown:
            bleDidUpdateState(.unknown)
        case .resetting:
            bleDidUpdateState(.resetting)
        case .unsupported:
            bleDidUpdateState(.unsupported)
        case .unauthorized:
            bleDidUpdateState(.unauthorized)
        case .poweredOff:
            connectStateChange(connenctState: .poweredOff)
            bleDidUpdateState(.poweredOff)
        case .poweredOn:
            bleDidUpdateState(.poweredOn)
            if FDPeripherModel.isScan() {//如果需要自动重新连接，则开始扫描
                centralManager?.scanForPeripherals(withServices: nil, options: nil)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {//扫描到设备的广播包
        if peripheral.name == nil {//没有名字
            return
        }
        let peripheralModel = FDPeripherModel(peripheral: peripheral, AdvertisementData: advertisementData, RSSI: RSSI)
        if autoConnect && peripheralModel.lastConnectPeripheral() {//自动连接且此设备是上次连接的设备
            connectPeripheral(peripheralModel: peripheralModel)
        }
        guard let scanResult = scanResult else {
            return
        }
        scanResult(peripheralModel)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {//连接成功
        connectStateChange(connenctState: .connected)
        findService(peripheral: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {//连接失败
        connectStateChange(connenctState: .connectFailure)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {//断开连接
        connectStateChange(connenctState: .disconnected)
    }
}

//MARK:CBPeripheralDelegate
extension FDBleManage: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {//查找服务的回调
        if (error != nil) {//查找服务出错
            connectStateChange(connenctState: .notFoundService)
            centralManager?.cancelPeripheralConnection(peripheral)
            return
        }
        if let services = peripheral.services {//已经查找到服务,就查找服务下的特征
            var haveService = false
            for service in services {
                if service.uuid.isEqual(CBUUID(string: serviceUUID))  {
                    peripheral.discoverCharacteristics(nil, for: service)
                    haveService = true
                }
            }
            if haveService == false {
                connectStateChange(connenctState: .notFoundService)
                centralManager?.cancelPeripheralConnection(peripheral)
            }
        }else {//没有服务
            connectStateChange(connenctState: .notFoundService)
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (error != nil) {//查找特征出错
            return
        }
        if let characteristics = service.characteristics {//已经查找到特征,就看一下是否有自己想要的特征
            for characteristic in characteristics {//如果UUID有自己想要的就是连接成功
                let UUID = CBUUID(string: writeUUID)
                if characteristic.uuid .isEqual(UUID) {
                    connectStateChange(connenctState: .foundService)
                    break
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {//接收到设备返回的数据
        if error != nil {
            return
        }
        guard let receivePeripheralDataUpdate = receivePeripheralDataUpdate, let data = characteristic.value  else {
            return
        }
        receivePeripheralDataUpdate(data)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("發送數據失敗")
        }
    }
    
}





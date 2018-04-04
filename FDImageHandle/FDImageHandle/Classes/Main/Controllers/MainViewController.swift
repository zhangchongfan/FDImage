//
//  MainViewController.swift
//  FDImageHandle
//
//  Created by 张冲 on 2018/3/28.
//  Copyright © 2018年 zhangchong. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    let bleManager = FDBleManage.shareManager
    
    var selectImageData: Data?
    
    var transforming = false
    
    var i = 0
    
    @IBOutlet var rateTextField: UITextField!
    @IBOutlet var sizeLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var transformProgressLabel: UILabel!
    
    lazy var connectStateView:FDConnectStateView = {
        let stateView = FDConnectStateView()
        stateView.delegate = self
        return stateView
    }()
    
    lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.modalTransitionStyle = .coverVertical
        picker.allowsEditing = false
        return picker
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Main"
        configuringBle()
        view.addSubview(connectStateView)
        _ = connectStateView
            .sd_layout()
            .leftSpaceToView(view,0)?
            .topSpaceToView(view, 64)?
            .rightSpaceToView(view,0)?
            .heightIs(50)
//        connectStateView.layoutIfNeeded()
    }
    
    func configuringBle() {
        //监听手机蓝牙的变化
        bleManager.bleDidUpdateState = { [weak self](bleState) in
            switch bleState {
            case .poweredOn:
                //手机蓝牙开启
                break
            case .poweredOff:
                //手机蓝牙关闭
                self?.disconnected()
                break
            default:
                //手机蓝牙关闭
                self?.disconnected()
                break
            }
        }
        
        bleManager.bleConnectState = { [weak self](connectState) in
            switch connectState {
            case .connected:
                //连接成功
                break
            case .foundService:
                //发现服务
                self?.connected()
                break
            case .connectFailure:
                //连接失败
                self?.disconnected()
                break
            case .disconnected:
                //蓝牙断开
                self?.disconnected()
                break
            case .poweredOff:
                //手机蓝牙没打开
                break
            default:
                //手机蓝牙关闭
                break
            }
        }
        //接收数据
        bleManager.receivePeripheralDataUpdate = { [weak self](receiveData) in
            var receiveBytes:[UInt8] = Array(repeatElement(0x00, count: 20))
            receiveData.copyBytes(to: &receiveBytes, count: receiveBytes.count)
            if receiveBytes[0] == 0xA1 && receiveBytes[1] == 0x01 {
                self?.transformData()
            }
        }
    }
    
    func connected() {
        if (navigationController?.childViewControllers.count)! > 1 {
            navigationController?.popToRootViewController(animated: true)
        }
        connectStateView.connectState = true
    }
    
    func disconnected() {
        connectStateView.connectState = false
    }
    
    //传输数据
    @IBAction func startTransform(_ sender: UIButton) {
        if selectImageData == nil || rateTextField.text == nil {
            return
        }
        i = 0
        transforming = true
        transformProgressLabel.text = "开始传输"
        bleManager.writeValue(data: FDDataHandle.transformImageData(start: true))
    }
    
    @IBAction func stopTransform(_ sender: UIButton) {
        transforming = false
        transformProgressLabel.text = "停止传输"
        bleManager.writeValue(data: FDDataHandle.transformImageData(start: false))
    }
    
    @objc func transformData() {
        if !transforming {
            return
        }
        let rate = Double(rateTextField.text!)
        let transData = selectImageData as NSData?
        let count = (transData?.length)!%20 == 0 ? (transData?.length)!/20 : (transData?.length)!/20 + 1
        let range = NSMakeRange(i*20, ((transData?.length)! - i*20 - 20) > 0 ? 20 : (transData?.length)! - i*20)
        let sendData = transData?.subdata(with: range) as! Data
        bleManager.transformMassiveData(data: sendData)
        i = i + 1
        if i < count - 1 {
            print("\(i) + \(sendData)")
            perform(#selector(transformData), with: self, afterDelay: rate!/1000.0)
            transformProgressLabel.text = "传输:" + String(i*100 / count)
        }else {//完成
            transformProgressLabel.text = "传输完成"
        }
    }
    
    //选择图片
    @IBAction func selectImage(_ sender: UIButton) {
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    //更新显示
    func updateView(imageData: Data) {
        let size = imageData.count
        sizeLabel.text = "大小:" + String(size) + "byte"
        imageView.image = UIImage(data: imageData)
        selectImageData = imageData
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
}

extension MainViewController: FDConnectStateViewDelegate {
    func connectStateView(_ connectStateView: FDConnectStateView) {
        if bleManager.connected {
            
        }else {
            let scanController = FDScanViewController(nibName: "FDScanViewController", bundle: Bundle.main)
            navigationController?.pushViewController(scanController, animated: true)
        }
    }
    
    func connectStateView(_ connectStateView: FDConnectStateView, didClickDisconnect: UIButton) {
        bleManager.disconnectPeripheral()
    }
}

extension MainViewController: UINavigationControllerDelegate,UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info["UIImagePickerControllerOriginalImage"]
        if let selectImage = image {
            let data = UIImagePNGRepresentation(selectImage as! UIImage)
            if let selectData = data {
                updateView(imageData: selectData)
            }
        }
        dismiss(animated: true, completion: nil)
    }
}














//let serviceUUID = "FFD0" //服务
//let writeUUID = "FFD1"   //A1指令写特征
//let notifyUUID = "FFD2"  //A1指令notify
//let writeUUID1 = "FFD3"  //图片数据传输通道，类型是withoutRespongse

/*
 图片传输步骤
 1.先选择图片和传输速度（一包20字节，速度是每包之间的间隔，单位毫秒）
 2.点击开始传输App向设备发送A101的指令，设备返回A101的指令后，开始传输数据
 3.使用FFD3的特征，向设备写入图片数据，写入的时候上边的进度是App发送的进度，并不是真实设备接收的速度，设备端的这个特征一定要调成withoutRespongse这个类型的
 4.如果中途不想传输了，就点击停止传输App向设备发送A100的指令，设备返回此指令给App
 */






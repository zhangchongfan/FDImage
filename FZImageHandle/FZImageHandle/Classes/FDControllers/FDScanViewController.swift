//
//  FDScanViewController.swift
//  FDImageHandle
//
//  Created by 张冲 on 2018/3/28.
//  Copyright © 2018年 zhangchong. All rights reserved.
//

import UIKit

let LabelTag = 10

class FDScanViewController: UIViewController {
    
    @IBOutlet var scanTableView: FDBaseTableView!
    
    var deviceList: [FDPeripherModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "连接设备"
        scanTableView.normalHeader.beginRefreshing { [weak self] in
            self?.scanDevice()
            self?.perform(#selector(self?.endRefreshing), with: nil, afterDelay: 5.0)
        }
        scanDevice()
    }

    func scanDevice() {
        deviceList.removeAll()
        self.scanTableView.reloadData()
        FDBleManage.shareManager.startScan { [weak self](peripheralModel) in
            self?.deviceList.append(peripheralModel)
            self?.deviceListSorted()
            self?.scanTableView.reloadData()
        }
    }
    
    @objc func endRefreshing() {
        if scanTableView.normalHeader.state != .idle {
            scanTableView.normalHeader.endRefreshing()
        }
        FDBleManage.shareManager.stopScan()
    }
    
    func deviceListSorted() {
        deviceList = deviceList.sorted(by: {(model1,model2) in
            if let rssi1 = model1.rssi, let rssi2 = model2.rssi {
                return rssi1.intValue > rssi2.intValue
            }
            return true
        })
    }
    
}

extension FDScanViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = deviceList[indexPath.row]
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        }
        cell?.textLabel?.text = model.name
        cell?.detailTextLabel?.text = model.address

        var rssiLable: UILabel? = cell?.contentView.viewWithTag(LabelTag) as? UILabel
        if rssiLable == nil {
            rssiLable = UILabel(frame: CGRect(x: UIScreen.main.bounds.size.width - 150, y: 25, width: 130, height: 20))
            rssiLable?.font = UIFont.systemFont(ofSize: 15)
            rssiLable?.tag = LabelTag
            rssiLable?.textAlignment = .right
            rssiLable?.backgroundColor = UIColor.clear
            cell?.contentView.addSubview(rssiLable!)
        }
        rssiLable?.text = "RSSI:" + String(describing: model.rssi!)
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        endRefreshing()
        let model = deviceList[indexPath.row]
        if FDBleManage.shareManager.connected {
            FDBleManage.shareManager.disconnectPeripheral()
        }
        FDBleManage.shareManager.connectPeripheral(peripheralModel: model)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
}


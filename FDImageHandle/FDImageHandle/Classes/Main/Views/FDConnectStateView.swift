//
//  FDConnectStateView.swift
//  FDImageHandle
//
//  Created by 张冲 on 2018/3/28.
//  Copyright © 2018年 zhangchong. All rights reserved.
//

import UIKit
//import SDAutoLayout

@objc protocol FDConnectStateViewDelegate {
    func connectStateView(_ connectStateView: FDConnectStateView)
    func connectStateView(_ connectStateView: FDConnectStateView, didClickDisconnect: UIButton)
}

class FDConnectStateView: UIView {

    let nameLabel = UILabel()
    
    weak var delegate: FDConnectStateViewDelegate? = nil
    
    var connectState = false {
        willSet {
            connectView.isHidden = !newValue
            disconnectView.isHidden = newValue
        }
    }
    
    lazy var connectView: UIView = {
        let view = UIView()
        
        let connectImageView = UIImageView(image: UIImage(named: "bluetooth_connect"))
        
        nameLabel.backgroundColor = UIColor.clear
        nameLabel.text = "V07"
        
        let disconnectBtn = UIButton(type: .custom)
        disconnectBtn.setTitle("断开连接", for: .normal)
        disconnectBtn.setTitleColor(UIColor.brown, for: .normal)
        disconnectBtn.addTarget(self, action: #selector(disconnectBtnClick(sender:)), for: .touchUpInside)
        disconnectBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        disconnectBtn.layer.cornerRadius = 15
        disconnectBtn.layer.borderWidth = 1
        disconnectBtn.layer.borderColor = UIColor.brown.cgColor
        
        view.addSubview(connectImageView)
        view.addSubview(nameLabel)
        view.addSubview(disconnectBtn)
        
        _ = connectImageView.sd_layout()
            .centerYEqualToView(view)?
            .leftSpaceToView(view, 15)?
            .widthIs(30)?
            .heightEqualToWidth()
        _ = nameLabel.sd_layout()
            .centerYEqualToView(view)?
            .leftSpaceToView(connectImageView, 10)?
            .heightIs(30)?
            .rightSpaceToView(view,100)
        _ = disconnectBtn.sd_layout()
            .centerYEqualToView(view)?
            .heightIs(30)?
            .widthIs(80)?
            .rightSpaceToView(view,10)
        return view
    }()
    
    lazy var disconnectView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.red
        let disconnectLabel = UILabel()
        disconnectLabel.text = "Disconnected"
        disconnectLabel.textColor = UIColor.white
        view.addSubview(disconnectLabel)
        
        let tipLabel = UILabel()
        tipLabel.text = "点击连接设备>"
        tipLabel.textColor = UIColor(red: 220/255.0, green: 220/255.0, blue: 220/255.0, alpha: 1)
        tipLabel.textAlignment = .right
        tipLabel.font = UIFont.systemFont(ofSize: 13)
        view.addSubview(tipLabel)
        
        _ = disconnectLabel
            .sd_layout()
            .centerYEqualToView(view)?
            .leftSpaceToView(view, 15)?
            .heightIs(30)?
            .widthIs(150)
        _ = tipLabel
            .sd_layout()
            .centerYEqualToView(view)?
            .rightSpaceToView(view, 10)?
            .heightRatioToView(disconnectLabel,1)?
            .leftSpaceToView(disconnectLabel,10)
        
        return view
    }()
    
    init() {
        super.init(frame: CGRect.zero)
        setConnectStateViewUI()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setConnectStateViewUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setConnectStateViewUI() {
        addSubview(connectView)
        connectView.sd_layout().spaceToSuperView(UIEdgeInsetsMake(0, 0, 0, 0))
        
        addSubview(disconnectView)
        disconnectView.sd_layout().spaceToSuperView(UIEdgeInsetsMake(0, 0, 0, 0))
        
        let lineView = UIView()
        lineView.backgroundColor = UIColor(red: 200/255.0, green: 200/255.0, blue: 200/255.0, alpha: 1)
        addSubview(lineView)
        
        _ = lineView
            .sd_layout()
            .bottomSpaceToView(self,0)?
            .rightSpaceToView(self,0)?
            .leftSpaceToView(self,0)?
            .heightIs(0.5)
        connectState = false
    }
    
    @objc func disconnectBtnClick(sender: UIButton) {
        if let clickDelegate = delegate {
            clickDelegate.connectStateView(self, didClickDisconnect: sender)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.alpha = 0.5
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.alpha = 1
        if let clickDelegate = delegate {
            clickDelegate.connectStateView(self)
        }
    }
    
}






//
//  FDInternalController.swift
//  FZImageHandle
//
//  Created by 张冲 on 2018/9/9.
//  Copyright © 2018年 zhangchong. All rights reserved.
//

import UIKit

@objc class FDInternalController: UIViewController {

    @IBOutlet weak var speedTextField: UITextField!
    
    @IBOutlet weak var bytesTextField: UITextField!
    
    @objc var model: FDInternalTransformModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "内部参数设置"
        speedTextField.text = String(model!.speed)
        bytesTextField.text = String(model!.byteCount)
    }

    @IBAction func confirmAction(_ sender: UIButton) {
        let speed = Int(speedTextField.text ?? "5")
        let count = Int(bytesTextField.text ?? "20")
        model?.speed = speed!
        model?.byteCount = count!
        model?.saveSettingModel()
        self.navigationController?
            .popViewController(animated:true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}

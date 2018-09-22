//
//  ViewController.swift
//  FZImageHandle
//
//  Created by 张冲 on 2018/8/22.
//  Copyright © 2018年 zhangchong. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let docPath: String = GZImageFormatChange.share().docPath()
        let path:String = docPath + "/" + "test.png"
        let image = UIImage(contentsOfFile: path)
        self.imageView.image = image
//        GZImageFormatChange.share().save(toBMP: image, andSaveFileName: "zc.bmp")
        let data = image?.bitmapDataWithFileHeader()
        if let bmpData = data {
            print(bmpData.description)
            let savePath = docPath + "/" + "test.bmp"
            try! bmpData.write(to: URL(fileURLWithPath: savePath))
        }
//        self.navigationController?.pushViewController(PhotoDetailViewController(), animated: true)
        
        let handSharke = "HandShake/2yK39b";
        handSharke.data(using: .utf8)
        
//        NSString *handSharke = @"HandShake/2yK39b";
//        NSData *data = [handSharke dataUsingEncoding:NSUTF8StringEncoding];
        
        
    }

}


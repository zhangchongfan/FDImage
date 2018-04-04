//
//  FDBaseTableView.swift
//  FDImageHandle
//
//  Created by 张冲 on 2018/3/28.
//  Copyright © 2018年 zhangchong. All rights reserved.
//

import UIKit
import MJRefresh
class FDBaseTableView: UITableView {
    
    public let normalHeader = MJRefreshNormalHeader()
    
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        addHeaderRefersh()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addHeaderRefersh()
    }
    
    func addHeaderRefersh() {
        mj_header = normalHeader
    }
    
}

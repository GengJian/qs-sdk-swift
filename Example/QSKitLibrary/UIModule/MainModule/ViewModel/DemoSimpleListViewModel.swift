//
//  DemoSimpleListViewModel.swift
//  QSKitLibrary_Example
//
//  Created by Soul on 2023/7/13.
//  Copyright © 2023 Quasi Team. All rights reserved.
//

import UIKit
import QSKitLibrary

class DemoSimpleListViewModel: QSBaseViewModel {
    enum Entry {
        case testButton

        var entryName: String {
            switch self {
            case .testButton:
                return "测试QSButton"
//            default:
//                return "未知"
            }
        }

    }

    // MARK: - Property
    var mDataSource: [Entry] = [.testButton]

}

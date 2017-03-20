//
//  RangeSelectorBar.swift
//  Tuton
//
//  Created by Carl Goldsmith on 11/03/2016.
//  Copyright © 2016 Tuton. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class RangeSelectorBar: UIScrollView {
    var image: UIImage? = UIImage(named: "RangeSelectorBarBackground.png")
    
    override func draw(_ rect: CGRect) {
        //        if image != nil {
        self.backgroundColor = UIColor(patternImage: image!)
        //        }
    }
}

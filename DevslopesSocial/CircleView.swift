//
//  CircleView.swift
//  DevslopesSocial
//
//  Created by Juan M Mariscal on 1/15/17.
//  Copyright © 2017 Juan M Mariscal. All rights reserved.
//

import UIKit

class CircleView: UIImageView {
    
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        layer.cornerRadius = self.frame.width / 2
        clipsToBounds = true
    }
}

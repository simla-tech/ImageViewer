//
//  UIColor.swift
//  ImageViewer
//
//  Created by Ross Butler on 17/02/2017.
//  Copyright © 2017 MailOnline. All rights reserved.
//

import UIKit

extension UIColor {

    public func shadeDarker() -> UIColor {
        var red: CGFloat = 0.0, green: CGFloat = 0.0, blue: CGFloat = 0.0, alpha: CGFloat = 0.0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let variance: CGFloat = 0.4
        let newR = CGFloat.maximum(red * variance, 0.0),
        newG = CGFloat.maximum(green * variance, 0.0),
        newB = CGFloat.maximum(blue * variance, 0.0)

        return UIColor(red: newR, green: newG, blue: newB, alpha: 1.0)
    }

}

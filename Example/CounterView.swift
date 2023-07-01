//
//  ImageCounterView.swift
//  Money
//
//  Created by Kristian Angyal on 07/03/2016.
//  Copyright © 2016 Mail Online. All rights reserved.
//

import UIKit

class CounterView: UIView {

    var count: Int
    let countLabel = UILabel()
    var currentIndex: Int {
        didSet {
            self.updateLabel()
        }
    }

    init(frame: CGRect, currentIndex: Int, count: Int) {

        self.currentIndex = currentIndex
        self.count = count

        super.init(frame: frame)

        self.configureLabel()
        self.updateLabel()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureLabel() {

        self.countLabel.textAlignment = .center
        self.addSubview(self.countLabel)
    }

    func updateLabel() {

        let stringTemplate = "%d of %d"
        let countString = String(format: stringTemplate, arguments: [currentIndex + 1, count])

        self.countLabel.attributedText = NSAttributedString(
            string: countString,
            attributes: [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17),
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.countLabel.frame = self.bounds
    }
}

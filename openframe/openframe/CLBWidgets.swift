//
//  CLBWidgets.swift
//  PreviewTransitionDemo
//
//  Created by seth piezas on 8/3/17.
//  Copyright © 2017 Alex K. All rights reserved.
//

import UIKit
import Charts


class LabelView : UITextView {
    init() {
        super.init(frame: CGRect.zero, textContainer: nil)
        text = "ehllo there!"
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class SlideView : UIView {
    var pan:UIPanGestureRecognizer!
    init() {
        super.init(frame: CGRect.zero)
        pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        addGestureRecognizer(pan)
    }
    
    @objc func handlePan(gesture:UIPanGestureRecognizer) {
//        print(gesture)
        let pos = gesture.location(in: self.superview)
        self.center.y = pos.y
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class StatsView : UIButton {
    init() {
        super.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class ChartView : BarChartView {
    init() {
        super.init(frame: CGRect.zero)
        drawGridBackgroundEnabled = false
        xAxis.drawGridLinesEnabled = false
        leftAxis.drawZeroLineEnabled = false
        leftAxis.drawBottomYLabelEntryEnabled = false
        dragEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(data: Any) {
        print("setting data")
    }
}

class TopView: UIView {
    init() {
        super.init(frame: CGRect.zero)
        backgroundColor = .green
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

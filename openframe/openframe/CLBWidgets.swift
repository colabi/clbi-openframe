//
//  CLBWidgets.swift
//  PreviewTransitionDemo
//
//  Created by seth piezas on 8/3/17.
//  Copyright © 2017 Alex K. All rights reserved.
//

import UIKit
//import Charts


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

class ChartView : UIView {
    init() {
        super.init(frame: CGRect.zero)
//        drawGridBackgroundEnabled = false
//        xAxis.drawGridLinesEnabled = false
//        leftAxis.drawZeroLineEnabled = false
//        leftAxis.drawBottomYLabelEntryEnabled = false
//        dragEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setData(data: Any) {
        print("setting data")
    }
}

//Swipeview BG
class TopView: UIView {
    init() {
        super.init(frame: CGRect.zero)
        backgroundColor = .green
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


open class DateView : UIView {
    static var shared:DateView!
    var label:UILabel!
    override init(frame:CGRect) {
        super.init(frame:frame)
        let v = UIView(frame:frame)
        addSubview(v)
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = frame
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.isUserInteractionEnabled = false
        blurEffectView.layer.cornerRadius = 10
        blurEffectView.clipsToBounds = true
        v.addSubview(blurEffectView)
        
        label = UILabel(frame: frame)
        label.font = label.font.withSize(32)
        label.text = "7/17"
        label.textColor = .white
        label.textAlignment = .center
        v.addSubview(label)
        DateView.shared = self
    }
    
    var date:String {
        set(date) {
            label.text = date
        }
        get {
            return label.text!
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

public class ParallaxBrowserView : UITableView {
//    func configure(data: Post) {
//        print(data)
//    }
    
}

public class ParallaxBrowserViewCell : UITableViewCell, CLBIDataView {
    func configure(data: Post) {
        backgroundColor = .red
        print("configuring cell: ", data)
    }

}

/*
 
 Copyright ©Seth Piezas, 2017
 
 GPLv3
 
 */

import UIKit
import PreviewTransition
import HFSwipeView
import WebKit
//import Charts

public class CLBIView : UIView {
    var effect:UIVisualEffectView?
    
}


//public class PostView : CLBIView {
//    private var _data:Post?
//    public var pdata:Post {
//        set {
//            configure(data: pdata)
//        }
//        get {
//            return _data!
//        }
//    }
//    public func configure(data:Post) {
//
//    }
//
//}



public protocol CLBIDataView {
    func configure(data:Datum, completion: @escaping (Post, [String]?) -> Void)
}

class LabelView : UITextView, CLBIDataView {
    init() {
        super.init(frame: CGRect.zero, textContainer: nil)
        text = "ehllo there!"
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(data: Datum, completion: @escaping (Post, [String]?) -> Void) {
        print("configuring cell: ", data)
    }
    
}

class SlideView : UIView {
    
    public lazy var swipeView: HFSwipeView = {
        let view = HFSwipeView.newAutoLayout()
        view.isDebug = true
        view.autoAlignEnabled = true
        view.circulating = true
        view.recycleEnabled = true
        view.currentPage = 0
        view.currentPageIndicatorTintColor = .clear
        view.pageIndicatorTintColor = .clear
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    var pan:UIPanGestureRecognizer!
    init() {
        super.init(frame: CGRect.zero)
//        pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
//        addGestureRecognizer(pan)
        addSubview(swipeView)
    }
    
    //    @objc func handlePan(gesture:UIPanGestureRecognizer) {
    ////        print(gesture)
    //        let pos = gesture.location(in: self.superview)
    //        self.center.y = pos.y
    //    }
    

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class StatsView : UIButton, CLBIDataView {
    init() {
        super.init(frame: CGRect.zero)
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(data: Datum, completion: @escaping (Post, [String]?) -> Void) {
        print("configuring cell: ", data)
    }
}

class ChartView : UIView, CLBIDataView {
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
    
    public func configure(data: Datum, completion: @escaping (Post, [String]?) -> Void) {
        print("configuring cell: ", data)
    }

}

//Swipeview BG
class TopView: UIView {

    var pan:UIPanGestureRecognizer!
    init() {
        super.init(frame: CGRect.zero)
        pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        addGestureRecognizer(pan)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func handlePan(gesture:UIPanGestureRecognizer) {
        //        print(gesture)
        let pos = gesture.location(in: self.superview)
        self.center.y = pos.y
    }
}


open class DateView : UIView, CLBIDataView {
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
    
    public func configure(data: Datum, completion: @escaping (Post, [String]?) -> Void) {
        print("configuring cell: ", data)
    }
}

public class ParallaxBrowserView : UITableView {
    public func configure(data: Datum, completion: @escaping (Post, [String]?) -> Void) {
        print("configuring cell: ", data)
    }
    
}

public class ParallaxBrowserViewCell : ParallaxCell, CLBIDataView {
//    init(style: UITableViewCellStyle, reuseIdentifier: String?) {
//        super.init
//    }
//    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(data: Datum, completion: @escaping (Post, [String]?) -> Void) {
        print("configuring cell: ", data)
    }

}

open class MyxedWebView : WKWebView, WKUIDelegate, WKNavigationDelegate {
    
    var webview:WKWebView?
    var config:WKWebViewConfiguration!
    var loadCB:((MyxedWebView) -> Void)?
    init(appname:String, completion: @escaping (MyxedWebView) -> Void) {
        let frame = UIScreen.main.bounds
        super.init(frame: frame, configuration: WKWebViewConfiguration())
        self.configuration.userContentController.add(CLBIBridge.shared, name: "port")
        load(URLRequest(url: URL(string: MyxedConfig.appurl)!))
        self.navigationDelegate = self
        self.uiDelegate = self
//        self.isHidden = true
        self.loadCB = completion
        
    }
    
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //        print("webview: finished load")
    }
    
    public required override init?(coder:NSCoder) {
        super.init(coder:coder)
    }
    
}


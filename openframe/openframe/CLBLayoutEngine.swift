//
//  CLBLayoutEngine.swift
//  PreviewTransitionDemo
//
//  Created by seth piezas on 7/29/17.
//  Copyright © 2017 Alex K. All rights reserved.
//

import UIKit
import WebKit
import JavaScriptCore
import Photos

struct Frame : Codable {
    var x:Double
    var y:Double
    var width:Double
    var height:Double

}

struct LayoutInfoSimple : Codable {
    var frame:Frame
    var backgroundImage:String
    var backgroundColor:Array<CGFloat>
    var effects:String
    var cornerRadius:Int
    var opacity:CGFloat
}

struct ShadowView : Codable {
    var dom:Dictionary<String,String>
    var id:String
    var type:String
    var children:Array<ShadowView>
    var blur:Bool
    var datasource:String?
    var selector:String?
}

struct LayoutInfoSimpleResult : Codable {
    var controller:String
    var hierarchy:ShadowView
    var modes:Dictionary<String,Dictionary<String, LayoutInfoSimple>>
}

class UIViewControllerExtra {
    var info:LayoutInfoSimpleResult
    var views:[String:UIView]!
    init(info:LayoutInfoSimpleResult) {
        self.info = info
        views = [String:UIView]()
    }
}



class CLBWebViewEngine {
    var wv:UIWebView!
    var jscontext:JSContext!
    init() {
        let f = UIScreen.main.bounds
        wv = UIWebView(frame:f)
        jscontext = wv.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
        print(jscontext)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


@objc protocol LayoutEngineExports : JSExport {
    var firstName: String { get set }
    func update(json:String) -> String
}

@objc class LayoutEngine : NSObject, LayoutEngineExports {
    dynamic var firstName: String = "test"
    override init() {
        
    }
    func update(json: String) -> String {
        print("updating: \(json)")
        return "done"
    }
}


@objc public class CLBLayoutEngine : NSObject, LayoutEngineExports, UIWebViewDelegate {
    dynamic var firstName: String = "test"
    
    public static var refreshTimeout = 2000
    private static var _instance:CLBLayoutEngine!
    public static var shared:CLBLayoutEngine {
        if _instance == nil {
            _instance = CLBLayoutEngine()
            _instance.myinit()
        }
        return _instance
    }
    
    var engine:CLBWebViewEngine!
    private var size:CGSize!
    let decoder = JSONDecoder()
    var cache:LayoutInfoSimpleResult?
    var vcs = [UIViewController:UIViewControllerExtra]()
    func myinit() {
        engine = try? CLBWebViewEngine()
        engine.wv.delegate = self
        engine.jscontext.setObject(self, forKeyedSubscript: "layoutengine" as NSCopying & NSObjectProtocol)

    }
    

    
    func preload() {
        
    }

    func load(_ index:String, cache:Bool = true, completion: @escaping (UIView) -> Void) {
        
    }
    
    var loadCB:((UIViewController) -> Void)?
    var options:[String:Any]?
    func loadVC(_ index:String, options: [String: Any], completion: @escaping (UIViewController) -> Void) -> Void {
        self.options = options
        loadCB = completion

        var doCacheLoad = true
        if doCacheLoad == true {
//            var json = UserDefaults.standard.object(forKey: "data") as! String
//            print(json)
            if let filepath = Bundle.main.path(forResource: "wib_browser", ofType: "json") {
                var json = try? String(contentsOfFile: filepath)
                update(json: json!)
            }
            
            
        } else {
            let path = Bundle.main.path(forResource: "wbprocessor", ofType: "html")
            let data = NSData.init(contentsOfFile: path!)
            let base = URL(string: "http://myxed.com")
            engine.wv.load(data as! Data, mimeType: "text/html", textEncodingName: "utf-8", baseURL: base! )
        }
        

    }
    
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.doLoadVC(options: self.options!)
        }
    }

    func doLoadVC(options: [String:Any]) {
        let layoutFn = self.engine.jscontext.objectForKeyedSubscript("getAllModes")
        let data = try! JSONSerialization.data(withJSONObject: options, options: JSONSerialization.WritingOptions(rawValue: 0))
        let arg = String(data: data, encoding: .utf8)
        let results = layoutFn?.call(withArguments: [arg])

    }
    
    func animate(_ extra:UIViewControllerExtra, label:String, mode:String?, duration:Double) {
        var mode = extra.info.modes[label]!
        UIView.animate(withDuration: duration, animations: {
            for (k,v) in extra.views {
                var info = mode[k]
                v.setFromWIB(info: info!)
            }
        }, completion: { (status) in
            print(status)
        })
    }
    
    func createEffectsView(_ parent:UIView, _ main:UIView) -> UIView {
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        parent.insertSubview(blurEffectView, belowSubview: main)
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.topAnchor.constraint(equalTo: main.topAnchor).isActive = true
        blurEffectView.leftAnchor.constraint(equalTo: main.leftAnchor).isActive = true
        blurEffectView.widthAnchor.constraint(equalTo: main.widthAnchor).isActive = true
        blurEffectView.heightAnchor.constraint(equalTo: main.heightAnchor).isActive = true

        blurEffectView.isUserInteractionEnabled = true
        return blurEffectView
    }
    
    func hierV(node:ShadowView, extra: inout UIViewControllerExtra, parent:UIView? = nil)  -> UIView {
        let module = "openframe"//Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
        let vname = node.type
        let path = node.id
        print("path: \(path), blur: \(node.blur)")
        let aClass = NSClassFromString("\(module).\(vname)") as! UIView.Type
        var mainview = aClass.init()
        parent?.addSubview(mainview)
        if node.blur == true {
            createEffectsView(parent!, mainview)
        }
        extra.views[path] = mainview
        if node.datasource != nil {
            
        }
        for child in node.children {
            let cview = hierV(node: child, extra: &extra, parent: mainview)
            mainview.addSubview(cview)
        }
        return mainview
    }
    
    func createViews(vc:UIViewController, extra: inout UIViewControllerExtra) -> UIView {
        let root = extra.info.hierarchy
        let rootview = hierV(node:root, extra: &extra)
        return rootview
    }
    
    func createViewController(info:LayoutInfoSimpleResult?) -> UIViewController? {
        guard info != nil else {
            return nil
        }
        let module = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
        let vcname = info!.controller
        let aClass = NSClassFromString("\(module).\(vcname)") as! UIViewController.Type
        let vc = aClass.init()
        var ex = UIViewControllerExtra(info: info!)
        vcs[vc] = ex
        let rootview = self.createViews(vc: vc, extra: &ex)
        vc.view = UIView(frame: UIScreen.main.bounds)
        vc.view.addSubview(rootview)
        //animate(ex, label: "initial", mode: nil, duration: 0)
        return vc
    }
    
    func update(json: String) -> String {
        //UPDATE JSON INTO CACHE
        let ts = Date().timeIntervalSince1970
        UserDefaults.standard.set(ts, forKey: "data_ts")
        UserDefaults.standard.set(json, forKey: "data")

        if let newData = json.data(using: String.Encoding.utf8){
            print("layout: \(json)")
            let result = try? decoder.decode(LayoutInfoSimpleResult.self, from: newData)
            DispatchQueue.main.async {
                let vc = self.createViewController(info: result)
                self.loadCB!(vc!)
            }
        }
        return "done"
    }
    

}


extension UIView {

    subscript<T:UIView>(index:String) -> T {
        var v = UIStackView()
        return v as! T
    }
    
    func setFromWIB(info:LayoutInfoSimple) {
        print("setting view from wib: \(info)")
        let f = info.frame
        frame = CGRect(x: f.x, y: f.y, width: f.width, height: f.height > 0 ? f.height : 736)
        layer.cornerRadius = CGFloat(info.cornerRadius)
        clipsToBounds = info.cornerRadius > 0
        alpha = info.opacity
        backgroundColor = .clear
//        backgroundColor = UIColor(red: info.backgroundColor[0]/255.0, green: info.backgroundColor[1]/255.0, blue: info.backgroundColor[2]/255.0, alpha: 1)
        if info.backgroundImage != "" {
            print("BACKGROUND IMAGE: \(info.backgroundImage)")
            ImageCache.shared[info.backgroundImage] {
                image in
                DispatchQueue.main.async {
                    self.layer.contents = image.cgImage
                }
            }
        }
    }

    
    public var data:Any {
        set {
//            setData(data: data)
        }
        get {
            return ""
        }
    }


}

extension UIViewController {
    func setMode(_ mode:String, duration:Float) {
//        CLBLayoutEngine.shared.
        
    }
    public func animateSubviews(_ label:String, duration:Double) {
        var ex = CLBLayoutEngine.shared.vcs[self]
        CLBLayoutEngine.shared.animate(ex!, label: "second", mode: nil, duration: duration)
    }
}

extension UIStoryboard {
    public class func instantiateWIBViewController(withURL: String, options: [String: Any], completion: @escaping (UIViewController) -> Void) {
        CLBLayoutEngine.shared.loadVC(withURL, options: options, completion: {
            vc in
            var mwv = MyxedWebView(appname: "WeightList")
            vc.view.insertSubview(mwv, at: 0)
            completion(vc)
        })
    }
    
}

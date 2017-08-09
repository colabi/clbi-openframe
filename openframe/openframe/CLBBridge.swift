//
//  CLBBridge.swift
//  PreviewTransitionDemo
//
//  Created by seth piezas on 8/3/17.
//  Copyright © 2017 Alex K. All rights reserved.
//

import UIKit
import WebKit

extension Notification.Name {
    static let clbiDataName = Notification.Name("clbi_data")
}

class CLBIBridge : NSObject, WKScriptMessageHandler {
    static var _shared:CLBIBridge!;
    static var shared:CLBIBridge {
        get {
            if _shared == nil {
                _shared = CLBIBridge()
            }
            return _shared
        }
    }

    var webview:WKWebView?
    
    override init() {
        super.init()
        //listen for messages
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification), name: .clbiDataName, object: nil)
    }
    @objc func handleNotification(note:Notification) {
        print(note)
        
    }
    func setupListener(name:String) {
        let cmd = "window.authservice.mbus.handleMessage({'name': 'subscribe', 'path': '\(name)'})"
        print(cmd)
        webview?.evaluateJavaScript(cmd, completionHandler: { (a, error) in
            print(a,error)
        })
    }
    func update(index:String, object:AnyObject, completion: @escaping (String) -> Void ) {
        var jsonobject = "{}"
        let cmd = "window.authservice.mbus.handleMessage({'name': 'update', 'index': '\(index)', 'object': \(jsonobject)    })"
        print("updating: \(cmd)")
        webview?.evaluateJavaScript(cmd, completionHandler: { (a, error) in
//            completion(a)
        })
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("WEBKIT MESSAGE: \(message.body)")
    }
    
    
    //    func exec(_ funcName:String, completion: @escaping (AnyObject) -> Void) {
//
//    }
}



extension UIViewController {
    func connectToDataSources(options:[String:CLBStreamOption]) {
        for (path,v) in options {
//            CLBIBridge.shared.streams["path"] {
//                obj in
//                print(obj) //delivery summary
//                self.updateViewHierarchy(path: path, object: obj)
//            }
        }
        StreamManager.shared.streams["/data"] {
            objects in
            print(objects)
        }
    }
    
    func updateViewHierarchy(path:String, object:Any) {
        
    }
}


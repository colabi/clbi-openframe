//
//  CLBBridge.swift
//  PreviewTransitionDemo
//
//  Created by seth piezas on 8/3/17.
//  Copyright © 2017 Alex K. All rights reserved.
//

import UIKit
import WebKit


public typealias GenericBridgeFN = (AnyObject, (Any) -> Void) -> Void
extension Notification.Name {
    static let clbiDataName = Notification.Name("clbi_data")
}

struct MessageResponse : Decodable {
    
}


public class CLBIBridge : NSObject, WKScriptMessageHandler {
    static var _shared:CLBIBridge!;
    static var shared:CLBIBridge {
        get {
            if _shared == nil {
                _shared = CLBIBridge()
            }
            return _shared
        }
    }

    var webview:MyxedWebView?
    var decoder = JSONDecoder()
    var listeners:[String:Array<ListenerCB>]!
    var function_listeners:[String:Array<GenericBridgeFN>]!
    var apphandlers:[String:Any]!
    override init() {
        super.init()
        //listen for messages
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification), name: .clbiDataName, object: nil)
        listeners = [String:Array<ListenerCB>]()
        function_listeners = [String:Array<GenericBridgeFN>]()
        apphandlers = CLBIAppDelegate.registerServiceHandlers()
        
    }
    @objc func handleNotification(note:Notification) {
        print(note)
        
    }
    func setupListener(name:String, mode:String, completion: @escaping ListenerCB) {
        let cmd = "window.authservice.mbus.handleMessage({'name': 'subscribe', 'path': '\(name)', 'mode': '\(mode)'})"
        if listeners[name] == nil {
            listeners[name] = [ListenerCB]()
            webview?.evaluateJavaScript(cmd, completionHandler: { (a, error) in
                print(a,error)
            })
        }
        listeners[name]?.append(completion)
    }
    
    public func registerListener(funcname:String, function: @escaping GenericBridgeFN) {
        if function_listeners[funcname] == nil {
            function_listeners[funcname] = [GenericBridgeFN]()
        }
        function_listeners[funcname]?.append(function)
    }
    
    func update(index:String, object:AnyObject, completion: @escaping (String) -> Void ) {
        var jsonobject = "{}"
        let cmd = "window.authservice.mbus.handleMessage({'name': 'update', 'index': '\(index)', 'object': \(jsonobject)    })"
        print("updating: \(cmd)")
        webview?.evaluateJavaScript(cmd, completionHandler: { (a, error) in
//            completion(a)
        })
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
//        print(message.body)
        var data = message.body as! [String:AnyObject]
        var name = data["type"] as! String
        if name == "subscribe" {
            var path = data["path"] as! String
            execListeners(path: path, data: data["data"]!)
        } else if(name == "ready") {
            webview?.loadCB?(webview!)
        } else {
            guard let appFnHandler = apphandlers[name] else {
                return
            }
            let appFn = appFnHandler as! GenericBridgeFN
            appFn(data["data"]!) {
                response in
                print(response)
                let cmd = "window.authservice.mbus.handleMessage({'name': '\(name)'})"
                webview?.evaluateJavaScript(cmd, completionHandler: { (a, error) in
                    print(a)
                })
            }
        }
        
//        var message = try? decoder.decode(MessageResponse.self, from: message.body)
    }
    func execListeners(path:String, data:AnyObject) {
        guard let ll = listeners[path] else {
            return
        }
        for l in ll {
            l(data)
        }
    }
    
    
    //    func exec(_ funcName:String, completion: @escaping (AnyObject) -> Void) {
//
//    }
}




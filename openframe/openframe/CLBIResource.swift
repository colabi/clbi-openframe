//
//  CLBIResource.swift
//  PreviewTransitionDemo
//
//  Created by seth piezas on 8/9/17.
//  Copyright © 2017 Alex K. All rights reserved.
//

import UIKit


struct CLBStreamOption {
    var isList:Bool
    var summarize:Bool
    var preloadResources:Bool
}

struct PostSummaryInfo {
    
}

typealias ListenerCB = (Any) -> Void

protocol ListenerDelegate {
    
}


class ResourceTracker {
    var type:Int = 0;
}

struct ResourceItem : Hashable, Equatable {
    var path:String;
    var state:Int = 0;
    var data:Data?;
    var type:String;
    
    var hashValue: Int {
        return path.hashValue;
    }
    static func == (lhs: ResourceItem, rhs: ResourceItem) -> Bool {
        return lhs.path == rhs.path
    }
}

class ResourceManager {
    var resources = [String:ResourceItem]();
    var wait_queue = [ResourceItem:[(ResourceItem) -> Void]]()
    init() {
        
    }
    
    func retrieve_resource(path:String, type:String, completion: @escaping (Data) -> Void) {
        guard let url = URL(string: path) else { return }
        print("download start: \(path)")
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                //                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil
                //                let image = UIImage(data: data)
                else { return }
            completion(data)
            
            }.resume()
    }
    
    func item(_ path: String, type: String, completion: @escaping (ResourceItem) -> Void) -> ResourceItem {
        if resources[path] == nil {
            var r = ResourceItem(path: path, state: 0, data: nil, type:type)
            retrieve_resource(path: path, type: type) {
                r.data = $0
                r.state = 2
                //exec all outstanding completions
                for c in self.wait_queue[r]! {
                    c(r)
                }
                self.wait_queue[r]!.removeAll()
            }
            resources[path] = r;
        }
        var r:ResourceItem = resources[path]!;
        
        if r.state != 2 {
            if(wait_queue[r] == nil) {
                wait_queue[r] = [(ResourceItem) -> Void]()
            }
            wait_queue[r]?.append(completion)
        } else {
            completion(r)
        }
        return r
    }
    
    func group(_ array:[String], completion: @escaping (Void) -> Void ) -> Void {
        let g = DispatchGroup();
        for a in array {
            g.enter()
            item(a, type: "image") {_ in
                g.leave()
            }
            
        }
        g.notify(queue: DispatchQueue.global(qos: .background)) {
            completion()
        }
    }
}


class StreamManager : NSObject {
    static var _shared:StreamManager!;
    static var shared:StreamManager {
        get {
            if _shared == nil {
                _shared = StreamManager()
            }
            return _shared
        }
    }
    var listeners:[String:Array<ListenerCB>]!
    var id = 0
    override init() {
        super.init()
        listeners = [String:Array<ListenerCB>]()
    }
    subscript(index:String, completion: @escaping ListenerCB ) -> Int {
        var nid = id
        if listeners[index] == nil {
            listeners[index] = [ListenerCB]()
            CLBIBridge.shared.setupListener(name:index)
        }
        listeners[index]?.append(completion)
        return id
    }
    func execListeners(path:String, objects:Any) {
        var ll = listeners[path]
        for l in ll! {
            l(objects)
        }
    }

}

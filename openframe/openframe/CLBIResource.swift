//
//  CLBIResource.swift
//  PreviewTransitionDemo
//
//  Created by seth piezas on 8/9/17.
//  Copyright © 2017 Alex K. All rights reserved.
//

import UIKit
import Photos


class ImageCache {
    static var _shared:ImageCache!;
    static var shared:ImageCache {
        get {
            if _shared == nil {
                _shared = ImageCache()
            }
            return _shared
        }
    }
    //    let default_image = UIImage(named: "human")!
    var cache = Dictionary<String, UIImage>()
    subscript(index:String, completion: @escaping (UIImage) -> Void ) -> Bool {
        if cache[index] != nil {
            DispatchQueue.main.async {
                completion(self.cache[index]!)
            }
        } else {
            //            DispatchQueue.main.async {
            //                completion(self.default_image)
            //            }
            if index.contains("https://") {
                let data = try? Data(contentsOf: URL(string: index)!)
                guard let d = data else {
                    //                    DispatchQueue.main.async {
                    //                        completion(self.default_image)
                    //                    }
                    return false
                }
                let image = UIImage(data: d)
                cache[index] = image
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    completion(image!)
                }
            } else if index.contains("local://") {
                var photoid = index.replacingOccurrences(of: "local://", with: "")
                var photos = PHAsset.fetchAssets(withLocalIdentifiers: [photoid], options: nil)
                let options = PHImageRequestOptions()
                options.resizeMode = .none
                PHImageManager.default().requestImage(for: photos[0], targetSize: CGSize(width: 512,height: 512), contentMode: .aspectFill, options: options, resultHandler: { (image, data) in
                    if Double((image?.size.width)!) > 512.0  {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                            self.cache[index] = image
                            completion(image!)
                        })
                    }
                })
                
            }
            
        }
        
        return true
    }
    
}

typealias ListenerCB = (AnyObject) -> Void
typealias ResourceDictionary =  [String:ResourceItem]
typealias ResourceDictionaryCB = (ResourceDictionary) -> Void



struct CLBStreamOption {
    var isList:Bool
    var summarize:Bool
    var preloadResources:Bool
}

public struct PostSummaryInfo {
    
}



public struct Post  {
    var key:String
    var ts:Int?
    var summary:PostSummaryInfo?
    var resources:ResourceDictionary?
}

//STREAM MANAGER DEALS WITH STREAMS OF WELL DESCRIBED POSTS
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
    subscript(index:String, completion: @escaping ([AnyObject]) -> Void ) -> Int {
        var nid = id
        CLBIBridge.shared.setupListener(name:index, mode:"list") {
            data in
            //convert data to [Post]
            var posts = data as! [AnyObject]
            completion(posts)
        }
        return id
    }
    //POSSIBLY SUBSCRIPT SHOULD ACCESS WHAT'SIN CACHE

}

//SPECIFIC TO OBJECT STATE
public class ObjectState : NSObject {
    static var _shared:ObjectState!;
    static var shared:ObjectState {
        get {
            if _shared == nil {
                _shared = ObjectState()
            }
            return _shared
        }
    }
    var id = 0
    var last_state:[String:AnyObject]
    var listeners:[String:Array<(AnyObject) -> Void>]
    override init() {
        last_state = [String:AnyObject]()
        listeners = [String:Array<(AnyObject) -> Void>]()
        super.init()
    }
    func subscribe(_ index:String, _ field:String, completion: @escaping (AnyObject) -> Void ) -> Int {
        var nid = id
        id += 1

        if listeners[field] == nil {
            listeners[field] = Array<(AnyObject) -> Void>()
            CLBIBridge.shared.setupListener(name: "\(index)", mode: "object") {
                state in
                var dict = state as! [String:AnyObject]
                self.handleUpdates(dict: dict)
            }
        }
        listeners[field]?.append(completion)
        return id
    }
    func handleUpdates(dict:[String:AnyObject]) {
//        print(dict)
        for (key, value) in dict {
            var lv:AnyObject? = last_state[key]
            if lv == nil  {
                last_state[key] = value
                execListeners(path: key, value: value)
            }
        }
    }
    func execListeners(path:String, value: AnyObject) {
        var fns = listeners[path]
        if fns == nil {
            return
        }
        for l in fns! {
            l(value)
        }
    }

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

class ResourceManager : NSObject {
    static var _shared:ResourceManager!;
    static var shared:ResourceManager {
        get {
            if _shared == nil {
                _shared = ResourceManager()
            }
            return _shared
        }
    }
    var resources = [String:ResourceItem]();
    var wait_queue = [ResourceItem:[(ResourceItem) -> Void]]()
    override init() {
        super.init()
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
            //            completion()
        }
    }
    
    subscript(post:Post, completion: @escaping (Post) -> Void) -> Int {
        DispatchQueue.main.async {
            completion(post)
        }
        return 0
    }
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

    }
    
    func updateViewHierarchy(path:String, object:Any) {
        
    }
}


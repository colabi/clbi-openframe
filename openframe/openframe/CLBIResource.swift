/*
 
 Copyright ©Seth Piezas, 2017
 
 GPLv3
 
 */

import UIKit
import Photos
import HFSwipeView


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
typealias DataDictionary = [String:Datum]

public struct Datum {
    var id:String
    var type:String
    var value:AnyObject
    var ts:Int?
    var post:Post?
}




public struct CLBStreamOption {
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
    var datum:DataDictionary?
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
    var last_cached_data:[String:[AnyObject]]
    var id = 0
    override init() {
        listeners = [String:Array<ListenerCB>]()
        last_cached_data = [String:[AnyObject]]()
        super.init()
    }
    subscript(index:String, completion: @escaping ([AnyObject]) -> Void ) -> Int {
        var nid = id
        CLBIBridge.shared.setupListener(name:index, mode:"list") {
            data in
            //convert data to [Post]
            var posts = data as! [AnyObject]
            self.last_cached_data[index] = posts
            completion(posts)
        }
        if let lcd = last_cached_data[index] {
            completion(lcd)
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
    var last_cached_data:[String:AnyObject]
    override init() {
        last_state = [String:AnyObject]()
        listeners = [String:Array<(AnyObject) -> Void>]()
        last_cached_data = [String:AnyObject]()
        super.init()
    }
    func subscribe(_ index:String, _ field:String, completion: @escaping (AnyObject) -> Void ) -> Int {
        var nid = id
        id += 1
        var fullpath = "\(index)/\(field)"
        if listeners[field] == nil {
            listeners[field] = Array<(AnyObject) -> Void>()
            CLBIBridge.shared.setupListener(name: "\(index)", mode: "object") {
                state in
                var dict = state as! [String:AnyObject]
                self.last_cached_data[fullpath] = dict[field]
//                print(dict, self.listeners)
                self.handleUpdates(dict: dict)
            }
        }
        listeners[field]?.append(completion)
        if let lcd = last_cached_data[fullpath] {
            completion(lcd as AnyObject)
        }
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
    
    subscript(post:Post, mask:Int, completion: @escaping (Post) -> Void) -> Int {
        DispatchQueue.main.async {
            completion(post)
        }
        return 0
    }
}

//extension UIViewController {
//
//    func updateViewHierarchy(path:String, object:Any) {
//
//    }
//}



public struct Indexer {
    var _current:Int = 0
    var post:Post?
    var provider:ListProvider?
    //should keep ordered list here
    public var current:Int {
        set {
            _current = current
            post = provider?.ordered[current]
        }
        get {
            return _current
        }
    }
    
    public var count:Int {
        get {
            return (self.provider?.ordered!.count)!
        }
    }
    
    subscript(index:Int, relative:Bool, mask:Int, completion: @escaping (Indexer) -> Void) -> Indexer {
        var idx = index
        if relative {
            idx = _current + index
        }
        let indexer = Indexer(_current: idx, post: self.post, provider: self.provider)
        completion(indexer)
        return indexer
    }
    
    subscript(path:String) -> Datum? {
        var datalabel = (path as NSString).replacingOccurrences(of: "$current.", with:"")
        //if use current
        guard let data = post?.datum?[datalabel] else {
            return nil
        }
        return data
    }
}


public class ListProvider : NSObject, UITableViewDelegate {
    var path:String!
    
    var objects:[String:Post]!
    var ordered:[Post]!
    var views:[UIView]!
    var currentIdx:Int = 0
    public init(path:String) {
        super.init()
        self.path = path
        self.objects = [String:Post]()
        self.ordered = [Post]()
        self.views = [UIView]()
        StreamManager.shared[path] {
            posts in
            for o in posts {
                var key = o["key"] as! String
                var p = Post(key: key, ts: nil, summary: nil, datum: nil, resources: nil)
                self.objects[key] = p
            }
            self.ordered = self.objects.keys.map {
                self.objects[$0]!
            }
            for v in self.views {
                v.reloadData()
            }
        }
    }
    
    public var count:Int {
        get {
            return self.objects.count
        }
    }
    
    public var totalCount:Int {
        get {
            return -1
        }
    }
    
    var currentIndexer = Indexer()
    var view_indexers = [UIView:Indexer]()
    public var current:Int {
        set {
            currentIndexer.current = current
            let post = self.ordered[current]
            
            currentIndexer.post = post
        }
        get {return currentIndexer.current}
    }
    
    
    func register(view:UIView) -> Indexer {
        self.views.append(view)
        var newindex = Indexer()
        newindex.provider = self
        self.view_indexers[view] = newindex
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            view.reloadData()
        }
        return newindex
    }

    
    public subscript(index:Int, relative:Bool, completion: @escaping (Post) -> Void ) -> Bool {
        var idx = currentIndexer.current + index
        let offsetid = self.ordered[index].key
        self.doFullSubscript(index: offsetid, mask:1) {
            post in
            completion(post)
        }
        return true
    }
    
    public subscript(index:Int) -> String {
        var post = self.ordered[index]
        return post.key
    }
    
    public func doFullSubscript(index:String, mask:Int, completion: @escaping (Post) -> Void ) -> Bool {
        var post = self.objects[index]!
        if mask == 0 {
            completion(post)
            return false
        }
        
        ResourceManager.shared[post, mask] {
            post in
            completion(post)
        }
        return true
    }
    public subscript(view:UIView) -> Indexer {
        return view_indexers[view]!
    }

    /*
     public var provider:ListProvider? {
     set {
     print("descend tree and set data")
     var clbiviews = descend(subviews:subviews)
     for cv in clbiviews {
     if let sv = CLBLayoutEngine.shared.node_link_map[cv as! UIView] {
     if let datapath = sv.datasource {
     var data = provider?.getByPath(path:datapath)
     guard let d = data else {
     return
     }
     cv.configure(data: d) {
     //listen to post changes by view
     //possibly gang up changes
     post, dirtyarray in
     }
     }
     }
     }
     }
     get {
     return nil
     }
     }
     */
}

public class DataSourceAdapterManager : NSObject {
    static var _shared:DataSourceAdapterManager!;
    static var shared:DataSourceAdapterManager {
        get {
            if _shared == nil {
                _shared = DataSourceAdapterManager()
            }
            return _shared
        }
    }
    var adapters = [String:ListProvider]()
    var indexers = [UIView:Indexer]()
    var view_indexers = [UIView:ListProvider]()
    override public init() {
        
    }
    
    subscript(view:UIView) -> Indexer? {
        var lp = view_indexers[view]
        return lp?[view]
    }
    
    func register(view:UIView, forPath path:String) -> Indexer? {
        var lp = adapters[path]
        if lp == nil {
            lp = ListProvider(path:path)
            adapters[path] = lp
        }
        view_indexers[view] = lp
        var indexer = lp?.register(view: view)
        return indexer
    }
}


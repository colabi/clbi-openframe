import UIKit
import WebKit





public class CLBIGenericLoadViewController : UIViewController {
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        let label = UILabel(frame: UIScreen.main.bounds)
        label.text = "Generic Load Screen"
        label.textColor = .white
        self.view = label
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


public class QueryOptions {
    
}

public class DataView : UIView {
    
}


public class PostView : DataView {
    private var _data:Post?
    public var pdata:Post {
        set {
            configure(data: pdata)
        }
        get {
            return _data!
        }
    }
    func configure(data:Post) {
        
    }
    
}

protocol CLBIDataView {
    func configure(data:Post)
}


public class ListProvider : NSObject, UITableViewDelegate {
    var path:String!
    
    var objects:[String:Post]!
    var ordered:[Post]!
    var views:[UITableView]!
    public init(path:String) {
        super.init()
        self.path = path
        self.objects = [String:Post]()
        self.ordered = [Post]()
        self.views = [UITableView]()
        StreamManager.shared[path] {
            posts in
            for o in posts {
                var key = o["key"] as! String
                var p = Post(key: key, ts: nil, summary: nil, resources: nil)
                self.objects[key] = p
            }
            self.ordered = self.objects.keys.map {
                self.objects[$0]!
            }
            for v in self.views {
                print("view reload")
                v.reloadData()
            }
        }
    }
    
    var count:Int {
        get {
            return self.objects.count
        }
    }
    
    var totalCount:Int {
        get {
            return -1
        }
    }
    
    
    func append(view:UIView) {
        self.views.append(view as! UITableView)
    }
    
    subscript(index:Int, mask:Int, completion: @escaping (Post) -> Void ) -> Bool {
        var post = self.ordered[index]
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
}



open class SynchronizedViewController : UIViewController {
    var sources:[String:UIView]!
    var selectors:[String:String]!
    var viewmap:[UIView:ListProvider]!

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func viewDidLoad() {
        sources = [String:DataView]()
        selectors = [String:String]()
        viewmap = [UIView:ListProvider]()
    }
 


}

open class CLBIStyleViewController : UIViewController {
    open override var prefersStatusBarHidden: Bool {
        return false;
    }
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    open override func viewDidLoad() {
        setNeedsStatusBarAppearanceUpdate()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class BrowserStreamVC : SynchronizedViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {

    var browserCellClass:AnyClass?
    var userCellClass:AnyClass?
    var currentIdx:String = ""
    var height:CGFloat = 200

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        
    }
    
    override init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(CLBLayoutEngine.viewmap[tableView])
        let datacount = CLBLayoutEngine.viewmap[tableView]?.count ?? -1
//        print("TV: \(datacount)")
        return datacount
    }
    
    public  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //configure cell according to boilerplate
        guard let cell = cell as? CLBIDataView,
        let provider = CLBLayoutEngine.viewmap[tableView] else {
            return
        }
        provider[indexPath.row, 1] {
            post in
            //configure cell with post
            cell.configure(data: post)
        }
    }
    
    public  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //CAN POSIBLY CHANGE BY POST
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "$prototypecell", for: indexPath)
        return cell
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
        var urlstring = "http://192.168.111.8:8100/#/tabs/home/home"
//        var urlstring = "http://172.20.10.2:8100/#/tabs/home/home"
        load(URLRequest(url: URL(string: urlstring)!))
        self.navigationDelegate = self
        self.uiDelegate = self
        self.isHidden = true
        self.loadCB = completion

    }
    
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        print("webview: finished load")
    }
    
    public required override init?(coder:NSCoder) {
        super.init(coder:coder)
    }
 
}

@UIApplicationMain
open class CLBIAppDelegate : UIResponder, UIApplicationDelegate {
    public var window: UIWindow?
    public var mwv:MyxedWebView?
    open var options:[String:Any] {
        return [
            "views": [
                "statsview": "StatsView",
                "labelview": "LabelView",
                "chartview": "ChartView",
                "uiview": "TopView",
                "slideview": "SlideView"
            ],
            "root": "testview",
            "modes": [
                "initial": "#first",
                "initial.hidden": "#initial.hidden",
                "second": "#second"
            ],
            ] as [String:Any]
    }
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.window = UIWindow(frame:UIScreen.main.bounds)
        var gvc = CLBIGenericLoadViewController()
        self.window?.rootViewController = gvc
        self.window?.makeKeyAndVisible()
        CLBLayoutEngine.refreshTimeout = 100
        self.mwv = MyxedWebView(appname: "WeightList") {
            _ in
            UIStoryboard.instantiateWIBViewController(withURL: "https://wibui.herokuapp.com/layout", options: self.options) {
                vc in
                self.window?.rootViewController = vc;
                vc.view.insertSubview(self.mwv!, at: 0)
                vc.animateSubviews("initial",duration: 0)

            }
//            self.window?.rootViewController?.view.addSubview(self.mwv!)
            
        }
//        gvc.view = mwv
        CLBIBridge.shared.webview = self.mwv


        
        return true
        

    }
    
    class func registerServiceHandlers() -> [String:GenericBridgeFN]{
        return [String:GenericBridgeFN]()
    }
    
    public func applicationWillResignActive(_ application: UIApplication) {
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
    }
    
    public func applicationWillEnterForeground(_ application: UIApplication) {
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
    }
    
}


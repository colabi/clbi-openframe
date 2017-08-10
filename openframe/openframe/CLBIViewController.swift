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

public class TestCell : PostView {
    
}



public class ListProvider : NSObject, UITableViewDelegate {
    var path:String!
    
    var objects:[String:Post]!
    public init(path:String) {
        super.init()
        self.path = path
        self.objects = [String:Post]()
        StreamManager.shared[path] {
            posts in
            for o in posts {
                var key = o["key"] as! String
                var p = Post(key: key, ts: nil, summary: nil, resources: nil)
                self.objects[key] = p
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
    
    subscript(index:Int, mask:Int, completion: @escaping (Post) -> Void ) -> Bool {
        var post = self.objects.first!.value
        if mask == 0 {
            completion(post)
        }

        if (mask & 1) > 0 {
            ResourceManager.shared[post] {
                post in
                completion(post)
            }
        }
        return true
    }
}



open class SynchronizedViewController : UIViewController {
    var sources:[String:UIView]!
    var selectors:[String:String]!
    var viewmap:[UIView:ListProvider]!

    override open func viewDidLoad() {
        sources = [String:DataView]()
        selectors = [String:String]()
        viewmap = [UIView:ListProvider]()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    


    public func linkDataSource(path:String, selector:String, view:UIView) {
        sources[path] = view
        sources[selector] = view
        ObjectState.shared.subscribe("/users/$USER/apps/$APP/state", path) {
            pathvalue in
            var field = pathvalue as! String
            self.viewmap[view] = ListProvider(path:field)
            //refresh
            if view.isKind(of: UITableView.self) {
                (view as! UITableView).reloadData()
            }
        }
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

open class BrowserStreamVC : SynchronizedViewController, UITableViewDelegate, UIScrollViewDelegate {

    var browserCellClass:AnyClass?
    var userCellClass:AnyClass?
    var currentIdx:String = ""
    var height:CGFloat = 200

    public  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewmap[tableView]?.count ?? 0
    }
    
    public  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //configure cell according to boilerplate
        guard let cell = cell as? PostView,
        let provider = viewmap[tableView] else {
            return
        }
        provider[indexPath.row, 1] {
            post in
            //configure cell with post
            cell.data = post
        }
    }
    
    public  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.isKind(of: browserCellClass!) {
            var cell:UITableViewCell?
//            let cell: ParallaxCell = tableView.getReusableCellWithIdentifier(indexPath: indexPath)
            return cell!
        }

        return  UITableViewCell(frame:CGRect.zero)
    }

    
}


class MyxedWebView : WKWebView, WKUIDelegate, WKNavigationDelegate {
    
    var webview:WKWebView?
    var config:WKWebViewConfiguration!
    init(appname:String) {
        let frame = UIScreen.main.bounds
        super.init(frame: frame, configuration: WKWebViewConfiguration())
        self.configuration.userContentController.add(CLBIBridge.shared, name: "port")
        var urlstring = "http://172.20.10.2:8100/#/tabs/home/home"
        load(URLRequest(url: URL(string: urlstring)!))
        self.navigationDelegate = self
        self.uiDelegate = self
    }
    
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("webview: finished load")
        CLBIBridge.shared.webview = self
        
    }
    
    required override init?(coder:NSCoder) {
        super.init(coder:coder)
    }
 
}

open class CLBIAppDelegate : UIResponder, UIApplicationDelegate {
    public var window: UIWindow?
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
            "css": """
            """,
            "html": """
            <uiview>
            </uiview>
            """
        ] as [String:Any]
    }
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.window = UIWindow(frame:UIScreen.main.bounds)
        self.window?.rootViewController = CLBIGenericLoadViewController()
        self.window?.makeKeyAndVisible()
        CLBLayoutEngine.refreshTimeout = 100
        UIStoryboard.instantiateWIBViewController(withURL: "https://wibui.herokuapp.com/layout", options: options) {
            vc in
            DispatchQueue.main.async {
                self.window?.rootViewController = vc;
                vc.animateSubviews("second",duration: 0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    ObjectState.shared.subscribe("/users/$USER/apps/$APP/state", "browserstreamid") {
                        value in
                        print("object state: \(value)")
                    }
                    
                }
            }
        }
        

        
        return true
        

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


/*
 
 Copyright ©Seth Piezas, 2017
 
 GPLv3
 
 */

import UIKit
import WebKit
import PreviewTransition
import HFSwipeView

open class MyxedConfig {
    open static var appurl:String {
        return "http://192.168.111.8:8100/#/tabs/home/home"
//        return "http://10.0.0.88:8100/#/tabs/home/home"
//        return "http://172.20.10.2:8100/#/tabs/home/home"
    }
}



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

extension ParallaxCell {
    public func configure(data: Post) {
        print("configuring cell: ", data)
        if let image = UIImage(named: "a") {
            //            setImage(image, title: "title", subtitle: "subtitle", caption: "caption")
            setImage(image, title: "title")
            self.frame.size = CGSize(width: UIScreen.main.bounds.width  , height: 300)
        }
    }
}

public class SwipeDetailVC : UIViewController, UINavigationControllerDelegate, HFSwipeViewDataSource, HFSwipeViewDelegate {
    var backButton:UIButton!
    var header:UIView!
    var currentFullView: UIImageView?
    var didSetupConstraints: Bool = false
    init() {
        super.init(nibName: nil, bundle: nil)
        navigationItem.setHidesBackButton(true, animated: false)
        //possibly hook up listener to global current id pull
    }
    
    override public func updateViewConstraints() {
        if !didSetupConstraints {
            slideview!.swipeView.autoMatch(.height, to: .height, of: self.slideview!, withMultiplier: 0.95)
            slideview!.swipeView.autoMatch(.width, to: .width, of: self.slideview!)
            slideview!.swipeView.autoPinEdge(toSuperviewEdge: .leading)
            slideview!.swipeView.autoPinEdge(toSuperviewEdge: .trailing)
            slideview!.swipeView.autoAlignAxis(toSuperviewAxis: .horizontal)
            didSetupConstraints = true
        }
        super.updateViewConstraints()
    }


    fileprivate var fullItemSize: CGSize {
        return CGSize(width: UIScreen.main.bounds.size.width - 10, height: UIScreen.main.bounds.height)
    }
   
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public var prefersStatusBarHidden: Bool {
        return true;
    }
    
    var slideview:SlideView?
    override public func viewDidLoad() {
        setNeedsStatusBarAppearanceUpdate()
        view.frame = UIScreen.main.bounds
        slideview = getView(path: "/swipeview")
        slideview!.swipeView.dataSource = self
        slideview!.swipeView.delegate = self
        header = getView(path: "/swipeview/header")
        let gs_headertap = UITapGestureRecognizer(target: self, action: #selector(handlerHeaderTap(gesture: )))
        gs_headertap.numberOfTapsRequired = 1
        header.addGestureRecognizer(gs_headertap)
//        updateViewConstraints()
    }
    
    @objc func handlerHeaderTap(gesture:UITapGestureRecognizer) {
        navigationController?.popViewController(animated: true)
    }
    
    public func swipeViewItemDistance(_ swipeView: HFSwipeView) -> CGFloat {
        return 0
    }
    public func swipeViewItemSize(_ swipeView: HFSwipeView) -> CGSize {
        return fullItemSize
    }
    public func swipeViewItemCount(_ swipeView: HFSwipeView) -> Int {
//        let lp = CLBLayoutEngine.viewmap[slideview!]
        let lp = DataSourceAdapterManager.shared[slideview!]
        let datacount = lp?.count ?? 0
        print("swipeswipe data count: \(datacount)")
        return datacount
    }
    public func swipeView(_ swipeView: HFSwipeView, viewForIndexPath indexPath: IndexPath) -> UIView {
        var sz = CGSize(width: UIScreen.main.bounds.size.width-15, height: UIScreen.main.bounds.height - 10)
        let webview = UIImageView(frame:  CGRect(origin: .zero, size: sz))
        webview.backgroundColor = .red
        return webview
    }
    public func swipeView(_ swipeView: HFSwipeView, needUpdateViewForIndexPath indexPath: IndexPath, view: UIView) {
        print("needUpdateViewForIndexPath: \(indexPath.row)")
    }
    public func swipeView(_ swipeView: HFSwipeView, needUpdateCurrentViewForIndexPath indexPath: IndexPath, view: UIView) {
        print("updating current view: \(indexPath.row)")
        currentFullView = view as? UIImageView
        guard let view = view as? UIImageView
             else {
                return
        }
        let lp = DataSourceAdapterManager.shared[swipeView]
        view.backgroundColor = UIColor(hue: 0.5 + CGFloat(indexPath.row) * 0.1, saturation: 1, brightness: 1, alpha: 1)
        DataSourceAdapterManager.shared[swipeView]?[indexPath.row, false, 1] {//get absolute index post, mask level
            indexer in
            view.setIndexer(indexer) {
                status in
                print("status update for post")
            }
        }
//        provider[swipeView].setCurrent(indexPath.row, view)
//        provider.current = indexPath.row
//        provider[0, true] {
//            post in
//            self.view.provider = provider
//        }

        
    }
    
    
    
    public func swipeView(_ swipeView: HFSwipeView, didFinishScrollAtIndexPath indexPath: IndexPath) {
//        log("HFSwipeView(\(swipeView.tag)) -> \(indexPath.row)")
    }
    
    public func swipeView(_ swipeView: HFSwipeView, didSelectItemAtPath indexPath: IndexPath) {
//        log("HFSwipeView(\(swipeView.tag)) -> \(indexPath.row)")
    }
    
    public func swipeView(_ swipeView: HFSwipeView, didChangeIndexPath indexPath: IndexPath, changedView view: UIView) {
//        log("HFSwipeView(\(swipeView.tag)) -> \(indexPath.row)")
    }
}

public class StepBrowserVC : PTTableViewController {
    
    var currentIdx:String = ""
    var height:CGFloat = 200
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        navigationItem.setHidesBackButton(true, animated: false)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public var prefersStatusBarHidden: Bool {
        return true;
    }

    
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        let lp = CLBLayoutEngine.viewmap[tableView]
        let indexer = DataSourceAdapterManager.shared[tableView]
        let datacount = indexer?.count ?? 0
        return datacount
    }
    
    public override  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //configure cell according to boilerplate
        guard let cell = cell as? ParallaxCell else {
                return
        }
        DataSourceAdapterManager.shared[tableView]?[indexPath.row, false, 0] {//get absolute index post, mask level
            indexer in
            cell.setImage(UIImage(named: "a")!, title: "TITLE")
            
            //            cell.configure(data: indexer.post!) {
//                post, dirty in
//                print(post)
//            }
//            self.view.setIndexer(indexer) {
//                status in
//                print("status update for post")
//            }
        }
        
        

    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //CAN POSIBLY CHANGE BY POST
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "$prototypecell", for: indexPath)
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //PUSH
        print("select row")
        UIStoryboard.instantiateWIBViewController("wib_detail", options: nil) {
            detailvc in
            self.navigationController?.pushViewController(detailvc, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                detailvc.animateSubviews("initial",duration: 0)
            })
        }
    }
    
}





class CLBINavigationController : UINavigationController {
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)

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
            ] as [String:Any]
    }
    open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.window = UIWindow(frame:UIScreen.main.bounds)
        var gvc = CLBIGenericLoadViewController()
        let nav1 = CLBINavigationController()
        nav1.viewControllers = [gvc]
        self.window?.rootViewController = nav1
        self.window?.makeKeyAndVisible()
        CLBLayoutEngine.refreshTimeout = 100

        CLBIBridge.shared.webview = MyxedWebView(appname: "WeightList") {
            _ in
            UIStoryboard.instantiateWIBViewController("wib_browser", options: nil) {
                vc in
//                self.window?.rootViewController = vc;
                nav1.pushViewController(vc, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    vc.animateSubviews("initial",duration: 0)
                })
//                vc.view.insertSubview(self.mwv!, at: 0)

            }
//            self.window?.rootViewController?.view.addSubview(self.mwv!)
            
        }
        nav1.view.insertSubview(CLBIBridge.shared.webview!, at: 0)

        //        gvc.view = mwv
        CLBIBridge.shared.apphandlers = registerServiceHandlers()
        configureNavigationBar()

        return true
        

    }
    
    open func registerServiceHandlers() -> [String:openframe.GenericBridgeFN]? {
        return nil
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
    
    fileprivate func configureNavigationBar() {
        //transparent background
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().isTranslucent = true
        
        
        if let font = UIFont(name: "Avenir-medium" , size: 18) {
            UINavigationBar.appearance().titleTextAttributes = [
                NSAttributedStringKey.foregroundColor : UIColor.white,
                NSAttributedStringKey.font : font
            ]
        }
    }
    
}


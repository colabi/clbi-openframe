import UIKit
import WebKit

class MyxedWebView : WKWebView, WKUIDelegate, WKNavigationDelegate {
    
    var webview:WKWebView?
    var config:WKWebViewConfiguration!
    init(appname:String) {
        let frame = UIScreen.main.bounds
        super.init(frame: frame, configuration: WKWebViewConfiguration())
        self.configuration.userContentController.add(CLBIBridge.shared, name: "port")
        var urlstring = "http://192.168.111.8:8100/#/tabs/home/home"
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

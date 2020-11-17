import Foundation
import WebKit

open class ForemWebViewHistory: WKBackForwardList {
    var historyBackList = [WKBackForwardListItem]()

    open override var backList: [WKBackForwardListItem] {
        get {
            return historyBackList
        }
        set(list) {
            historyBackList = list
        }
    }

    open func clearBackList() {
        historyBackList.removeAll()
    }
}

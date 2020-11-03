if (Runtime && !Runtime.bodyObserver) {
    // Callback function to execute when mutations are observed
    const callback = function(mutationsList, observer) {
        for(const mutation of mutationsList) {
            if (mutation.type === 'attributes') {
                window.webkit.messageHandlers.body.postMessage({})
                return
            }
        }
    };

    // Create an observer instance linked to the callback function
    Runtime.bodyObserver = new MutationObserver(callback)
    const body = document.getElementsByTagName('body')[0]
    Runtime.bodyObserver.observe(body, { attributes: true, childList: false, subtree: false })
    window.webkit.messageHandlers.body.postMessage({})
}
null

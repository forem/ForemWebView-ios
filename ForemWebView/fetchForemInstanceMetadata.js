JSON.stringify({
    "name": document.querySelector("meta[property='forem:name']")["content"],
    "logo": document.querySelector("meta[property='forem:logo']")["content"],
    "domain": document.querySelector("meta[property='forem:domain']")["content"],
})

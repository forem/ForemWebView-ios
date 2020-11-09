const userStatus = document.getElementsByTagName('body')[0].getAttribute('data-user-status')
if (userStatus === "logged-in") {
    document.getElementsByTagName('body')[0].getAttribute('data-user')
}

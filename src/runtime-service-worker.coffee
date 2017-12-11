urlBase64ToUint8Array = (base64String) ->
    padding = '='.repeat (4 - base64String.length % 4) % 4
    base64 = (base64String + padding).replace(/\-/g, '+').replace(/_/g, '/')
    raw = window.atob base64
    outArray = new Uint8Array raw.length
    outArray[i] = raw.charCodeAt i for i in [0...raw.length] by 1
    return outArray

###
require('../magicworker/runtime-service-worker.coffee') {
    swFilename: require 'file-loader?name=sw.js!./base.sw.coffee'
    publicKey: store.get('cfg').pushPublicKey
    updateInterval: 0
    notification: true
    messaging: true
}
###
module.exports = (ops) ->
    console.log '1'
    window.addEventListener 'load', ->
        console.log '2'
        console.log 3

        ###
        TODO
        salvar a hora do ultimo registro e registrar novamente somente se estiver na hora de tentar
        executar uma atualizacao
        ###
        return console.log '[SW] No service worker support' unless navigator.serviceWorker
        console.log '[SW] Starting Service Worker...'
        navigator.serviceWorker.register ops.swFilename, {scope: './'}
        .then -> navigator.serviceWorker.ready
        .then (reg) ->
            response = {}
            Notification.requestPermission() if ops.notification
            response.registration = reg
            response.sync = reg.sync.register
            if ops.messaging
                response.sendMessage = (message) ->
                    ###
                    parece ter um jeito de enviar mensagens para TODOS os clientes
                    http://craig-russell.co.uk/2016/01/29/service-worker-messaging.html#.WUqECflTLeQ
                    ###
                    new Promise (resolve, reject) ->
                        mesgChannel = new MessageChannel()
                        mesgChannel.port1.onmessage = (event) ->
                            if event.data.error
                                reject event.data.error
                            else
                                resolve event.data

                        navigator.serviceWorker.controller.postMessage message, [mesgChannel.port2]

            if ops.publicKey
                # reg.pushManager.getSubscription()
                # .then (subs) ->
                #     # subs.unsubscribe()
                reg.pushManager.subscribe
                    userVisibleOnly: true
                    applicationServerKey: urlBase64ToUint8Array ops.publicKey
                .then (subs) ->
                    response.subscriptions = subs
                    return Promise.resolve response
            else
                return Promise.resolve response

        .catch (err) -> console.err '[SW] Registro falhou!!', err

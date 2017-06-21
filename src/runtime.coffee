urlBase64ToUint8Array = (base64String) ->
    padding = '='.repeat (4 - base64String.length % 4) % 4
    base64 = (base64String + padding).replace(/\-/g, '+').replace(/_/g, '/')
    raw = window.atob base64
    outArray = new Uint8Array raw.length
    outArray[i] = raw.charCodeAt i for i in [0...raw.length] by 1
    return outArray


module.exports =
    install: (Vue, ops) ->
        window.addEventListener 'load', ->
            if ops.wwFilename
                console.log 'Starting Web Worker...'
                wwWorker = new Worker ops.wwFilename
                # wwWorker.postMessage()  # XXX diziam que isso era necessario....
                wwWorker.addEventListener 'message', (event) -> Vue.hub.$emit event.data.tag, event.data.response
                Vue::$wwMessage = (tag, message) -> wwWorker.postMessage {tag: tag, message: message}

            ###
            TODO
            salvar a hora do ultimo registro e registrar novamente somente se estiver na hora de tentar
            executar uma atualizacao
            ###
            if ops.swFilename
                console.log 'Starting Service Worker...'
                navigator.serviceWorker?.register ops.swFilename, {scope: './'}
                .then -> navigator.serviceWorker.ready
                .then (reg) ->
                    Notification.requestPermission() if ops.notification
                    # Vue::swReg = reg
                    Vue::swSync = -> reg.sync.register 'syncUp'
                    if ops.messaging
                        Vue::swMessage = (message) ->
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
                            ops.cb? {register: reg, subscription: subs}
                            Vue.hub.$emit 'magicWorkerDone', {register: reg, subscription: subs}
                    else
                        ops.cb? {register: reg}
                        Vue.hub.$emit 'magicWorkerDone', {register: reg}

                .catch (err) -> console.warn '[SW] Registro falhou!!', err

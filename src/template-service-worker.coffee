# Definidos pelo plugin webpack MagicAssets na hora da montagem!
#
# CACHE_VERSION = ''
# OPTIONS = {}
# ASSETS = []

# ver exemplo no meio da pagina para ignorar o cache do servidor na hora de executar addAll
# https://jakearchibald.com/2016/caching-best-practices/


self.addEventListener 'install', (event) ->
    console.log '[SW] Installing...' if OPTIONS.debug >= 1

    p = caches.open CACHE_VERSION
    .then (cache) -> cache.addAll ASSETS
    .then -> if OPTIONS.fastMode then self.skipWaiting() else true

    event.waitUntil p


self.addEventListener 'activate', (event) ->
    console.log '[SW] Activated!!!' if OPTIONS.debug >= 1

    p = caches.keys()
    .then (kList) -> Promise.all kList.map (k) -> return caches.delete k unless k == CACHE_VERSION
    .then -> if OPTIONS.fastMode then self.clients.claim() else true

    event.waitUntil p


self.addEventListener 'fetch', (event) ->
    console.log '[SW] fetching:', event.request if OPTIONS.debug >= 2
    p = caches.match event.request
    .then (response) ->
        return response if response
        console.log '[SW] buscando dados na web:', event.request if OPTIONS.debug >= 1
        fetch event.request

    event.respondWith p


# exemplo = ->
#     new Promise (resolve, reject) ->
#         self.registration.showNotification "Olha eu aqui :)"
#         console.log '[SW] falhando...'
#         reject()


# self.addEventListener 'sync', (event) ->
#     console.log '[SW] 1'
#     if event.tag == 'teste'
#         console.log '[SW] 2'
#         event.waitUntil exemplo()
#     if event.tag == 'syncUp'
#         event.waitUntil Promise.resolve()


# self.addEventListener 'push', (event) ->
#     console.log '[SW] Push recebido!'


# self.addEventListener 'notificationclick', (event) ->
#     console.log '[SW] Clicou no aviso!';

#     event.notification.close()

#     # TODO ter certeza que isso funciona! (usar a seta)
#     event.waitUntil ->
#         clients.openWindow('https://developers.google.com/web/')


# self.addEventListener 'message', (event) ->
#     console.log event.data
#     switch event.data.cmd
#         when 'isso' then a = 1
#         when 'aquilo' then a = 2
#         else a = 0

#     self.clients.matchAll().then (client) ->
#         client[0].postMessage
#             command: 'logMessage'
#             error: null
#             response: a


###
worker = new WorkerCallback 1, require 'worker-loader?inline&fallback=false!./ww.coffee'
worker.execute 'set id', {pid: 1}, (res) -> console.log '---',res
###
module.exports = class WorkerCallback
    constructor: (@instances, MyWorker) ->
        @w = new MyWorker
        @jobs = {}
        @jid = 0
        @w.onmessage = (event) =>
            @jobs[event.data._jobid]? event.data
            delete @jobs[event.data._jobid]

    close: ->
        @w.postMessage {_job: 'bye', _jobid: 0}

    execute: (job, args, cb) ->

        if typeof args == 'function'
            @w.postMessage {_job: job, _jobid: @jid}
            @jobs[@jid++] = args
        else
            tmp = Object.assign {}, args, {_job: job, _jobid: @jid}
            @w.postMessage tmp
            @jobs[@jid++] = cb if cb

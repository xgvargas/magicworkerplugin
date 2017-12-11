
# ... webpack require here ...


self.addEventListener 'message', (event) ->

    console.log '[WW]>>',event.data

    switch event.data._job
        when 'bye'
            console.warn '[WW] Worker is about to die!'
            self.postMessage {tag: 'bye', response: true}
            self.close()

        when 'set id'
            pid = event.data.pid
            console.log '[WW] test', pid

            self.postMessage {_jobid: event.data._jobid, something: true}

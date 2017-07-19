module.exports =
  mixins: [require('./mixins/jobs')]
  data: ->
    status: null
  ready: ->
    if !@status?
      @updateStatus()
  methods:
    updateStatus: ->
      @getStatus({}, (data) =>
        console.log data
        @status = data
      )
    addWorker: (queue)->
      @setWorkers(queue.queue_name, {worker_max: (queue.worker_max + 1)}, (data) =>
        @updateStatus()
      )
    removeWorker: (queue)->
      @setWorkers(queue.queue_name, {worker_max: (queue.worker_max - 1)}, (data) =>
        @updateStatus()
      )
  template: """
<div class="cf mw8 center">
  <div v-for="queue in status" class="fl w-50 tc pv5">
    <div class="mw5 center bg-white br3 pa0 mv3 ba b--black-10 overflow-hidden">
      <div class="tc">
        <h1 class="f4">{{queue.queue_name}}</h1>
        <div class="mw3 bb bw1 b--light-green center"></div>
      </div>
      <ul class="list pl0 mt0 mb0 measure center tl">
        <li
          class="flex items-center lh-copy pa3 ph0-l bb b--black-10">
            <div class="flex-auto">
            <div class="cf ph2">
              <div class="fl w-80">
                Jobs Remaining:
              </div>
              <div class="fl tr w-20">
                {{queue.jobs_remaining}}
              </div>
            </div>
            </div>
        </li>
        <li
          class="flex items-center lh-copy pa3 ph0-l bb b--black-10">
            <div class="flex-auto">
            <div class="cf ph2">
              <div class="fl w-80">
                Pool:
              </div>
              <div class="fl tr w-20">
                {{queue.worker_max}}
              </div>
            </div>
            </div>
        </li>
        <li
          class="flex items-center lh-copy pa3 ph0-l bb b--black-10">
            <div class="flex-auto">
            <div class="cf ph2">
              <div class="fl w-80">
                Workers:
              </div>
              <div class="fl tr w-20">
                {{queue.workers.length}}
              </div>
            </div>
            </div>
        </li>
      </ul>
      <div class="cf">
        <div class="fl w-100 tc pv2 bg-washed-yellow bg-animate hover-bg-washed-red hover-white">
          Clear Jobs
        </div>
        <div @click="removeWorker(queue)" class="fl w-50 tc pv2 bg-washed-blue bg-animate hover-bg-washed-green hover-black">
          - Worker
        </div>
        <div @click="addWorker(queue)" class="fl w-50 tc pv2 bg-washed-blue bg-animate hover-bg-washed-green hover-black">
          + Worker
        </div>
        <div class="fl w-100 tc pv2 bg-washed-yellow bg-animate hover-bg-washed-red hover-white">
          Pause
        </div>
    </div>
  </div>
  </div>
</div>
"""

module.exports =
  mixins: [require('./mixins/jobs')]
  data: ->
    jobs: []
    job: false
  ready: ->
    @getFailed(@$route.params.queue, {}, (resp) =>
      @jobs = resp.data
    )
  methods:
    pickJob:(job) ->
      @getFailedDetails(@$route.params.queue, job, {}, (resp) =>
        @job = {job_data: resp.data, job_id: job}

      )
    goHome: ->
      @$router.go(
        {
          name: 'queue_list', 
          params: {queue: null}
        }
      )
  template: """
<div class="cf mw8 center">

  <nav class="p3 pa4-ns">
    <a @click="goHome()" class="link dim gray f6 f5-ns dib mr3">Back</a>
  </nav>

  <div class="cf">
    <div class="fl w-100 w-50-ns tc">
      <div class="ph3 ph5-ns">
        <ul class="list pl0 measure center">
          <li class="lh-copy pv3 bg-white br3">
            {{jobs.length}} failed jobs of 
          </li>
          <li v-for="job in jobs" 
              @click="pickJob(job)"
              class="lh-copy pv3 stripe-dark">
                {{job}}
          </li>
        </ul>
      </div>
    </div>

    <div v-if="job" class="fl w-100 w-50-ns tc">
      <div class="mw10 center bg-white br3 pa0 mv3 ba b--black-10 overflow-hidden">
      <div class="tc">
        <h1 class="f4">{{job.job_id}}</h1>
        <div class="mw3 bb bw1 b--light-green center"></div>
          <ul class="list pl0 measure center">
            <li v-for="row in job.job_data" 
                class="lh-copy pv3 stripe-dark">
                  {{row | json}}
            </li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</div>

  """

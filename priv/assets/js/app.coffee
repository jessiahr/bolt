Vue = require "vue"
VueRouter = require "vue-router"

Vue.use(require('vue-resource'));
Vue.use(VueRouter)

QueueList = Vue.component('queue-list', require('./app/queue_list'))
FailedJobs = Vue.component('failed-jobs', require('./app/failed_jobs'))


App = Vue.extend({})
router = new VueRouter({
  history: true,
  root: "/bolt"
})

router.map({
  '*': {
    component: QueueList
  },
  '/': {
    name: 'queue_list',
    component: QueueList
  },
  '/:queue/failed': {
  	name: 'failed_jobs',
  	component: FailedJobs
  }
})

router.start(App, '#app')

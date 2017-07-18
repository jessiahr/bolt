Vue = require "vue"
VueRouter = require "vue-router"

Vue.use(require('vue-resource'));
Vue.use(VueRouter)

Sandbox = Vue.component('sandbox', require('./app/sandbox'))


App = Vue.extend({})
router = new VueRouter({
  history: true,
  root: "/app"
  })
router.map({
  '/bolt': {
    name: 'audit_list',
    component: Sandbox
  }
})

router.start(App, '#app')

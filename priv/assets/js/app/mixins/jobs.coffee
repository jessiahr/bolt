module.exports =
  methods:
    getStatus: (params = {}, callback)->
      @$http['get'] "/bolt/api/status", params
        .then (resp) ->
          callback(resp.data)
        .catch (resp) ->
          console.log resp
    setWorkers: (queue_name, params = {}, callback)->
      @$http['post'] "/bolt/api/#{queue_name}/workers", params
        .then (resp) ->
          callback(resp.data)
        .catch (resp) ->
          console.log resp

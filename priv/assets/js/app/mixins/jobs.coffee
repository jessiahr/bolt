module.exports =
  methods:
    getStatus: (params = {}, callback)->
      @$http['get'] "/bolt/api/status", params
        .then (resp) ->
          callback(resp.data)
        .catch (resp) ->
          console.log resp
    poll: (params = {}, callback) ->
      http = @$http
      setInterval(->
        http['get'] "/bolt/api/status", params
          .then (resp) ->
            callback(resp.data)
          .catch (resp) ->
            console.log resp
      , 3500)
    setWorkers: (queue_name, params = {}, callback)->
      @$http['post'] "/bolt/api/#{queue_name}/workers", params
        .then (resp) ->
          callback(resp.data)
        .catch (resp) ->
          console.log resp

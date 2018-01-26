module.exports =
  methods:
    getStatus: (params = {}, callback)->
      @$http['get'] "/bolt/api/status", params
        .then (resp) ->
          callback(resp.data)
        .catch (resp) ->
          console.log resp
    getFailed: (queue_name, params = {}, callback)->
      @$http['get'] "/bolt/api/#{queue_name}/failed", params
        .then (resp) ->
          callback(resp)
        .catch (resp) ->
          console.log resp
    getFailedDetails: (queue_name, job_id, params = {}, callback)->
      @$http['get'] "/bolt/api/#{queue_name}/failed/#{job_id}", params
        .then (resp) ->
          callback(resp)
        .catch (resp) ->
          console.log resp
    setWorkers: (queue_name, params = {}, callback)->
      @$http['post'] "/bolt/api/#{queue_name}/workers", params
        .then (resp) ->
          callback(resp.data)
        .catch (resp) ->
          console.log resp

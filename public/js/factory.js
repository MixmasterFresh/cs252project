(function() {
  'use strict';

  app.factory('FetchFileFactory', ['$http',
    function($http) {
      var _factory = {};

      _factory.fetchFile = function(file) {
        return $http.post('/open', { file: file});
      };

      return _factory;
    }
  ]);

}());

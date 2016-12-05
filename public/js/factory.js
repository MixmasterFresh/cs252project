(function() {
  'use strict';

  app.factory('FetchFileFactory', ['$http',
    function($http) {
      var _factory = {};

      _factory.fetchFile = function(file) {
        return $http.post(encodeURIComponent(file));
      };

      return _factory;
    }
  ]);

}());

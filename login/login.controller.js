(function () {
    'use strict';

    angular
        .module('app')
        .controller('LoginController', LoginController);

    LoginController.$inject = ['$location'];
    function LoginController($location) {
        var vm = this;
        
        function login() {
            vm.dataLoading = true;
            function Login(vm.username, vm.password) {
                $http.post($location, JSON.stringify( { user: vm.uservm, passward: vm.password }))
                .then(function(response){
                    if(response.data[1] === 'success' || 'good'){
                        $location.path('/home');
                    }
                     else {
                        window.alert("login Fail");
                        vm.dataLoading = false;
                    }
                });     
            };
        };
    }

});


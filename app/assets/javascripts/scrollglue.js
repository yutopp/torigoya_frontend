(function(angular, undefined){
  'use strict';

  function fakeNgModel(initValue){
    return {
      $setViewValue: function(value){
        this.$viewValue = value;
      },
      $viewValue: initValue
    };
  }

  angular.module('luegg.directives', [])
  .directive('scrollGlue', function(){

    return {
      require: 'ngModel',
      scope: {
        options: '=',
        model: '=ngModel'
      },
      restrict: 'A',
      link: function(scope, $el, attrs){
        var el = $el[0];
        var ngModel = fakeNgModel(true);

        function scrollToBottom(){
          el.scrollTop = el.scrollHeight;
        }

        function shouldActivateAutoScroll(){
          // + 1 catches off by one errors in chrome
          return el.scrollTop + el.clientHeight + 1 >= el.scrollHeight;
        }

        scope.$watch("model", function() {
          if(ngModel.$viewValue){
            scrollToBottom();
          }
        });

        $el.bind('scroll', function(){
          scope.$apply(ngModel.$setViewValue.bind(ngModel, shouldActivateAutoScroll()));
        });
      }
    };
  });
}(angular));
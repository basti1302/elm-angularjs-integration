import angular from 'angular';

import elmAppDirective from '../elm-app-directive/elm-app-directive';
import '../style/app.css';


let app = () => {
  return {
    template: require('./app.html'),
    controller: 'AppCtrl',
    controllerAs: 'app'
  }
};

class AppCtrl {
  constructor() {
    this.repositoryUrl = 'https://github.com/basti1302/elm-angularjs-integration';
  }
}

const MODULE_NAME = 'app';

angular.module(MODULE_NAME, [])
  .directive('app', app)
  .directive('elmApp', elmAppDirective)
  .controller('AppCtrl', AppCtrl)


export default MODULE_NAME;
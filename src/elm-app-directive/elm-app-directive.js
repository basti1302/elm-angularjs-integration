'use strict';

const Elm = require('../elm/Main.elm');

let elmApp = null;

let elmAppDirective = () => {
  return {
    restrict: 'E',
    template: '<div id="elm-app"/>',
    link: link
  }
};

function link($scope, $element)  {

  // Embed Elm module
  elmApp = Elm.Main.embed($element[0]);

  /*
  elmApp.ports.openCattleInfoPage.subscribe((cattleIdAndList: any[]): void => {
      this.openCattleInfoPage(cattleIdAndList);
  });

  // the result function for the embedded "add cattle" <cfn-select-multi-reference>
  $scope.addAnimal = (cattle: ICattle) => {
      elmApp.ports.addAnimalById.send(cattle.id);
  };

  private convertLocalDateToUtcDate(date: number): number {
      let m = moment(date);
      let asUtcBasedDate = moment.utc({
          year: m.year(),
          month: m.month(),
          day: m.date()
      });
      return asUtcBasedDate.valueOf();
  }

  private openCattleInfoPage = (cattleIdAndList: any[]): void => {
      this.DnCattleInfoPageService.createCattleInfoPage(cattleIdAndList[0], cattleIdAndList[1], true);
  };
  */
}

export default elmAppDirective;

module Main exposing (main)

import AngularIntegrationTestPage
import Html exposing (..)


main : Program Never AngularIntegrationTestPage.Model AngularIntegrationTestPage.Msg
main =
    Html.program
        { init = AngularIntegrationTestPage.init
        , update = AngularIntegrationTestPage.update
        , subscriptions = AngularIntegrationTestPage.subscriptions
        , view = AngularIntegrationTestPage.view
        }

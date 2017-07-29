module AngularIntegrationTestPage exposing (..)

import AngularIntegration
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias Model =
    { maybeStringValue : Maybe String
    , nonNullableStringValue : String
    , maybeIntValue : Maybe Int
    , nonNullableIntValue : Int
    , maybeObject : Maybe ExampleObject
    }


type Msg
    = ChangeStringValueFromDirective (Maybe String)
    | ChangeStringValueFromElm String
    | DeleteStringValueFromElm
    | ChangeNonNullableStringValueFromDirective String
    | ChangeNonNullableStringValueFromElm String
    | ChangeIntValueFromDirective (Maybe Int)
    | ChangeIntValueFromElm String
    | ChangeNonNullableIntValueFromDirective Int
    | ChangeNonNullableIntValueFromElm String
    | DeleteIntValueFromElm
    | ChangeObjectFromDirective (Maybe ExampleObject)
    | ChangeObjectFromElm ExampleObject
    | DeleteObjectFromElm


init : ( Model, Cmd Msg )
init =
    ( { maybeStringValue = Nothing
      , nonNullableStringValue = ""
      , maybeIntValue = Nothing
      , nonNullableIntValue = 0
      , maybeObject = Nothing
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        _ =
            Debug.log "Elm-Angular-Integration: Elm#update" msg
    in
    case msg of
        ChangeStringValueFromDirective maybeString ->
            ( { model | maybeStringValue = maybeString }, Cmd.none )

        ChangeStringValueFromElm string ->
            ( { model | maybeStringValue = Just string }, Cmd.none )

        DeleteStringValueFromElm ->
            ( { model | maybeStringValue = Nothing }, Cmd.none )

        ChangeNonNullableStringValueFromDirective string ->
            ( { model | nonNullableStringValue = string }, Cmd.none )

        ChangeNonNullableStringValueFromElm string ->
            ( { model | nonNullableStringValue = string }, Cmd.none )

        ChangeIntValueFromDirective maybeInt ->
            ( { model | maybeIntValue = maybeInt }, Cmd.none )

        ChangeIntValueFromElm string ->
            ( { model | maybeIntValue = String.toInt string |> Result.toMaybe }
            , Cmd.none
            )

        ChangeNonNullableIntValueFromDirective int ->
            ( { model | nonNullableIntValue = int }, Cmd.none )

        ChangeNonNullableIntValueFromElm string ->
            ( { model
                | nonNullableIntValue =
                    String.toInt string |> Result.withDefault 0
              }
            , Cmd.none
            )

        DeleteIntValueFromElm ->
            ( { model | maybeIntValue = Nothing }, Cmd.none )

        ChangeObjectFromDirective maybeObject ->
            ( { model | maybeObject = maybeObject }, Cmd.none )

        ChangeObjectFromElm topic ->
            ( { model | maybeObject = Just topic }, Cmd.none )

        DeleteObjectFromElm ->
            ( { model | maybeObject = Nothing }, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ stringSection model.maybeStringValue
        , hr [] []

        --        , nonNullableStringSection model.nonNullableStringValue
        --        , hr [] []
        --        , integerSection model.maybeIntValue
        --        , hr [] []
        --        , nonNullableIntegerSection model.nonNullableIntValue
        --        , hr [] []
        --        , objectSection model.maybeObject
        ]


stringSection : Maybe String -> Html Msg
stringSection maybeStringValue =
    div []
        [ simpleStringDirective maybeStringValue
        , input
            [ id "simple-string-elm"
            , value (maybeStringValue |> Maybe.withDefault "")
            , onInput ChangeStringValueFromElm
            ]
            []
        , button [ onClick DeleteStringValueFromElm ] [ text "delete" ]
        ]


simpleStringDirective : Maybe String -> Html Msg
simpleStringDirective maybeStringValue =
    AngularIntegration.stringDirective
        "simple-string-directive"
        ChangeStringValueFromDirective
        { markup =
            "<input id=\"simple-string-ng\" ng-model=\"value\"></input><button ng-click=\"value = null\">delete</button>"
        , currentValue = maybeStringValue
        , scopeKey = Just "value"
        }
        |> AngularIntegration.withAttributes [ class "span6" ]
        |> AngularIntegration.build


nonNullableStringSection : String -> Html Msg
nonNullableStringSection string =
    div []
        [ simpleNonNullableStringDirective string
        , input
            [ value string
            , onInput ChangeNonNullableStringValueFromElm
            ]
            []
        ]


simpleNonNullableStringDirective : String -> Html Msg
simpleNonNullableStringDirective string =
    AngularIntegration.nonNullableStringDirective
        "simple-nn-string-directive"
        ChangeNonNullableStringValueFromDirective
        { markup =
            "<input ng-model=\"value\">"
        , currentValue = string
        , scopeKey = Just "value"
        }
        |> AngularIntegration.withAttributes [ class "span6" ]
        |> AngularIntegration.build


integerSection : Maybe Int -> Html Msg
integerSection maybeIntValue =
    let
        inputHandler =
            onInput ChangeIntValueFromElm

        attrs =
            case maybeIntValue of
                Just actualValue ->
                    [ value (actualValue |> toString)
                    , inputHandler
                    ]

                Nothing ->
                    [ onInput ChangeIntValueFromElm ]
    in
    div []
        [ simpleIntDirective maybeIntValue
        , input attrs []
        , button [ onClick DeleteIntValueFromElm ] [ text "delete" ]
        ]


simpleIntDirective : Maybe Int -> Html Msg
simpleIntDirective maybeIntValue =
    AngularIntegration.intDirective
        "simple-int-directive"
        ChangeIntValueFromDirective
        { markup =
            "<d-input-integer model=\"value\"></d-input-integer><button ng-click=\"value = null\">delete</button>"
        , currentValue = maybeIntValue
        , scopeKey = Just "value"
        }
        |> AngularIntegration.withAttributes [ class "span6" ]
        |> AngularIntegration.build


nonNullableIntegerSection : Int -> Html Msg
nonNullableIntegerSection int =
    div []
        [ simpleNonNullableIntDirective int
        , input
            [ value (toString int)
            , onInput ChangeNonNullableIntValueFromElm
            ]
            []
        ]


simpleNonNullableIntDirective : Int -> Html Msg
simpleNonNullableIntDirective int =
    AngularIntegration.nonNullableIntDirective
        "simple-nn-int-directive"
        ChangeNonNullableIntValueFromDirective
        { markup =
            "<d-input-integer model=\"value\"></d-input-integer>"
        , currentValue = int
        , scopeKey = Just "value"
        }
        |> AngularIntegration.withAttributes [ class "span6" ]
        |> AngularIntegration.build


type alias ExampleObject =
    { id : String
    , name : String
    , someValue : Int
    , someFlag : Bool
    }


someObject : ExampleObject
someObject =
    let
        exampleObject =
            Decode.decodeString decodeExampleObject
                "{\"id\":\"d8d2b742-76b8-4ea1-8c16-87a97a634b5b\",\"name\":\"Just a name\",\"someValue\":42,\"someFlag\":true}"
    in
    case exampleObject of
        Ok t ->
            t

        Err e ->
            Debug.crash e


objectSection : Maybe ExampleObject -> Html Msg
objectSection maybeObject =
    div []
        [ objectSelectDirective maybeObject
        , p [] [ maybeObject |> toString |> text ]
        , button [ onClick (ChangeObjectFromElm someObject) ] [ text "change" ]
        , button [ onClick DeleteObjectFromElm ] [ text "delete" ]
        ]


objectSelectDirective : Maybe ExampleObject -> Html Msg
objectSelectDirective maybeObject =
    AngularIntegration.customDirective
        "object-select"
        ChangeObjectFromDirective
        decodeMaybeExampleObject
        encodeMaybeExampleObject
        { markup =
            "<cfn-reference-box field=\"object\" name-field=\"object.title\" "
                ++ "result-target-object=\"object\" title=\"ExampleObject\" "
                ++ "type=\"cattleGroupObject\"></cfn-reference-box>"
        , currentValue = maybeObject
        , scopeKey = Just "object"
        }
        |> AngularIntegration.withAttributes [ class "span6" ]
        |> AngularIntegration.build


decodeExampleObject : Decoder ExampleObject
decodeExampleObject =
    Decode.map4 ExampleObject
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "someValue" Decode.int)
        (Decode.field "someFlag" Decode.bool)


decodeMaybeExampleObject : Decoder (Maybe ExampleObject)
decodeMaybeExampleObject =
    Decode.nullable decodeExampleObject


encodeMaybeExampleObject : Maybe ExampleObject -> Encode.Value
encodeMaybeExampleObject maybeObject =
    maybeObject
        |> encodeMaybe encodeExampleObject


encodeExampleObject : ExampleObject -> Encode.Value
encodeExampleObject exampleObject =
    Encode.object
        [ ( "id", Encode.string exampleObject.id )
        , ( "name", Encode.string exampleObject.name )
        , ( "someValue", Encode.int exampleObject.someValue )
        , ( "someFlag", Encode.bool exampleObject.someFlag )
        ]


encodeMaybe : (a -> Encode.Value) -> Maybe a -> Encode.Value
encodeMaybe encoder value =
    value
        |> Maybe.map encoder
        |> Maybe.withDefault Encode.null

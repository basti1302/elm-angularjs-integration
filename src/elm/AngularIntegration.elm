module AngularIntegration
    exposing
        ( DirectiveBuilder
        , DirectiveConfig
        , boolDirective
        , build
        , customDirective
        , dateDirective
        , extendAttributes
        , floatDirective
        , intDirective
        , nonNullableBoolDirective
        , nonNullableDateDirective
        , nonNullableFloatDirective
        , nonNullableIntDirective
        , nonNullableStringDirective
        , stringDirective
        , withAttributes
        )

{-| Infrastructure for embedding AngularJS directives into Elm.
-}

import Html exposing (Html)
import Html.AttributeBuilder as AB
import Html.Attributes
import Html.Events
import Json.Decode
import Json.Encode
import Native.AngularIntegration


{-| Basic configuration for embedding an AngularJS directive.
-}
type alias DirectiveConfig valueType =
    -- TODO Merge this type with DirectiveBuilder?
    { markup : String
    , currentValue : valueType
    , scopeKey : Maybe String
    }


{-| A type for gradually building an embedded AngularJS directive.
-}
type DirectiveBuilder valueType directiveResultType msg
    = DirectiveBuilder
        { domId : String
        , msg : directiveResultType -> msg
        , decoder : Json.Decode.Decoder directiveResultType
        , encoder : valueType -> Json.Encode.Value
        , config : DirectiveConfig valueType
        , nodeConstructor : List (Html.Attribute msg) -> List (Html.Html msg) -> Html.Html msg
        , attributes : AB.AttributeBuilder msg
        , isDate : Bool
        }


{-| Creates an empty DirectiveBuilder.
-}
newBuilder :
    String
    -> (directiveResultType -> msg)
    -> Json.Decode.Decoder directiveResultType
    -> (valueType -> Json.Encode.Value)
    -> DirectiveConfig valueType
    -> DirectiveBuilder valueType directiveResultType msg
newBuilder domId msg decoder encoder config =
    DirectiveBuilder
        { domId = domId
        , msg = msg
        , decoder = decoder
        , encoder = encoder
        , config = config
        , nodeConstructor = Html.span
        , attributes = AB.attributeBuilder
        , isDate = False
        }


{-| Add attributes to the DirectiveBuilder.
-}
withAttributes :
    List (Html.Attribute msg)
    -> DirectiveBuilder valueType directiveResultType msg
    -> DirectiveBuilder valueType directiveResultType msg
withAttributes attributes (DirectiveBuilder directiveBuilder) =
    DirectiveBuilder
        { directiveBuilder
            | attributes =
                directiveBuilder.attributes |> AB.addAttributes attributes
        }


{-| Add attributes to the DirectiveBuilder by using functions that extend an existing Html.AttributeBuilder, useful
for functions from `ReusableViewFunctions`.
-}
extendAttributes :
    (AB.AttributeBuilder msg -> AB.AttributeBuilder msg)
    -> DirectiveBuilder valueType directiveResultType msg
    -> DirectiveBuilder valueType directiveResultType msg
extendAttributes attributeBuilderMapper (DirectiveBuilder directiveBuilder) =
    DirectiveBuilder
        { directiveBuilder | attributes = attributeBuilderMapper directiveBuilder.attributes }


{-| Mark the directive as a component that handles date values. (Dates are somewhat special and the native side needs
to know which components handle dates.
-}
asDate : DirectiveBuilder valueType directiveResultType msg -> DirectiveBuilder valueType directiveResultType msg
asDate (DirectiveBuilder directiveBuilder) =
    DirectiveBuilder { directiveBuilder | isDate = True }


{-| Create a directive builder for a boolean attribute. The actual JavaScript run time type of the value in AngularJS' scope needs
to be boolean and it is the responsibility of the embedded directive to make sure that the value is either a boolean or null or
undefined, otherwise updating the Elm model will fail silently.
-}
boolDirective :
    String
    -> (Maybe Bool -> msg)
    -> DirectiveConfig (Maybe Bool)
    -> DirectiveBuilder (Maybe Bool) (Maybe Bool) msg
boolDirective domId msg config =
    newBuilder domId msg (readValue Json.Decode.bool) (encodeMaybe Json.Encode.bool) config


{-| Create a directive builder for a non-nullable boolean attribute. The actual JavaScript run time type of the value in
AngularJS' scope needs to be boolean and it is the responsibility of the embedded directive to make sure that the value is always
a boolean, otherwise updating the Elm model will fail silently. Note that for `nonNullableBoolDirective` the JS value also must
not be null or undefined - use `boolDirective` if this can happen.
-}
nonNullableBoolDirective :
    String
    -> (Bool -> msg)
    -> DirectiveConfig Bool
    -> DirectiveBuilder Bool Bool msg
nonNullableBoolDirective domId msg config =
    newBuilder domId msg (readNonNullableValue Json.Decode.bool) Json.Encode.bool config


{-| Create a directive builder for a float attribute. The actual JavaScript run time type of the value in AngularJS' scope needs
to be number and it is the responsibility of the embedded directive to make sure that the value is either a number or null or
undefined, otherwise updating the Elm model will fail silently.
-}
floatDirective :
    String
    -> (Maybe Float -> msg)
    -> DirectiveConfig (Maybe Float)
    -> DirectiveBuilder (Maybe Float) (Maybe Float) msg
floatDirective domId msg config =
    newBuilder domId msg (readValue Json.Decode.float) (encodeMaybe Json.Encode.float) config


{-| Create a directive builder for a non-nullable float attribute. The actual JavaScript run time type of the value in AngularJS'
scope needs to be number and it is the responsibility of the embedded directive to make sure that the value is always a number,
otherwise updating the Elm model will fail silently. Note that for `nonNullableFloatDirective` the JS value also must not be null
or undefined - use `floatDirective` if this can happen.
-}
nonNullableFloatDirective :
    String
    -> (Float -> msg)
    -> DirectiveConfig Float
    -> DirectiveBuilder Float Float msg
nonNullableFloatDirective domId msg config =
    newBuilder domId msg (readNonNullableValue Json.Decode.float) Json.Encode.float config


{-| Create a directive builder for an integer attribute. The actual JavaScript run time type of the value in AngularJS' scope
needs to be number and the value must be an integer. It is the responsibility of the embedded directive to make sure that the
value is either an integer number or null or undefined, otherwise updating the Elm model will fail silently.
-}
intDirective :
    String
    -> (Maybe Int -> msg)
    -> DirectiveConfig (Maybe Int)
    -> DirectiveBuilder (Maybe Int) (Maybe Int) msg
intDirective domId msg config =
    newBuilder domId msg (readValue Json.Decode.int) (encodeMaybe Json.Encode.int) config


{-| Create a directive builder for a non-nullable integer attribute. The actual JavaScript run time type of the value in
AngularJS' scope to be number and the value must be an integer. It is the responsibility of the embedded directive to make sure
that the value is always an integer number, otherwise updating the Elm model will fail silently. Note that for
`nonNullableIntDirective` the JS value also must not be null or undefined - use `intDirective` if this can happen.
-}
nonNullableIntDirective :
    String
    -> (Int -> msg)
    -> DirectiveConfig Int
    -> DirectiveBuilder Int Int msg
nonNullableIntDirective domId msg config =
    newBuilder domId msg (readNonNullableValue Json.Decode.int) Json.Encode.int config


{-| Create a directive builder for a string attribute. The actual JavaScript run time type of the value in AngularJS' scope
needs to be string. It is the responsibility of the embedded directive to make sure that the value is either a string
or null or undefined, otherwise updating the Elm model will fail silently.
-}
stringDirective :
    String
    -> (Maybe String -> msg)
    -> DirectiveConfig (Maybe String)
    -> DirectiveBuilder (Maybe String) (Maybe String) msg
stringDirective domId msg config =
    newBuilder domId msg (readValue Json.Decode.string) (encodeMaybe Json.Encode.string) config


{-| Create a directive builder for a non-nullable string attribute. The actual JavaScript run time type of the value in AngularJS'
scope needs to be string and it is the responsibility of the embedded directive to make sure that the value is always a string,
otherwise updating the Elm model will fail silently. Note that for `nonNullableStringDirective` the JS value also must not be null
or undefined - use `stringDirective` if this can happen.
-}
nonNullableStringDirective :
    String
    -> (String -> msg)
    -> DirectiveConfig String
    -> DirectiveBuilder String String msg
nonNullableStringDirective domId msg config =
    newBuilder domId msg (readNonNullableValue Json.Decode.string) Json.Encode.string config


{-| Create a directive builder for a date attribute.
-}
dateDirective :
    String
    -> (Maybe Int -> msg)
    -> DirectiveConfig (Maybe Int)
    -> DirectiveBuilder (Maybe Int) (Maybe Int) msg
dateDirective domId msg config =
    newBuilder domId msg (readValue Json.Decode.int) (encodeMaybe Json.Encode.int) config
        |> asDate


{-| Create a directive builder for a non-nullable date attribute.
-}
nonNullableDateDirective :
    String
    -> (Int -> msg)
    -> DirectiveConfig Int
    -> DirectiveBuilder Int Int msg
nonNullableDateDirective domId msg config =
    newBuilder domId msg (readNonNullableValue Json.Decode.int) Json.Encode.int config
        |> asDate


{-| Create a directive with custom encoders/decoders.
-}
customDirective :
    String
    -> (directiveResultType -> msg)
    -> Json.Decode.Decoder directiveResultType
    -> (valueType -> Json.Encode.Value)
    -> DirectiveConfig valueType
    -> DirectiveBuilder valueType directiveResultType msg
customDirective domId msg decoder encoder config =
    newBuilder domId msg decoder encoder config


readValue : Json.Decode.Decoder directiveResultType -> Json.Decode.Decoder (Maybe directiveResultType)
readValue typeDecoder =
    Json.Decode.nullable typeDecoder


readNonNullableValue : Json.Decode.Decoder directiveResultType -> Json.Decode.Decoder directiveResultType
readNonNullableValue typeDecoder =
    typeDecoder


{-| Build the actual embedded AngularJS directive from the DirectiveBuilder.
-}
build : DirectiveBuilder valueType directiveResultType msg -> Html msg
build (DirectiveBuilder builder) =
    let
        handler =
            createHandler builder.decoder builder.msg

        defaultAttributes =
            builder.attributes
                |> AB.addAttribute handler
                |> AB.addAttributes
                    [ Html.Attributes.id builder.domId
                    , Html.Attributes.attribute "data-markup" builder.config.markup
                    , Html.Attributes.attribute "data-is-date" (boolToAttributeString builder.isDate)
                    ]

        attributes =
            case builder.config.scopeKey of
                Just scopeKey ->
                    defaultAttributes
                        |> AB.addAttribute (Html.Attributes.attribute "data-scope-key" scopeKey)

                Nothing ->
                    defaultAttributes

        virtualDomNode =
            builder.nodeConstructor (AB.toAttributes attributes) []
    in
    nativeEmbed virtualDomNode (builder.encoder builder.config.currentValue)


createHandler :
    Json.Decode.Decoder directiveResultType
    -> (directiveResultType -> msg)
    -> Html.Attribute msg
createHandler decoder msg =
    Html.Events.on jsEventName <| Json.Decode.map msg decoder


nativeEmbed : Html msg -> valueType -> Html msg
nativeEmbed virtualDomNode currentValue =
    Native.AngularIntegration.embed virtualDomNode currentValue


jsEventName : String
jsEventName =
    "embedded_watch_triggered"


boolToAttributeString : Bool -> String
boolToAttributeString value =
    if value then
        "true"
    else
        "false"


encodeMaybe : (a -> Json.Encode.Value) -> Maybe a -> Json.Encode.Value
encodeMaybe encoder value =
    value
        |> Maybe.map encoder
        |> Maybe.withDefault Json.Encode.null

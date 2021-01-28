module Api exposing (ServerError(..), expectJsonWithBody, viewServerError)

import Element exposing (Element, column, el, fill, paragraph, spacing, text, width)
import Element.Font as Font
import Http exposing (Expect)
import Json.Decode as Decode exposing (Decoder, dict, field, index, int, list, map2, map8, maybe, string, value)
import Json.Encode as Encode



{--
  - This module is modeled after rtfeldman's elm-spa-example: https://github.com/rtfeldman/elm-spa-example/blob/master/src/Api.elm
  - However, it is only a start, I won't immediately follow his design, as I think it is slightly overkill for my use case
  - I essentially only have two "Endpoint":s so using that abstraction for me feels overkill: Login and Recipe
  - However, I do have some code that I need to share, and I put that here
--}


expectJsonWithBody : (Result ServerError a -> msg) -> Decoder a -> Expect msg
expectJsonWithBody toMsg decoder =
    Http.expectStringResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ urll ->
                    Err (otherError (Http.BadUrl urll) Nothing)

                Http.Timeout_ ->
                    Err (otherError Http.Timeout Nothing)

                Http.NetworkError_ ->
                    Err (otherError Http.NetworkError Nothing)

                Http.BadStatus_ { url, statusCode, statusText, headers } body ->
                    case statusCode of
                        401 ->
                            Err Unauthorized

                        _ ->
                            Err (otherError (Http.BadStatus statusCode) (Just body))

                Http.GoodStatus_ md body ->
                    case Decode.decodeString decoder body of
                        Ok value ->
                            Ok value

                        Err err ->
                            Err (otherError (Http.BadBody (Decode.errorToString err)) (Just body))



{--
  - ServerError
  - I specifically care about Unauthorized case - then we want to redirect to /login
  - otherwise, I keep the type opaque, modules are expected to basically just pass it to
  - viewServerError, if they wish to display the error to user
  --}


type ServerError
    = Unauthorized
    | Error OtherError


type OtherError
    = OtherError Http.Error (Maybe Body)


otherError : Http.Error -> Maybe Body -> ServerError
otherError httpError body =
    Error (OtherError httpError body)


type alias Body =
    String


httpErrorToString : Http.Error -> String
httpErrorToString err =
    case err of
        Http.BadUrl str ->
            "BadUrl " ++ str

        Http.Timeout ->
            "Timeout"

        Http.NetworkError ->
            "NetworkError"

        Http.BadStatus code ->
            "BadStatus " ++ String.fromInt code

        Http.BadBody str ->
            "BadBody " ++ str


viewServerError : String -> ServerError -> Element msg
viewServerError prefix serverError =
    let
        wrapError status errBody =
            column [ width fill, spacing 10 ]
                [ el [ Font.heavy ] (text prefix)
                , el [ Font.family [ Font.typeface "Courier New", Font.monospace ], Font.heavy ] (text status)
                , errBody |> Maybe.map (\err -> paragraph [ Font.family [ Font.typeface "Courier New", Font.monospace ] ] [ text err ]) |> Maybe.withDefault Element.none
                ]
    in
    case serverError of
        Error (OtherError httpError Nothing) ->
            wrapError (httpErrorToString httpError) Nothing

        Error (OtherError httpError (Just body)) ->
            wrapError (httpErrorToString httpError) (Just body)

        Unauthorized ->
            wrapError "401 Unauthorized" Nothing

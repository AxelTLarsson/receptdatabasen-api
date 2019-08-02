module Page.RecipeList exposing (Model, Msg, Status, init, toSession, update, view)

import Html exposing (..)
import Html.Attributes as Attr
import Http
import Json.Decode as Decoder exposing (Decoder, list)
import Recipe exposing (Preview, Recipe, previewDecoder)
import Recipe.Slug as Slug exposing (Slug)
import Route exposing (Route)
import Session exposing (Session)
import Url
import Url.Builder



-- MODEL


type alias Model =
    { session : Session, recipes : Status (List (Recipe Preview)) }


type Status recipes
    = Loading
    | Loaded recipes
    | Failed Http.Error


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , recipes = Loading
      }
    , getRecipes
    )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    case model.recipes of
        Loading ->
            { title = "Recipes"
            , content = text ""
            }

        Failed err ->
            { title = "Failed to load"
            , content = viewError err
            }

        Loaded recipes ->
            { title = "Recipes"
            , content =
                ul [] (List.map viewPreview recipes)
            }


viewPreview : Recipe Preview -> Html Msg
viewPreview recipe =
    let
        { title, id, createdAt } =
            Recipe.metadata recipe
    in
    li [] [ a [ Route.href (Route.Recipe title) ] [ text (Slug.toString title) ] ]


viewError : Http.Error -> Html Msg
viewError error =
    case error of
        Http.BadUrl str ->
            text str

        Http.NetworkError ->
            text "NetworkError"

        Http.BadStatus status ->
            text ("BadStatus " ++ String.fromInt status)

        Http.BadBody str ->
            text ("BadBody " ++ str)

        Http.Timeout ->
            text "Timeout"



-- UPDATE


type Msg
    = LoadedRecipes (Result Http.Error (List (Recipe Preview)))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoadedRecipes (Ok recipes) ->
            ( { model | recipes = Loaded recipes }, Cmd.none )

        LoadedRecipes (Err error) ->
            ( { model | recipes = Failed error }, Cmd.none )



-- HTTP


url : String
url =
    Url.Builder.crossOrigin "http://localhost:3000" [ "recipes" ] []


getRecipes : Cmd Msg
getRecipes =
    Http.get
        { url = url
        , expect = Http.expectJson LoadedRecipes previewsDecoder
        }


previewsDecoder : Decoder (List (Recipe Preview))
previewsDecoder =
    list <| Recipe.previewDecoder



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session

port module Main exposing (..)

import Html exposing (Html, text, div, img)
import Html.Attributes exposing (src)
import List exposing (map, filter, unzip, any)
import String exposing (startsWith)
import Dict exposing (toList)
import Html exposing (Html, text, div, img, button, table, thead, tbody, td, tr, th, input, h1, del, iframe)
import Html.Attributes exposing (class, type_, attribute, id)
import Components exposing (render, DropDownType(..), Search(..), DropDownComponent(..), IsRequired(..), AlertItem(..), Severity(..), AlertViewerComponent(..), ProgressBarComponent(..), LoaderComponent(..), GridAlign(..), ModalComponent(..), SideBarState(..), ButtonComponent(..), NavComponent(..), RenderType(..), Component(..), ComponentContext(..), GridComponent(..), Input(..), TableComponent(..), renderGrid, renderInput, renderTable)
import Http exposing (Error(..))
import Json.Decode exposing (Decoder, string, field, int, list, succeed, field)
import Json.Decode.Extra exposing (andMap)
import Json.Encode exposing (Value, object, list)
import Guards exposing (..)
import Tuple exposing (first)
import List.Extra exposing (unique)

-- Constants
suirenURL : URL
suirenURL = "http://suiren.io/"

ankiURL : URL
ankiURL = "https://ankiweb.net/decks/"

kanjidamageURL : URL
kanjidamageURL = "http://www.kanjidamage.com/"

-- Type Aliases
type alias RawHTML = String
type alias URL = String

type alias Term =
    { hirigana : String
    , kanji : String
    , english : String
    }

decodeTerm : Decoder Term
decodeTerm = succeed Term
                |> andMap (field "hirigana" string)
                |> andMap (field "kanji" string)
                |> andMap (field "english" string)

decodeTermList : Decoder (List Term)
decodeTermList = Json.Decode.list decodeTerm

-- Model

type alias Model =
    { pendingTerms : List Term
    , activeTerm : Maybe Term
    , baseUrl : URL
    , kdseed : Int
    }


-- Init


init : String -> ( Model, Cmd Msg )
init url =
    ( {
    pendingTerms = []
    , activeTerm = Nothing
    , baseUrl = url
    , kdseed = 1
    }, getTerms url)


getSuirenUrl : URL -> Maybe Term -> URL
getSuirenUrl url term = case term of
                            Nothing -> url
                            Just term -> url ++ "/words/" ++ term.kanji

getKanjiDamageUrl : URL -> Maybe Term -> Int -> URL
getKanjiDamageUrl url term seed = case term of
                            Nothing -> url
                            Just term -> url ++ "kanji/search/?utf8=✓" ++ "&q=" ++ getByIndex term.kanji seed

getByIndex : String -> Int -> String
getByIndex str ind = if ind <= String.length str then String.dropLeft (ind - 1) (String.left ind str)
                     else getByIndex str (ind - String.length str)


-- Msg

type Msg
    = RequestSuiren
    | GetHtmlFromSuiren RawHTML
    | GetHtmlFromSuirenAck (Result Http.Error (Term))
    | FlushTerms
    | SendTermsAck (Result Http.Error (Bool))
    | FlushAck (Result Http.Error (Bool))
    | GetTerms
    | TermsAck (Result Http.Error (List Term))
    | RequestAnki
    | GetHtmlFromAnki RawHTML
    | GetHtmlFromAnkiAck (Result Http.Error (Term))

-- Ports

port requestForSuirenHTML : String -> Cmd msg
port ackForSuirenHTML : (RawHTML -> msg) -> Sub msg

port requestForAnkiHTML: String -> Cmd msg
port ackForAnkiHTML : (RawHTML -> msg) -> Sub msg

-- Update

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
                RequestSuiren -> (model, requestForSuirenHTML "")
                GetHtmlFromSuiren rawHtml -> (model, parseSuirenHTML model.baseUrl rawHtml)
                GetHtmlFromSuirenAck (Ok term) -> ({model | pendingTerms = model.pendingTerms ++ [term]}, sendTerms model.baseUrl [term])
                GetHtmlFromSuirenAck (Err _) -> (model, Cmd.none)
                FlushTerms -> (model, requestFlush model.baseUrl)
                SendTermsAck (Ok bool) -> (model, Cmd.none)
                SendTermsAck (Err _) -> (model, Cmd.none)
                FlushAck (Ok bool)-> ({model | pendingTerms = []}, Cmd.none)
                FlushAck (Err _)-> (model, Cmd.none)
                GetTerms -> (model, getTerms model.baseUrl)
                TermsAck (Ok terms) -> ({model | pendingTerms = terms}, Cmd.none)
                TermsAck (Err _) -> ({model | pendingTerms = []}, Cmd.none)
                RequestAnki -> (model, requestForAnkiHTML "")
                GetHtmlFromAnki rawHtml -> (model, parseAnkiHTML model.baseUrl rawHtml)
                GetHtmlFromAnkiAck (Ok term) -> ({model | activeTerm = Just term, kdseed = model.kdseed + 1}, Cmd.none)
                GetHtmlFromAnkiAck (Err _) -> (model, Cmd.none)

-- HTTP

getTerms : URL -> Cmd Msg
getTerms baseRoute = Http.send TermsAck <| Http.get (baseRoute ++ "/terms") decodeTermList

parseSuirenHTML : URL -> RawHTML -> Cmd Msg
parseSuirenHTML baseRoute rawHtml = Http.send GetHtmlFromSuirenAck <| Http.post (baseRoute ++ "/process_suiren")
                            (Http.jsonBody <| (Json.Encode.object [("html", Json.Encode.string rawHtml)])) decodeTerm

parseAnkiHTML : URL -> RawHTML -> Cmd Msg
parseAnkiHTML baseRoute rawHtml = Http.send GetHtmlFromAnkiAck <| Http.post (baseRoute ++ "/process_anki")
                            (Http.jsonBody <| (Json.Encode.object [("html", Json.Encode.string rawHtml)])) decodeTerm

sendTerms : URL -> List Term -> Cmd Msg
sendTerms baseRoute terms = Http.send SendTermsAck <| Http.post (baseRoute ++ "/terms")
                            (Http.jsonBody <| Json.Encode.list <|
                                                map (\x -> Json.Encode.object [("hirigana", Json.Encode.string x.hirigana),
                                                            ("kanji", Json.Encode.string x.kanji),
                                                            ("english", Json.Encode.string x.english)]) terms) Json.Decode.bool

requestFlush : URL -> Cmd Msg
requestFlush baseRoute = Http.send FlushAck <| Http.post (baseRoute ++ "/terms/flush")
                            Http.emptyBody Json.Decode.bool

-- Subscriptions

subscriptions : Model -> Sub Msg
subscriptions model = Sub.batch [ackForSuirenHTML GetHtmlFromSuiren, ackForAnkiHTML GetHtmlFromAnki]

-- View

renderNav : Model -> Html Msg
renderNav model =
    render <| NavComp <| Nav Inverted [ HtmlComp <| text "Jam" ]


renderIFrame : URL -> String -> Html Msg
renderIFrame url strId = div [class "fluidMedia"] [iframe [src url, attribute "frameborder" "0", id strId] []]

renderTermHeader: List (TableComponent (Component Msg))
renderTermHeader = map (\x -> Entry Standard <| HtmlComp <| text x) ["kanji", "hirigana", "english"]

renderTerm : Term -> List (TableComponent (Component Msg))
renderTerm term = map (\x -> Entry Standard <| HtmlComp <| text x) [term.kanji, term.hirigana, term.english]

renderTerms : List Term -> List (TableComponent (Component Msg))
renderTerms terms = case terms of
                        [] -> []
                        x::xs -> [Row Standard <| renderTerm x] ++ renderTerms xs

renderModel : Model -> Html Msg
renderModel model =
    render <|
        GridComp
            (Grid Fluid
                [ GridRow Fluid
                    [ GridCol Fluid <|
                        HtmlComp <| renderIFrame (getSuirenUrl suirenURL model.activeTerm) "suiren"
                    ]
                , GridRow Fluid
                    [ GridCol Fluid <|
                        ButtonComp <| Button Success RequestSuiren <| HtmlComp <| text "Add Term To Pending"
                    ]
                , GridRow Fluid
                    [ GridCol Fluid <|
                        HtmlComp <| renderIFrame (getKanjiDamageUrl kanjidamageURL model.activeTerm model.kdseed) "kanjidamage"
                    ]
                , GridRow Fluid
                    [ GridCol Fluid <|
                        HtmlComp <| renderIFrame ankiURL "anki"
                    ]
                , GridRow Fluid
                    [ GridCol Fluid <|
                        ButtonComp <| Button Success RequestAnki <| HtmlComp <| text "Lookup Term"
                    ]
                , GridRow Fluid
                    [ GridCol Fluid <|
                        TableComp (NamedTable "Pending Terms" <|
                                    Table (Header renderTermHeader) <|
                                        (renderTerms model.pendingTerms)
                                  )
                    ]
                , GridRow Fluid
                    [ GridCol Fluid <|
                        ButtonComp <| Button Success FlushTerms <| HtmlComp <| text "Flush Pending"
                    ]
                ]
            )



-- View
view : Model -> Html Msg
view model =
    div [] [
        renderNav model
        , div [ class "ui container" ]
            [
            renderModel model
            ]
        ]

-- main
main : Program String Model Msg
main =
    Html.programWithFlags
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }

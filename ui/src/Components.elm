module Components exposing (..)

import Html exposing (Html, div, input, tbody, thead, tfoot, th, td, table, tr, text, h2, a, button, Attribute, i, option, select)
import Html.Attributes exposing (class, placeholder, type_, value, attribute, width, style, title, multiple, name, selected)
import Html.Events exposing (onInput, onClick, on)
import List exposing (map)
import Json.Decode
import Guards exposing (..)


--- Custom Attribs ---


datavalue : String -> Attribute msg
datavalue string =
    attribute "data-value" string


datatotal : String -> Attribute msg
datatotal string =
    attribute "data-total" string


datapercent : String -> Attribute msg
datapercent string =
    attribute "data-percent" string



--- COMPONENT ---


type ComponentContext
    = Standard
    | Success
    | Fail
    | Warning


contextToStringBtn : ComponentContext -> String
contextToStringBtn cc =
    case cc of
        Standard ->
            ""

        Success ->
            "positive"

        Fail ->
            "negative"

        Warning ->
            "yellow"


contextToStringTable : ComponentContext -> String
contextToStringTable cc =
    case cc of
        Standard ->
            ""

        Success ->
            "positive"

        Fail ->
            "error"

        Warning ->
            "warning"


type Component msg
    = GridComp (GridComponent (Component msg))
    | TableComp (TableComponent (Component msg))
    | InputComp (Input msg (Component msg))
    | ClickableComp (Clickable msg (Component msg))
    | NavComp (NavComponent (Component msg))
    | SideBarComp (SideBarComponent (Component msg))
    | ButtonComp (ButtonComponent msg (Component msg))
    | ModalComp (ModalComponent (Component msg))
    | HtmlComp (Html msg)
    | LoaderComp (LoaderComponent (Component msg))
    | ProgressBarComp (ProgressBarComponent (Component msg))
    | AlertViewerComp (AlertViewerComponent msg (Component msg))
    | DropDownComp (DropDownComponent msg)


render : Component msg -> Html msg
render component =
    case component of
        GridComp comp ->
            renderGrid comp

        TableComp comp ->
            renderTable comp

        InputComp comp ->
            renderInput comp

        HtmlComp x ->
            x

        ClickableComp comp ->
            renderClickable comp

        NavComp comp ->
            renderNav comp

        SideBarComp comp ->
            renderSidebar comp

        ButtonComp comp ->
            renderButton comp

        ModalComp comp ->
            renderModal comp

        LoaderComp comp ->
            renderLoader comp

        ProgressBarComp comp ->
            renderProgressBar comp

        AlertViewerComp comp ->
            renderAlertViewer comp

        DropDownComp comp ->
            renderDropdown comp



--- SIDEBAR ---


type RenderType
    = Normal
    | Inverted


type SideBarState
    = Hidden
    | Visible


type SideBarComponent component
    = LeftSideBar RenderType SideBarState component
    | RightSideBar RenderType SideBarState component
    | UpSideBar RenderType SideBarState component
    | DownSideBar RenderType SideBarState component


rendertypeToString : RenderType -> String
rendertypeToString typ =
    case typ of
        Normal ->
            ""

        Inverted ->
            "inverted"


stateToString : SideBarState -> String
stateToString state =
    case state of
        Hidden ->
            ""

        Visible ->
            "visible"


renderSidebar : SideBarComponent (Component msg) -> Html msg
renderSidebar sidebar =
    case sidebar of
        LeftSideBar typ state component ->
            div [ class <| "ui left sidebar " ++ (rendertypeToString typ) ] [ render component ]

        RightSideBar typ state component ->
            div [ class <| "ui right sidebar " ++ (rendertypeToString typ) ] [ render component ]

        UpSideBar typ state component ->
            div [ class <| "ui up sidebar " ++ (rendertypeToString typ) ] [ render component ]

        DownSideBar typ state component ->
            div [ class <| "ui down sidebar " ++ (rendertypeToString typ) ] [ render component ]



--- DROPDOWN ---


type DropDownType
    = Simple
    | Multi


type Search
    = NoSearch
    | WithSearch


type DropDownComponent msg
    = DropDown DropDownType Search (String -> msg) (List String) String


renderTerms : List String -> List (Html msg)
renderTerms terms =
    case terms of
        [] ->
            []

        x :: xs ->
            [ option [ value x ] [ text x ] ] ++ renderTerms xs


onChange : (String -> msg) -> Attribute msg
onChange handler =
    on "change" <| Json.Decode.map handler <| Json.Decode.at [ "target", "value" ] Json.Decode.string


renderDropdown : DropDownComponent msg -> Html msg
renderDropdown dropdown =
    case dropdown of
        DropDown Simple NoSearch msg terms val ->
            select [ class "ui fluid dropdown", onChange msg ] <| renderTerms <| [ "" ] ++ terms

        DropDown Simple WithSearch msg terms val ->
            select [ class "ui fluid search dropdown", multiple True, onChange msg ] <| renderTerms <| [ "" ] ++ terms

        DropDown Multi NoSearch msg terms val ->
            select [ class "ui fluid dropdown", onChange msg ] <| renderTerms <| [ "" ] ++ terms

        DropDown Multi WithSearch msg terms val ->
            select [ name "drop", class "ui fluid search dropdown", multiple True, onChange msg ] <| renderTerms <| [ "" ] ++ terms



--- NAV ---


type NavComponent component
    = Nav RenderType (List component)


renderNav : NavComponent (Component msg) -> Html msg
renderNav nav =
    case nav of
        Nav typ components ->
            div [ class <| "ui menu " ++ (rendertypeToString typ) ] <| map (\c -> a [ class "item" ] [ render c ]) components



--- BUTTON ---


type ButtonComponent msg component
    = Button ComponentContext msg component
    | DualButton ComponentContext msg ComponentContext msg component component


renderButton : ButtonComponent msg (Component msg) -> Html msg
renderButton btn =
    case btn of
        Button cc msgCons component ->
            button [ class <| "ui button " ++ (contextToStringBtn cc), onClick msgCons ] [ render component ]

        DualButton cc1 msgCons1 cc2 msgCons2 comp1 comp2 ->
            div [ class "ui buttons" ] [ renderButton <| Button cc1 msgCons1 comp1, div [ class "or" ] [], renderButton <| Button cc2 msgCons2 comp2 ]



--- LOADER ---


type LoaderComponent component
    = Loader SideBarState component


loaderStateToString : SideBarState -> String
loaderStateToString state =
    case state of
        Hidden ->
            ""

        Visible ->
            "active"


renderLoader : LoaderComponent (Component msg) -> Html msg
renderLoader loader =
    case loader of
        Loader state component ->
            div [ class <| "ui dimmer " ++ loaderStateToString state ] [ div [ class <| "ui modal " ++ loaderStateToString state ] [ div [ class "ui text loader" ] [ render component ] ] ]



--- ALERTVIEWER ---


type Severity
    = Message
    | Warn
    | Exception


type AlertItem msg component
    = AlertItem Severity msg component


type AlertViewerComponent msg component
    = EmptyAlertViewer
    | AlertViewer (List (AlertItem msg component))


renderAlert : AlertItem msg (Component msg) -> Html msg
renderAlert alert =
    case alert of
        AlertItem severity onClose component ->
            case severity of
                Message ->
                    div [ class "ui positive message" ] [ i [ class "close icon", onClick onClose ] [], render component ]

                Warn ->
                    div [ class "ui yellow message" ] [ i [ class "close icon", onClick onClose ] [], render component ]

                Exception ->
                    div [ class "ui negative message" ] [ i [ class "close icon", onClick onClose ] [], render component ]


renderAlertViewer : AlertViewerComponent msg (Component msg) -> Html msg
renderAlertViewer alertViewer =
    case alertViewer of
        EmptyAlertViewer ->
            div [] []

        AlertViewer alerts ->
            div [] <| map renderAlert alerts



--- POPUP ---
--TODO Implement Popup
---
--- PROGRESSBAR ---
--TODO Style Better, Looks Ugly


type ProgressBarComponent component
    = ProgressBar SideBarState CurrentValue MaxValue component



---type ProgressBarFn num = Abs AbsoluteProgressBarFn num | Rel RelativeProgressBarFn num
---type alias AbsoluteProgressBarFn numeric = (numeric -> numeric)
---type alias RelativeProgressBarFn numeric = (numeric -> numeric -> numeric)


type alias CurrentValue =
    Int


type alias MaxValue =
    Int


pbStateToString : SideBarState -> String
pbStateToString state =
    case state of
        Hidden ->
            ""

        Visible ->
            "active"


renderProgressBar : ProgressBarComponent (Component msg) -> Html msg
renderProgressBar pb =
    case pb of
        ProgressBar state cv mv component ->
            div [ class <| "ui dimmer " ++ pbStateToString state ] [ div [ class <| "ui modal " ++ pbStateToString state ] [ div [ class "ui active indicating progress", datavalue <| toString cv, datatotal <| toString mv, datapercent <| toString <| toPercent cv mv ] [ div [ class "bar", style [ ( "width", toString (toPercent cv mv) ++ "%" ) ] ] [ div [ class "progress" ] [] ], render component ] ] ]


toPercent : Int -> Int -> Float
toPercent a b =
    100 * (toFloat a / (toFloat b))



--- GRID ---


type GridAlign
    = Fluid
    | One
    | Two
    | Three
    | Four
    | Five
    | Six
    | Seven
    | Eight
    | Nine
    | Ten
    | Eleven
    | Twelve
    | Thirteen
    | Fourteen
    | Fifteen
    | Sixteen


type GridLayout
    = TopDown
    | BottomUp


type GridComponent component
    = Grid GridAlign (List (GridComponent component))
    | GridRow GridAlign (List (GridComponent component))
    | GridCol GridAlign component


renderGrid : GridComponent (Component msg) -> Html msg
renderGrid gridComponent =
    case gridComponent of
        Grid ga listRow ->
            div [ class <| "ui celled grid " ++ getGridAlign ga TopDown ] <| map renderGrid listRow

        GridRow ga listCol ->
            div [ class <| "row " ++ getGridAlign ga TopDown ] <| map renderGrid listCol

        GridCol ga component ->
            div [ class <| "column " ++ getGridAlign ga BottomUp ] <| [ render component ]


getGridAlign : GridAlign -> GridLayout -> String
getGridAlign ga gl =
    let
        app =
            case gl of
                TopDown ->
                    " column"

                BottomUp ->
                    " wide"
    in
        case ga of
            Fluid ->
                ""

            One ->
                "one" ++ app

            Two ->
                "two" ++ app

            Three ->
                "three" ++ app

            Four ->
                "four" ++ app

            Five ->
                "five" ++ app

            Six ->
                "six" ++ app

            Seven ->
                "seven" ++ app

            Eight ->
                "eight" ++ app

            Nine ->
                "nine" ++ app

            Ten ->
                "ten" ++ app

            Eleven ->
                "eleven" ++ app

            Twelve ->
                "twelve" ++ app

            Thirteen ->
                "thirteen" ++ app

            Fourteen ->
                "fourteen" ++ app

            Fifteen ->
                "fifteen" ++ app

            Sixteen ->
                "sixteen" ++ app



--- CLICKABLE ---


type Clickable msg component
    = Clickable msg component


renderClickable : Clickable msg (Component msg) -> Html msg
renderClickable comp =
    let
        (Clickable msgCons component) =
            comp
    in
        div [ onClick msgCons ] [ render component ]



--- MODAL ---


type ModalComponent component
    = Modal SideBarState component


modalStateToString : SideBarState -> String
modalStateToString state =
    case state of
        Hidden ->
            ""

        Visible ->
            "active"


renderModal : ModalComponent (Component msg) -> Html msg
renderModal comp =
    case comp of
        Modal state component ->
            div [ class <| "ui dimmer " ++ (modalStateToString state) ] [ div [ class <| "ui modal " ++ (modalStateToString state) ] [ render component ] ]



--- INPUT ---


type alias Placeholder =
    String


type alias MsgConstructor msg =
    String -> String -> msg


type IsRequired
    = NotRequired
    | Required String


type Input msg component
    = Input Placeholder IsRequired (MsgConstructor msg) String


renderInput : Input msg (Component msg) -> Html msg
renderInput component =
    let
        (Input ph req msg val) =
            component
    in
        case req of
            NotRequired ->
                div [ class "ui input container" ]
                    [ input [ type_ "text", placeholder ph, value val, onInput <| msg ph ] []
                    ]

            Required string ->
                string
                    /= ""
                    => div [ class "ui input container" ]
                        [ input [ type_ "text", placeholder ph, value val, onInput <| msg ph ] []
                        ]
                    |= div [ class "ui error input container" ]
                        [ input [ type_ "text", placeholder ph, value val, onInput <| msg ph ] []
                        ]



--- TABLE ---


type TableComponent component
    = Table (TableComponent component) (List (TableComponent component))
    | Header (List (TableComponent component))
    | Row ComponentContext (List (TableComponent component))
    | Footer (List (TableComponent component))
    | Entry ComponentContext component
    | DescEntry String ComponentContext component
    | NamedTable String (TableComponent component)



--- Renders a Semantic UI Table ---


renderTable : TableComponent (Component msg) -> Html msg
renderTable component =
    case component of
        Table header rowsList ->
            table [ class "ui celled table" ] <| [ renderTable header ] ++ [ tbody [] <| map renderTable rowsList ]

        Header entriesList ->
            thead [] <| map (\e -> th [] <| [ renderTable e ]) entriesList

        Footer entriesList ->
            tfoot [] <| map (\e -> th [] <| [ renderTable e ]) entriesList

        Row cc entriesList ->
            tr [ class <| contextToStringTable cc ] <| map (\e -> td [] <| [ renderTable e ]) entriesList

        Entry cc comp ->
            div [ class <| contextToStringTable cc ] [ render comp ]

        DescEntry description cc comp ->
            div [ class <| contextToStringTable cc, title <| description ] [ render comp ]

        NamedTable name comp ->
            div [] [ h2 [ class "ui header" ] [ text name ], renderTable comp ]

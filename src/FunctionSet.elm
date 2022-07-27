module FunctionSet exposing (..)

import Url as Url
import Url.Builder as Url
import Json.Decode as Decode
import Json.Decode exposing (andThen, succeed, fail)
import Json.Encode as Encode
import FunctionSet.HaskellPrelude exposing (haskellPrelude)
import FunctionSet.LensOperators exposing (lensOperators)
import FunctionSet.Plutarch exposing (plutarch)

type FunctionSet
  = HaskellPrelude
  | JustTraverse
  | LensOperators
  | Plutarch

availableSets : List FunctionSet
availableSets = [ Plutarch, HaskellPrelude, JustTraverse, LensOperators ]

getAllFuncs : FunctionSet -> List String
getAllFuncs fs = case fs of
  HaskellPrelude -> haskellPrelude
  JustTraverse ->
    [ "traverse :: Traversable t => Applicative f => (a -> f b) -> t a -> f (t b)"
    ]
  LensOperators -> lensOperators
  Plutarch -> plutarch

asKey : FunctionSet -> String
asKey fs = case fs of
  HaskellPrelude -> "haskell-prelude"
  JustTraverse -> "just-traverse"
  LensOperators -> "lens-operators"
  Plutarch -> "plutarch"

fromKey : String -> Maybe FunctionSet
fromKey s = case s of
  "haskell-prelude" -> Just HaskellPrelude
  "just-traverse" -> Just JustTraverse
  "lens-operators" -> Just LensOperators
  "plutarch" -> Just Plutarch
  _                -> Nothing

functionSetEncoder fs =
  asKey fs
    |> Encode.string

functionSetDecoder : Decode.Decoder FunctionSet
functionSetDecoder =
  let
      withString v =
         case fromKey v of
           Just fs -> succeed fs
           Nothing -> fail "unrecognized function set"
   in
      Decode.string
        |> andThen withString

displayName : FunctionSet -> String
displayName fs = case fs of
  HaskellPrelude -> "the haskell prelude"
  JustTraverse -> "just traverse"
  LensOperators -> "lens operators"
  Plutarch -> "plutarch"

url : FunctionSet -> String
url fs = case fs of
  HaskellPrelude -> "https://hackage.haskell.org/package/base/docs/Prelude.html"
  JustTraverse -> "https://hackage.haskell.org/package/base/docs/Prelude.html#v:traverse"
  LensOperators -> "https://hackage.haskell.org/package/lens/docs/Control-Lens.html"
  Plutarch -> "https://github.com/Plutonomicon/plutarch-plutus"

mkFunctionUrl : FunctionSet -> String -> String
mkFunctionUrl fs name = case fs of
  HaskellPrelude ->
    Url.custom
      (Url.CrossOrigin "https://hackage.haskell.org")
      ["package", "base", "docs", "Prelude.html"]
      []
      (Just ("v:" ++ haddockEscape name))
  JustTraverse ->  mkFunctionUrl HaskellPrelude "traverse"
  LensOperators -> url LensOperators -- todo handle reexported names correctly
  Plutarch -> url Plutarch

haddockEscape : String -> String
haddockEscape name =
  let
      escapeChar p char =
        if p char
        then String.fromChar char
        else "-" ++ String.fromInt (Char.toCode char) ++ "-"
      isLegal char =
        case char of
          ':' -> True
          '_' -> True
          '.' -> True
          _   -> Char.isAlphaNum char
   in
      case String.toList name of
        (c :: cs) -> String.concat (escapeChar Char.isAlpha c :: List.map (escapeChar isLegal) cs)
        _ -> name

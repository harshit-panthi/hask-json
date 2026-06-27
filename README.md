json-parser

A JSON parser written in Haskell using Megaparsec, producing values of the json-ast AST type.

Features


Parses all JSON value types — objects, arrays, strings, numbers, booleans, and null
Exact numeric representation via Scientific — no floating-point rounding errors
Full string escape sequence support including \n, \t, \\, \", \/, and \uXXXX Unicode escapes
Unicode scalar value validation — surrogate halves are rejected with a clear error message
Human-readable parse errors with line and column information


Usage

haskellimport JSONParser (parseJSON)
import qualified Data.Text.IO as TIO

main :: IO ()
main = do
  input <- TIO.readFile "example.json"
  case parseJSON input of
    Left  err -> putStrLn $ "Parse error: " <> err
    Right val -> print val

API

haskell-- | Parse JSON from Text, returning a human-readable error on failure.
parseJSON :: Text -> Either String JSON

-- | Parse JSON from Text, returning the full ParseErrorBundle on failure.
parseJSONWith :: String -> Text -> Either (ParseErrorBundle Text Void) JSON

The AST type

Values are parsed into the JSON type from the json-ast package:

haskelldata JSON =
  JSON_Object !(HashMap Text JSON) |
  JSON_Array  !(Vector JSON)       |
  JSON_String !Text                |
  JSON_Number !Scientific          |
  JSON_Bool   !Bool                |
  JSON_Null

Dependencies


megaparsec
json-ast
text
vector
unordered-containers
scientific


Known limitations


Surrogate pairs in \uXXXX escape sequences are not decoded — these are rejected with a parse error
Leading zeros in numbers (e.g. 007) and leading plus signs (e.g. +1) are accepted but are not valid JSON
Duplicate object keys are silently resolved by keeping the last value
UTF-8 validation of the source input is the caller's responsibility

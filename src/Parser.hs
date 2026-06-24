{-# LANGUAGE OverloadedStrings #-}

module Parser
  ( parseJSON
  , parseJSONWith
  ) where

import           Control.Monad              (void)
import           Data.Char                  (digitToInt, chr)
import qualified Data.HashMap.Strict        as HashMap
import           JSONAST                    (JSON (..))
import           Data.Text                  (Text)
import qualified Data.Text                  as Text
import qualified Data.Vector                as Vector
import           Data.Void                  (Void)
import           Text.Megaparsec
import           Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L

type Parser = Parsec Void Text

-- | Parse a JSON 'Text' value, returning a human-readable error on failure.
parseJSON :: Text -> Either String JSON
parseJSON input =
  case runParser topLevel "" input of
    Left  err -> Left (errorBundlePretty err)
    Right val -> Right val

-- | Parse a JSON 'Text' value, returning the full 'ParseErrorBundle' on failure.
parseJSONWith :: String -> Text
              -> Either (ParseErrorBundle Text Void) JSON
parseJSONWith = runParser topLevel

topLevel :: Parser JSON
topLevel = sc *> jsonValue <* eof

-- JSON only allows spaces, tabs, newlines, and carriage returns as whitespace.
sc :: Parser ()
sc = L.space jsonSpace empty empty where
  jsonSpace = void $ takeWhile1P (Just "whitespace") isJsonSpace
  isJsonSpace c = c == ' ' || c == '\n' || c == '\r' || c == '\t'

lexeme :: Parser a -> Parser a
lexeme = L.lexeme sc

symbol :: Text -> Parser Text
symbol = L.symbol sc

jsonValue :: Parser JSON
jsonValue = lexeme $ choice
  [ jsonObject
  , jsonArray
  , jsonString
  , jsonNumber
  , jsonBool
  , jsonNull
  ]

jsonObject :: Parser JSON
jsonObject =
  fmap (JSON_Object . HashMap.fromList) $
    between (symbol "{") (symbol "}") $
      jsonKVPair `sepBy` symbol ","
  where
    jsonKVPair :: Parser (Text, JSON)
    jsonKVPair = do
      k <- lexeme stringLiteral
      void $ symbol ":"
      v <- jsonValue
      pure (k, v)

jsonArray :: Parser JSON
jsonArray =
  fmap (JSON_Array . Vector.fromList) $
    between (symbol "[") (symbol "]") $
      jsonValue `sepBy` symbol ","

jsonString :: Parser JSON
jsonString = JSON_String <$> stringLiteral

-- | Parse a quoted JSON string literal, returning its unescaped 'Text' value.
stringLiteral :: Parser Text
stringLiteral =
  fmap Text.pack $
    char '"' *> manyTill stringChar (char '"')

stringChar :: Parser Char
stringChar = escapeSeq <|> normalChar
  where
    -- JSON strings must not contain unescaped control characters (< U+0020).
    normalChar = satisfy $ \c -> c /= '"' && c /= '\\' && c >= '\x20'

escapeSeq :: Parser Char
escapeSeq = char '\\' *> do
  c <- anySingle
  case c of
    '"'  -> pure '"'
    '\\' -> pure '\\'
    '/'  -> pure '/'
    'b'  -> pure '\b'
    'f'  -> pure '\f'
    'n'  -> pure '\n'
    'r'  -> pure '\r'
    't'  -> pure '\t'
    'u'  -> unicodeEscape
    _    -> fail $ "unknown escape sequence: \\" <> [c]

-- | Parse exactly 4 hex digits and convert to the corresponding 'Char'.
--   Surrogate halves (U+D800–U+DFFF) are rejected as they are not valid
--   Unicode scalar values; surrogate-pair decoding is not implemented here.
unicodeEscape :: Parser Char
unicodeEscape = do
  h1 <- hexDigitChar
  h2 <- hexDigitChar
  h3 <- hexDigitChar
  h4 <- hexDigitChar
  let cp = foldl' (\acc d -> acc * 16 + digitToInt d) 0 [h1, h2, h3, h4]
  if cp >= 0xD800 && cp <= 0xDFFF
    then fail "surrogate halves are not valid Unicode scalar values"
    else pure $ chr cp

jsonNumber :: Parser JSON
jsonNumber = JSON_Number <$> L.signed (pure ()) L.scientific

jsonBool :: Parser JSON
jsonBool =
      JSON_Bool True  <$ string "true"
  <|> JSON_Bool False <$ string "false"

jsonNull :: Parser JSON
jsonNull = JSON_Null <$ string "null"

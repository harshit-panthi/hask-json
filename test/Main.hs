module Main (main) where

import Parser (parseJSON)
import qualified Data.Text.IO as TIO (readFile)

main ::IO ()
main = putStrLn "Download/Generate 2 json files (64KB.json and 5MB.json), uncomment the real test in this file run this test from the directory with those files"

{-
main :: IO ()
main = do
  jsonFile64 <- TIO.readFile "64KB.json"
  case parseJSON jsonFile64 of
    Left err -> putStrLn $ "Parse error: " <> err
    Right !_ -> putStrLn "Parsed 64KB"
  jsonFile5 <- TIO.readFile "5MB.json"
  case parseJSON jsonFile5 of
    Left err -> putStrLn $ "Parse error: " <> err
    Right !_ -> putStrLn "Parsed 5MB"
  pure ()
-}

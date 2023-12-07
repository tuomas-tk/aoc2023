import Debug.Trace
import Data.List.Split(splitOn)
import Data.Maybe(mapMaybe)

getInput :: IO [String]
getInput = do
  lines <$> readFile "input.txt"

parseSeeds :: String -> [Int]
parseSeeds str = map read $ drop 1 $ splitOn " " str

parseInput :: [String] -> [Map]
parseInput [] = []
parseInput list =
    parseMap first : parseInput(drop 1 rest)
  where
    (first, rest) = break (=="") list

data Map = Map { fromType :: String, toType :: String, mapLines :: [Line] }
instance Show Map where
   show (Map from to map) = from ++ " -> " ++ to

parseMap :: [String] -> Map
parseMap [] = error "Empty string in parseMap"
parseMap (title : rest) =
    Map (from) (to) $ map parseLine rest
  where
    (from : _ : to : _) = splitOn "-" $ takeWhile (/=' ') title

data Line = Line { destStart :: Int, sourceStart :: Int, length :: Int }

parseLine :: String -> Line
parseLine str =
    Line dest src len
  where
    [dest, src, len] = map read $ splitOn " " str

mapValue :: [Map] -> Int -> Int
mapValue maps value = foldl (\a m -> combineMappers (mapLines m) a) value maps

combineMappers :: [Line] -> Int -> Int
combineMappers lines value = head $ (mapMaybe ((singleMapper value)) lines) ++ [value]

singleMapper :: Int -> Line -> Maybe Int
singleMapper value (Line destStart srcStart length)
  | srcStart <= value && value <= srcStart + length = Just $ value - srcStart + destStart
  | otherwise                                       = Nothing

main = do
  input <- getInput
  let seeds = parseSeeds (head input)
  print seeds
  let maps = parseInput $ (drop 2 input)
  print $ show maps
  print $ map (mapValue maps) seeds
  print $ minimum $ map (mapValue maps) seeds
import Debug.Trace
import Data.List.Split(splitOn, chunksOf)
import Data.List(nub)
import Data.Maybe(mapMaybe)

getInput :: IO [String]
getInput = do
  lines <$> readFile "input.txt"

parseInput :: [String] -> [Map]
parseInput [] = []
parseInput list =
    parseMap first : parseInput(drop 1 rest)
  where
    (first, rest) = break (=="") list

parseSeeds :: String -> [Int]
parseSeeds str = map read $ drop 1 $ splitOn " " str

parseSeedRanges :: [Int] -> [Range]
parseSeedRanges seeds = map createRange $ chunksOf 2 seeds

data Range = Range { fromIndex :: Int, count :: Int } deriving Show

createRange :: [Int] -> Range
createRange [a,c] = Range a c

rangeLastIndex :: Range -> Int
rangeLastIndex (Range from count) = from + count - 1

rangeNextIndex :: Range -> Int
rangeNextIndex (Range from count) = from + count

data Map = Map { fromType :: String, toType :: String, mapLines :: [MapLine] }
instance Show Map where
   show (Map from to map) = from ++ " -> " ++ to

parseMap :: [String] -> Map
parseMap [] = error "Empty string in parseMap"
parseMap (title : rest) =
    Map (from) (to) $ map parseLine rest
  where
    (from : _ : to : _) = splitOn "-" $ takeWhile (/=' ') title

data MapLine = MapLine { destStart :: Int, sourceStart :: Int, length :: Int }

parseLine :: String -> MapLine
parseLine str =
    MapLine dest src len
  where
    [dest, src, len] = map read $ splitOn " " str

mapValue :: [Map] -> Int -> Int
mapValue maps value = foldl (\a m -> combineMappers (mapLines m) a) value maps

combineMappers :: [MapLine] -> Int -> Int
combineMappers lines value = head $ (mapMaybe ((singleMapper value)) lines) ++ [value]

singleMapper :: Int -> MapLine -> Maybe Int
singleMapper value (MapLine destStart srcStart length)
  | srcStart <= value && value < srcStart + length = Just $ value - srcStart + destStart
  | otherwise                                      = Nothing


applyMapsToRanges :: [Map] -> [Range] -> [Range]
applyMapsToRanges maps ranges = foldl (\ ranges m -> concat
                              $ map (applyMapToRange m) ranges) ranges maps

applyMapToRange :: Map -> Range -> [Range]
applyMapToRange map range = Prelude.map (applyValueMapping map)
                          $ splitRangeAtPoints range
                          $ findDiscontinuities map

-- Transform the given range according to the given map.
-- Assumes that the whole range can be transformed in the same way (i.e. it has been split already)
applyValueMapping :: Map -> Range -> Range
applyValueMapping (Map _ _ mapLines) (Range from count) =
  let destFrom = combineMappers mapLines from
  in Range destFrom count

-- Points for which the map uses a different mapline than for the previous one
findDiscontinuities :: Map -> [Int]
findDiscontinuities (Map _ _ mapLines) = nub $
  (map (\line -> sourceStart line) mapLines)
  ++ (map (\line -> sourceStart line + Main.length line) mapLines)

splitRangeAtPoints :: Range -> [Int] -> [Range]
splitRangeAtPoints range [] = [range]
splitRangeAtPoints range (splitPoint : rest) = concat $ map (\r -> splitRangeAtPoints r rest) (splitRange range splitPoint)

-- splitpoint is the beginning of the new range
splitRange :: Range -> Int -> [Range]
splitRange range splitPoint
  | pointSplitsRange range splitPoint = [
      (Range (fromIndex range) (splitPoint - fromIndex range)),
      (Range splitPoint (rangeNextIndex range - splitPoint))
    ]
  | otherwise                         = [range]

-- Is the point in range, beginning exclusive, end inclusive
pointSplitsRange :: Range -> Int -> Bool
pointSplitsRange range splitPoint =
  fromIndex range < splitPoint && splitPoint <= rangeLastIndex range

main = do
  input <- getInput
  let seeds = parseSeeds $ head input
  let maps = parseInput $ drop 2 input
  -- PART 1
  putStrLn "Part 1"
  putStrLn $ show $ minimum $ map (mapValue maps) seeds
  putStrLn $ show $ minimum $ map fromIndex $ applyMapsToRanges maps $ map (\ s -> Range s 1) seeds
  -- PART 2
  let seedRanges = parseSeedRanges seeds
  putStrLn "Part 2"
  putStrLn $ show $ minimum $ map fromIndex $ applyMapsToRanges maps seedRanges
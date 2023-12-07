import Data.List.Split(splitOn)

main = do
  input <- getInput
  let races = parseInput input
  putStrLn "Part 1"
  putStrLn $ show $ product $ map countWaysToWin races
  putStrLn "Part 2"
  putStrLn $ show $ product $ map countWaysToWin [combineRaces races]

-- PARSING --

getInput :: IO [String]
getInput = do
  lines <$> readFile "input.txt"

data Race = Race { time :: Int, distance :: Int } deriving Show

parseInput :: [String] -> [Race]
parseInput lines =
  let 
    (times : dists : _) = map parseInputLine lines
  in
    map (uncurry Race) (zip times dists)

parseInputLine :: String -> [Int]
parseInputLine line = map read $ drop 1 $ filter (/="") $ splitOn " " line

-- CALCULATING --

countWaysToWin :: Race -> Int
countWaysToWin (Race time distance) =
    (floor high) - (ceiling low) + 1
  where
    [low, high] = solveEq (-1) time (-distance-1)

-- Time pressing button = x
--    travel = (time - x) * x = -x^2 + time * x
-- need to find
--    travel > distance + 1
--    -x^2 + time * x - distance - 1 > 0

solveEq :: Int -> Int -> Int -> [Float]
solveEq ai bi ci =
    map (\ m -> (-b+m*(sqrt (b^2-4*a*c))) / (2*a)) [1, -1]
  where
    a = fromIntegral ai
    b = fromIntegral bi
    c = fromIntegral ci

combineRaces :: [Race] -> Race
combineRaces races = Race (combineFields time races) (combineFields distance races)

combineFields :: (Race -> Int) -> [Race] -> Int
combineFields accessor races = (read $ concat $ map (show . accessor) races)

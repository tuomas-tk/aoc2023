main = do
  input <- getInput
  let measurements = map parseInput input
  print "Part 1"
  print $ sum $ map predictLast measurements
  print "Part 2"
  print $ sum $ map predictFirst measurements

getInput :: IO [String]
getInput = do
  lines <$> readFile "input.txt"

type Sequence = [Int]

parseInput :: String -> Sequence
parseInput line = map read $ words line

predictLast :: Sequence -> Int
predictLast list
  | all (== 0) list = 0
  | otherwise = last list + predictLast (diffs list)

predictFirst :: Sequence -> Int
predictFirst list
  | all (== 0) list = 0
  | otherwise = head list - predictFirst (diffs list)

diffs :: Sequence -> Sequence
diffs list = zipWith (-) (drop 1 list) list
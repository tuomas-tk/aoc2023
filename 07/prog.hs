import Data.List(sort, group, intercalate)

main = do
  input <- getInput
  let players = map parseInput input
  putStrLn "Part 1"
  compute players
  putStrLn "Part 2"
  compute $ map convertToJokers players

compute :: [Player] -> IO ()
compute players = do
  let withRanks = zip (sort players) [1..]
  -- putStrLn $ intercalate "\n" $ map show $ withRanks
  putStrLn $ show $ sum $ map (\(Player _ bid, rank) -> bid * rank) withRanks

convertToJokers :: Player -> Player
convertToJokers (Player (Hand cards) bid) =
    Player (Hand newCards) bid
  where
    newCards = map (\c -> case c of J -> JOKER; other -> other) cards

getInput :: IO [String]
getInput = do
  lines <$> readFile "input.txt"

parseInput :: String -> Player
parseInput line = Player (Hand $ map charToCard $ take 5 line) (read $ drop 6 line)

data Player = Player { hand :: Hand, bid :: Int } deriving (Show, Eq)
instance Ord Player where
  compare (Player x _) (Player y _) = compare x y

data Hand = Hand { cards :: [Card] } deriving (Eq)
instance Ord Hand where
  compare x y =
    case compare (handToType x) (handToType y) of
      EQ    -> compare (cards x) (cards y)
      other -> other
instance Show Hand where
  show hand = (show $ handToType hand) ++ "/" ++ (map (last . show) $ cards hand)

data Card = JOKER | N2 | N3 | N4 | N5 | N6 | N7 | N8 | N9 | T | J | Q | K | A
  deriving (Enum, Show, Eq, Ord)

charToCard :: Char -> Card
charToCard 'A' = A
charToCard 'K' = K
charToCard 'Q' = Q
charToCard 'J' = J
charToCard 'T' = T
charToCard '9' = N9
charToCard '8' = N8
charToCard '7' = N7
charToCard '6' = N6
charToCard '5' = N5
charToCard '4' = N4
charToCard '3' = N3
charToCard '2' = N2

data HandType = HighCard | OnePair | TwoPair | ThreeOfAKind | FullHouse | FourOfAKind | FiveOfAKind 
  deriving (Enum, Show, Eq, Ord)

handToType :: Hand -> HandType
handToType (Hand cards) =
  case same cards of
    [5]       -> FiveOfAKind
    [4,1]     -> FourOfAKind
    [3,2]     -> FullHouse
    [3,1,1]   -> ThreeOfAKind
    [2,2,1]   -> TwoPair
    [2,1,1,1] -> OnePair
    otherwise -> HighCard

same :: [Card] -> [Int]
same cards = addToFirst (length $ jokers cards)
           $ reverse $ sort $ map length $ group $ sort $ notJokers cards

jokers :: [Card] -> [Card]
jokers = filter (== JOKER)
notJokers :: [Card] -> [Card]
notJokers = filter (/= JOKER)

addToFirst :: Int -> [Int] -> [Int]
addToFirst add []       = [add]
addToFirst add [f]      = [f + add]
addToFirst add (f:rest) = [f + add] ++ rest
module Anagram where

import Data.List
import Data.Char (toLower)
import qualified Data.Map as Map

-- ######### Definition type

type Word = String

type Sentence = [Word]

type Occurrences = [(Char, Int)]

-- ######### Production code

wordOccurrences :: Word -> Occurrences
wordOccurrences = map (\x -> ((head x), length x)) . group . sort . (map toLower)

sentenceOccurrences :: Sentence -> Occurrences
sentenceOccurrences = wordOccurrences . (intercalate "")

combinations :: Occurrences -> [Occurrences]
combinations =
  foldl' comb [[]]
  where comb :: [Occurrences] -> (Char, Int) -> [Occurrences]
        comb ss ci = ss ++ [sub ++ [c] | sub <- ss, c <- subOccurrences ci]
        subOccurrences :: (Char, Int) -> Occurrences
        subOccurrences (c, n) = [(c, i) | i <- [1..n]]

substract :: Occurrences -> Occurrences -> Occurrences
substract occ = foldl' update occ
                where update :: Occurrences -> (Char, Int) -> Occurrences
                      update [] _                       = []
                      update (x@(cc, nn) : xs) e@(c, n) = case cc == c of
                        True -> let ni = nn - n in if ni <= 0 then xs else (c, ni):xs
                        _    -> x : update xs e

type DicoOcc = [(Occurrences, [Word])]

dicoByOccurrences :: [String] -> DicoOcc
dicoByOccurrences = nub . (foldl' add []) -- Fixme - using nub to destroy duplicated entries at the end
  where add acc word = let occ = wordOccurrences word in
          case lookup occ acc of
            Nothing -> (occ, [word]) : acc
            Just ws -> (occ, nws) : acc -- Fixme - how to update the associative array
                       where nws = if elem word ws then ws else word : ws -- no duplicated entries

findAnagram :: Word -> [(Occurrences, a)] -> Maybe a
findAnagram w d = (flip lookup d . wordOccurrences) w

-- Returns all the anagrams of a given word.
wordAnagrams :: Word -> DicoOcc -> [Word]
wordAnagrams w d = case findAnagram w d of
  Nothing -> []
  Just x  -> x

-- ######### I/O

extractLines :: FilePath -> IO [String]
extractLines filePath =
  do contents <- readFile filePath
     return $ lines contents

disp :: Int -> IO [String] -> IO ()
disp n allLines =
  do ll <- allLines
     let f = take n ll in
       mapM_ putStrLn f

--  An anagram of a sentence is formed by taking the occurrences of all the characters of
--  all the words in the sentence, and producing all possible combinations of words with those characters,
--  such that the words have to be from the dictionary.

-- Returns a list of all anagram sentences of the given sentence.
sentenceAnagrams :: Sentence -> DicoOcc -> [Sentence]
sentenceAnagrams s d =
  (filteringSentencesOnOccurrence . nub . sentenceCompute . combinations) sentenceOccurrenceRef
  where filteringSentencesOnOccurrence :: [Sentence] -> [Sentence]
        filteringSentencesOnOccurrence = filter (\x -> sentenceOccurrences x == sentenceOccurrenceRef)
        sentenceOccurrenceRef :: Occurrences
        sentenceOccurrenceRef = sentenceOccurrences s
        sentenceCompute :: [Occurrences] -> [Sentence]
        sentenceCompute []     = [[]]
        sentenceCompute (o:os) = case lookup o d of
          Nothing        -> sentenceCompute os
          Just anagrams  -> [y:ys | y <- anagrams, ys <- sentenceCompute oss] ++ sentenceCompute os
            where oss = map (flip substract o) os

dictionaryFromFile :: FilePath -> IO DicoOcc
dictionaryFromFile filepath =
  do dicoLines <- extractLines filepath
     return $ dicoByOccurrences dicoLines

mainWordAnagrams :: String -> FilePath -> IO ()
mainWordAnagrams word filePath =
  do dicoLines <- extractLines filePath
     mapM_ putStrLn $ wordAnagrams word (dicoByOccurrences dicoLines)

printSentence :: Sentence -> IO ()
printSentence sentence = putStr "[" >> mapM_ (putStr . (++) " ") sentence >> putStrLn "]"

mainSentenceAnagrams :: [String] -> FilePath -> IO ()
mainSentenceAnagrams sentence filePath =
  do dico <- dictionaryFromFile filePath
     mapM_ printSentence $ sentenceAnagrams sentence dico
module C12 where

fibs :: [Integer]
fibs = 0:1:[ x+y | (x,y) <- zip fibs (tail fibs)]

-- *C12> take 20 fibs
-- [0,1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181]

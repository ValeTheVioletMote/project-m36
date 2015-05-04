{-# LANGUAGE FlexibleInstances,OverloadedStrings #-}
import ProjectM36.Base
import ProjectM36.Relation
import ProjectM36.Tuple
import ProjectM36.Relation.Show.CSV
import qualified Data.HashSet as HS
import qualified Data.ByteString.Lazy.Char8 as BS
import qualified Data.IntMap as IM
import qualified Data.Hashable as Hash
import qualified Data.Vector as V
import Options.Applicative
                     
dumpcsv :: Relation -> IO ()
dumpcsv = BS.putStrLn . relationAsCSV

parseAttributeCount :: Parser Int
parseAttributeCount = option auto (short 'a' <> long "attribute-count")

parseTupleCount :: Parser Int
parseTupleCount = option auto (short 't' <> long "tuple-count")
  
parseArgs :: Parser (Int, Int)
parseArgs = (,) <$> parseAttributeCount <*>  parseTupleCount


main :: IO ()
main = do
  (attributeCount, tupleCount) <- execParser $ info (helper <*> parseArgs) fullDesc
  --matrixRestrictRun
  matrixRun attributeCount tupleCount
    --vectorMatrixRun 
    --intmapMatrixRun
  
-- takes 30 minutes to run and 1.1 GB       
matrixRestrictRun :: IO ()
matrixRestrictRun = do  
  case matrixRelation 100 1000000 of
    Left err -> putStrLn (show err)
    Right rel -> case restrict (\tuple -> atomForAttributeName "0" tuple == Right (IntAtom 5)) rel of
      Left err -> putStrLn (show err)
      Right rel -> dumpcsv rel
      
matrixRun :: Int -> Int -> IO ()
matrixRun attributeCount tupleCount= do  
  case matrixRelation attributeCount tupleCount of
    Left err -> putStrLn (show err)
    Right rel -> putStrLn "Done"
      
intmapMatrixRun :: IO ()
intmapMatrixRun = do      
  let matrix = intmapMatrixRelation 100 100000
  putStrLn (show matrix)
  
--compare IntMap speed and size
--this is about 3 times faster (9 minutes) for 10x100000 and uses 800 MB
intmapMatrixRelation :: Int -> Int -> HS.HashSet (IM.IntMap Atom)
intmapMatrixRelation attributeCount tupleCount = HS.fromList $ map mapper [0..tupleCount]
  where
    mapper tupCount = IM.fromList $ map (\c-> (c, IntAtom tupCount)) [0..attributeCount]

instance Hash.Hashable (IM.IntMap Atom) where
  hashWithSalt salt tupMap = Hash.hashWithSalt salt (show tupMap)

vectorMatrixRun :: IO ()
vectorMatrixRun = do
  let matrix = vectorMatrixRelation 100 100000
  putStrLn (show matrix)

-- 20 s 90 MBs- a clear win- ideal size is 10 * 100000 * 8 bytes = 80 MB! without IntAtom wrapper
--with IntAtom wrapper: 1m12s 90 MB
vectorMatrixRelation :: Int -> Int -> HS.HashSet (V.Vector Atom)
vectorMatrixRelation attributeCount tupleCount = HS.fromList $ map mapper [0..tupleCount]
  where
    mapper tupCount = V.replicate attributeCount (IntAtom tupCount)
    
instance Hash.Hashable (V.Vector Atom) where    
  hashWithSalt salt vec = Hash.hashWithSalt salt (show vec)
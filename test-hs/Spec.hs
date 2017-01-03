{-# LANGUAGE OverloadedStrings #-}
module Main (main) where

import LispVal
import Parser
import Eval

import Test.Hspec
import qualified Data.Text as T

import System.IO.Unsafe

main :: IO ()
main = do
  hspec $ describe "src/Parser.hs" $ do
    it "Atom" $ do
      (readExpr "bb-8?") `shouldBe`  (Right $ Atom "bb-8?")
    it "Num Negative" $ do
      (readExpr "-2187") `shouldBe`  (Right $ Number $ 0 - 2187)
    it "Num Positive" $ do
      (readExpr "112233") `shouldBe`  (Right $ Number 112233)

    it "String" $ do
      (readExpr "\"General Liea Organa\"") `shouldBe`  (Right $ String "General Liea Organa")
    it "Bool True" $ do
      (readExpr "#t") `shouldBe`  (Right $ Bool True)
    it "Bool False" $ do
      (readExpr "#f") `shouldBe`  (Right $ Bool False)
    it "Nil" $ do
      (readExpr "Nil") `shouldBe`  (Right $ Nil)

    it "S-Expr: homogenous list" $ do
      (readExpr "(2 1 87)") `shouldBe`  (Right $ List [Number 2, Number 1,Number 87])
    it "S-Expr: homogenous list quoted" $ do
      (readExpr "'(2 1 87)") `shouldBe`  (Right $ List [Atom "quote",List [Number 2, Number 1,Number 87]])

    it "S-Expr: heterogenous list" $ do
      (readExpr "(stromTrooper \"Fn\" 2 1 87)") `shouldBe`  (Right $ List [Atom "stromTrooper", String "Fn", Number 2, Number 1,Number 87])
    it "S-Expr: heterogenous list quoted" $ do
      (readExpr "'(stromTrooper \"Fn\" 2 1 87)") `shouldBe`  (Right $ List [Atom "quote", List [Atom "stromTrooper", String "Fn", Number 2, Number 1,Number 87]])

    it "S-Expr: prim call: neg nums" $ do
      (readExpr "(- -42 -42)") `shouldBe` (Right $ List [Atom "-", Number (0 - 42), Number (0 - 42)])
    it "S-Expr: prim call: atoms" $ do
      (readExpr "(- you me)") `shouldBe` (Right $ List [Atom "-", Atom "you", Atom "me"])

    it "S-Expr: nested list" $ do
      (readExpr "(lambda (x x) (+ x x))") `shouldBe` (Right $ List [Atom "lambda", List[Atom "x", Atom "x"], List [Atom "+", Atom "x", Atom "x"]])



  hspec $ describe "src/Eval.hs" $ do
    wStd "test/add.scm" $ Number 3
    runExpr Nothing "test/define.scm" $ Number 4
    wStd "test/eval_boolean.scm" $ Bool True
    wStd "test/eval_lambda.scm" $ Number 5
    wStd "test/if_alt.scm" $ Number 2
    wStd "test/let.scm" $ Number 321
    wStd "test/test_car.scm" $ Number 1
    wStd "test/test_cdr.scm" $ List [Number 2]
    wStd "test/test_cadadr.scm" $ Number 42
    wStd "test/test_gt.scm" $ List [ Bool True, Bool False]
    wStd "test/test_quote.scm" $ List []

  hspec $ describe "eval extra" $ do
    tExpr "fold"  "(fold '''(+) 1 '''(1 2 3))" $ Number 7

-- helper functions
wStd :: T.Text -> LispVal -> SpecWith ()
wStd = runExpr (Just "test/stdlib_mod.scm")

tExpr :: T.Text -> T.Text -> LispVal -> SpecWith ()
tExpr note expr val = do
    it (T.unpack note) $ do
      (unsafePerformIO $ runASTinEnv basicEnv $ fileToEvalForm expr) `shouldBe` val

runExpr :: Maybe T.Text -> T.Text -> LispVal -> SpecWith ()
runExpr  std file val = do
    it (T.unpack file) $ do
      (unsafePerformIO $ evalTextTest std file) `shouldBe` val

evalTextTest :: Maybe T.Text -> T.Text -> IO LispVal --REPL
evalTextTest (Just stdlib) file= do
  stdlib <- getFileContents $ T.unpack  stdlib
  f <- getFileContents $ T.unpack file 
  runASTinEnv basicEnv $ textToEvalForm stdlib  f

evalTextTest Nothing file = do
  f <- getFileContents $ T.unpack file 
  runASTinEnv basicEnv $ fileToEvalForm f



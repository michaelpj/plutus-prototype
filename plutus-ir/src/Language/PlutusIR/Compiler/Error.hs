{-# LANGUAGE FlexibleInstances      #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE LambdaCase             #-}
{-# LANGUAGE OverloadedStrings      #-}
{-# LANGUAGE TemplateHaskell        #-}
module Language.PlutusIR.Compiler.Error (Error (..), AsError (..)) where

import qualified Language.PlutusCore        as PLC
import qualified Language.PlutusCore.Pretty as PLC

import           Control.Exception
import           Control.Lens

import qualified Data.Text                  as T
import           Data.Text.Prettyprint.Doc  ((<+>), (<>))
import qualified Data.Text.Prettyprint.Doc  as PP
import           Data.Typeable

data Error a = CompilationError a T.Text -- ^ A generic compilation error.
               | UnsupportedError a T.Text -- ^ An error relating specifically to an unsupported feature.
               | PLCError (PLC.Error a) -- ^ An error from running some PLC function, lifted into this error type for convenience.
               deriving (Typeable)
makeClassyPrisms ''Error

instance PLC.AsTypeError (Error a) a where
    _TypeError = _PLCError . PLC._TypeError

instance (PP.Pretty a) => Show (Error a) where
    show e = show $ PLC.prettyPlcClassicDebug e

instance PP.Pretty a => PLC.PrettyBy PLC.PrettyConfigPlc (Error a) where
    prettyBy config = \case
        CompilationError x e -> "Error during compilation:" <+> PP.pretty e <> "(" <> PP.pretty x <> ")"
        UnsupportedError x e -> "Unsupported construct:" <+> PP.pretty e <+> "(" <> PP.pretty x <> ")"
        PLCError e -> PP.vsep [ "Error from the PLC compiler:", PLC.prettyBy config e ]

instance (PP.Pretty a, Typeable a) => Exception (Error a)

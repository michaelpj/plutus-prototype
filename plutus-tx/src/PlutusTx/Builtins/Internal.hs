{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE TypeApplications   #-}
-- This ensures that we don't put *anything* about these functions into the interface
-- file, otherwise GHC can be clever about the ones that are always error, even though
-- they're NOINLINE!
{-# OPTIONS_GHC -O0 #-}
-- | This module contains the special Haskell names that are used to map to builtin types or functions
-- in Plutus Core.
--
-- Most users should not use this module directly, but rather use 'PlutusTx.Builtins'.
module PlutusTx.Builtins.Internal where

import qualified Crypto
import           Data.ByteString      as BS
import qualified Data.ByteString.Hash as Hash
import           Data.Coerce
import           Data.Maybe           (fromMaybe)
import qualified PlutusCore.Data      as PLC
import           PlutusTx.Utils

{- Note [Builtin name definitions]
The builtins here have definitions so they can be used in off-chain code too.

However they *must* be replaced by the compiler when used in Plutus Tx code, so
in particular they must *not* be inlined, otherwise we can't spot them to replace
them.
-}

{- Note [Delaying error]
The Plutus Core 'error' builtin is of type 'forall a . a', but the
one we expose here is of type 'forall a . () -> a'.

This is because it's hard to get the evaluation order right with
the non-delayed version - it's easy to end up with it getting thrown
unconditionally, or before some other effect (e.g. tracing). On the other
hand, it's much easier to work with the delayed version.

But why not just define that in the library? i.e.

    error = \_ -> Builtins.error

The answer is that GHC is eager to inline and reduce this function, which
does the Wrong Thing. We can't stop GHC doing this (at the moment), but
for most of our functions it's not a *semantic* problem. Here, however,
it is a problem. So we just expose the delayed version as the builtin.
-}

{-# NOINLINE error #-}
error :: BuiltinUnit -> a
error = mustBeReplaced "error"

{-
BOOL
-}

newtype BuiltinBool = BuiltinBool Bool

{-# NOINLINE true #-}
true :: BuiltinBool
true = coerce True

{-# NOINLINE false #-}
false :: BuiltinBool
false = coerce False

{-# NOINLINE ifThenElse #-}
ifThenElse :: BuiltinBool -> a -> a -> a
ifThenElse (BuiltinBool b) x y = if b then x else y

{-
UNIT
-}

newtype BuiltinUnit = BuiltinUnit ()

{-# NOINLINE unitval #-}
unitval :: BuiltinUnit
unitval = BuiltinUnit ()

{-# NOINLINE chooseUnit #-}
chooseUnit :: BuiltinUnit -> a -> a
chooseUnit (BuiltinUnit ()) a = a

{-
INTEGER
-}

type BuiltinInteger = Integer

{-# NOINLINE addInteger #-}
addInteger :: BuiltinInteger -> BuiltinInteger -> BuiltinInteger
addInteger = coerce ((+) @Integer)

{-# NOINLINE subtractInteger #-}
subtractInteger :: BuiltinInteger -> BuiltinInteger -> BuiltinInteger
subtractInteger = coerce ((-) @Integer)

{-# NOINLINE multiplyInteger #-}
multiplyInteger :: BuiltinInteger -> BuiltinInteger -> BuiltinInteger
multiplyInteger = coerce ((*) @Integer)

{-# NOINLINE divideInteger #-}
divideInteger :: BuiltinInteger -> BuiltinInteger -> BuiltinInteger
divideInteger = coerce (div @Integer)

{-# NOINLINE modInteger #-}
modInteger :: BuiltinInteger -> BuiltinInteger -> BuiltinInteger
modInteger = coerce (mod @Integer)

{-# NOINLINE quotientInteger #-}
quotientInteger :: BuiltinInteger -> BuiltinInteger -> BuiltinInteger
quotientInteger = coerce (quot @Integer)

{-# NOINLINE remainderInteger #-}
remainderInteger :: BuiltinInteger -> BuiltinInteger -> BuiltinInteger
remainderInteger = coerce (rem @Integer)

{-# NOINLINE greaterThanInteger #-}
greaterThanInteger :: BuiltinInteger -> BuiltinInteger -> BuiltinBool
greaterThanInteger = coerce ((>) @Integer)

{-# NOINLINE greaterThanEqInteger #-}
greaterThanEqInteger :: BuiltinInteger -> BuiltinInteger -> BuiltinBool
greaterThanEqInteger = coerce ((>=) @Integer)

{-# NOINLINE lessThanInteger #-}
lessThanInteger :: BuiltinInteger -> BuiltinInteger -> BuiltinBool
lessThanInteger = coerce ((<) @Integer)

{-# NOINLINE lessThanEqInteger #-}
lessThanEqInteger :: BuiltinInteger -> BuiltinInteger -> BuiltinBool
lessThanEqInteger = coerce ((<=) @Integer)

{-# NOINLINE equalsInteger #-}
equalsInteger :: BuiltinInteger -> BuiltinInteger -> BuiltinBool
equalsInteger = coerce ((==) @Integer)

{-
BYTESTRING
-}

type BuiltinByteString = ByteString

{-# NOINLINE concatenate #-}
concatenate :: BuiltinByteString -> BuiltinByteString -> BuiltinByteString
concatenate = BS.append

{-# NOINLINE takeByteString #-}
takeByteString :: BuiltinInteger -> BuiltinByteString -> BuiltinByteString
takeByteString n = BS.take (fromIntegral n)

{-# NOINLINE dropByteString #-}
dropByteString :: BuiltinInteger -> BuiltinByteString -> BuiltinByteString
dropByteString n = BS.drop (fromIntegral n)

{-# NOINLINE emptyByteString #-}
emptyByteString :: BuiltinByteString
emptyByteString = BS.empty

{-# NOINLINE sha2_256 #-}
sha2_256 :: BuiltinByteString -> BuiltinByteString
sha2_256 = Hash.sha2

{-# NOINLINE sha3_256 #-}
sha3_256 :: BuiltinByteString -> BuiltinByteString
sha3_256 = Hash.sha3

{-# NOINLINE verifySignature #-}
verifySignature :: BuiltinByteString -> BuiltinByteString -> BuiltinByteString -> BuiltinBool
verifySignature pubKey message signature =
  coerce (fromMaybe False (Crypto.verifySignature pubKey message signature))

{-# NOINLINE equalsByteString #-}
equalsByteString :: BuiltinByteString -> BuiltinByteString -> BuiltinBool
equalsByteString = coerce ((==) @ByteString)

{-# NOINLINE lessThanByteString #-}
lessThanByteString :: BuiltinByteString -> BuiltinByteString -> BuiltinBool
lessThanByteString = coerce ((<) @ByteString)

{-# NOINLINE greaterThanByteString #-}
greaterThanByteString :: BuiltinByteString -> BuiltinByteString -> BuiltinBool
greaterThanByteString = coerce ((>) @ByteString)

{-# NOINLINE decodeUtf8 #-}
decodeUtf8 :: BuiltinByteString -> BuiltinString
decodeUtf8 = mustBeReplaced "decodeUtf8"

{-
STRING
-}

type BuiltinChar = Char
newtype BuiltinString = BuiltinString String

{-# NOINLINE appendString #-}
appendString :: BuiltinString -> BuiltinString -> BuiltinString
appendString = mustBeReplaced "appendString"

{-# NOINLINE emptyString #-}
emptyString :: BuiltinString
emptyString = mustBeReplaced "emptyString"

{-# NOINLINE charToString #-}
charToString :: BuiltinChar -> BuiltinString
charToString = mustBeReplaced "charToString"

{-# NOINLINE equalsString #-}
equalsString :: BuiltinString -> BuiltinString -> BuiltinBool
equalsString = mustBeReplaced "equalsString"

{-# NOINLINE trace #-}
trace :: BuiltinString -> BuiltinUnit
trace _ = unitval

{-# NOINLINE encodeUtf8 #-}
encodeUtf8 :: BuiltinString -> BuiltinByteString
encodeUtf8 = mustBeReplaced "encodeUtf8"

{-
PAIR
-}

newtype BuiltinPair a b = BuiltinPair (a, b)

{-# NOINLINE fst #-}
fst :: BuiltinPair a b -> a
fst (BuiltinPair (a, _)) = a

{-# NOINLINE snd #-}
snd :: BuiltinPair a b -> b
snd (BuiltinPair (_, b)) = b

{-# NOINLINE mkPairData #-}
mkPairData :: BuiltinData -> BuiltinData -> BuiltinPair BuiltinData BuiltinData
mkPairData d1 d2 = BuiltinPair (d1, d2)

{-
LIST
-}

newtype BuiltinList a = BuiltinList [a]

{-# NOINLINE null #-}
null :: BuiltinList a -> BuiltinBool
null (BuiltinList (_:_)) = coerce True
null (BuiltinList [])    = coerce False

{-# NOINLINE head #-}
head :: BuiltinList a -> a
head (BuiltinList (x:_)) = x
head (BuiltinList [])    = Prelude.error "empty list"

{-# NOINLINE tail #-}
tail :: BuiltinList a -> BuiltinList a
tail (BuiltinList (_:xs)) = coerce xs
tail (BuiltinList [])     = Prelude.error "empty list"

{-# NOINLINE mkNilData #-}
mkNilData :: BuiltinList BuiltinData
mkNilData = BuiltinList []

{-# NOINLINE mkConsData #-}
mkConsData :: BuiltinData -> BuiltinList BuiltinData -> BuiltinList BuiltinData
mkConsData d (BuiltinList ds) = BuiltinList (d:ds)

{-# NOINLINE mkNilPairData #-}
mkNilPairData :: BuiltinList (BuiltinPair BuiltinData BuiltinData)
mkNilPairData = BuiltinList []

{-# NOINLINE mkConsPairData #-}
mkConsPairData :: BuiltinPair BuiltinData BuiltinData -> BuiltinList (BuiltinPair BuiltinData BuiltinData) -> BuiltinList (BuiltinPair BuiltinData BuiltinData)
mkConsPairData d (BuiltinList ds) = BuiltinList (d:ds)

{-
DATA
-}

newtype BuiltinData = BuiltinData PLC.Data
    deriving newtype (Show, Eq, Ord)

-- NOT a builtin, only safe off-chain, hence the NOINLINE
{-# NOINLINE builtinDataToData #-}
builtinDataToData :: BuiltinData -> PLC.Data
builtinDataToData (BuiltinData d) = d

-- NOT a builtin, only safe off-chain, hence the NOINLINE
{-# NOINLINE dataToBuiltinData #-}
dataToBuiltinData :: PLC.Data -> BuiltinData
dataToBuiltinData = BuiltinData

{-# NOINLINE chooseData #-}
chooseData :: forall a . a -> a -> a -> a -> a -> BuiltinData -> a
chooseData constrCase mapCase listCase iCase bCase (BuiltinData d) = case d of
    PLC.Constr{} -> constrCase
    PLC.Map{}    -> mapCase
    PLC.List{}   -> listCase
    PLC.I{}      -> iCase
    PLC.B{}      -> bCase

{-# NOINLINE mkConstr #-}
mkConstr :: BuiltinInteger -> BuiltinList BuiltinData -> BuiltinData
mkConstr i args = BuiltinData (PLC.Constr i (coerce args))

{-# NOINLINE mkMap #-}
mkMap :: BuiltinList (BuiltinPair BuiltinData BuiltinData) -> BuiltinData
mkMap es = BuiltinData (PLC.Map (coerce es))

{-# NOINLINE mkList #-}
mkList :: BuiltinList BuiltinData -> BuiltinData
mkList l = BuiltinData (PLC.List (coerce l))

{-# NOINLINE mkI #-}
mkI :: BuiltinInteger -> BuiltinData
mkI i = BuiltinData (PLC.I i)

{-# NOINLINE mkB #-}
mkB :: BuiltinByteString -> BuiltinData
mkB b = BuiltinData (PLC.B b)

{-# NOINLINE unsafeDataAsConstr #-}
unsafeDataAsConstr :: BuiltinData -> BuiltinPair BuiltinInteger (BuiltinList BuiltinData)
unsafeDataAsConstr (BuiltinData (PLC.Constr i args)) = BuiltinPair (i, coerce args)
unsafeDataAsConstr _                                 = Prelude.error "not a Constr"

{-# NOINLINE unsafeDataAsMap #-}
unsafeDataAsMap :: BuiltinData -> BuiltinList (BuiltinPair BuiltinData BuiltinData)
unsafeDataAsMap (BuiltinData (PLC.Map m)) = coerce m
unsafeDataAsMap _                         = Prelude.error "not a Map"

{-# NOINLINE unsafeDataAsList #-}
unsafeDataAsList :: BuiltinData -> BuiltinList BuiltinData
unsafeDataAsList (BuiltinData (PLC.List l)) = coerce l
unsafeDataAsList _                          = Prelude.error "not a List"

{-# NOINLINE unsafeDataAsI #-}
unsafeDataAsI :: BuiltinData -> BuiltinInteger
unsafeDataAsI (BuiltinData (PLC.I i)) = i
unsafeDataAsI _                       = Prelude.error "not an I"

{-# NOINLINE unsafeDataAsB #-}
unsafeDataAsB :: BuiltinData -> BuiltinByteString
unsafeDataAsB (BuiltinData (PLC.B b)) = b
unsafeDataAsB _                       = Prelude.error "not a B"

{-# NOINLINE equalsData #-}
equalsData :: BuiltinData -> BuiltinData -> BuiltinBool
equalsData (BuiltinData b1) (BuiltinData b2) = coerce $ b1 Prelude.== b2

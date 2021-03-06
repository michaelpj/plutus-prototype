module Data.RawJson where

import Prelude
import Data.Generic.Rep (class Generic)
import Data.Generic.Rep.Show (genericShow)
import Data.Lens (Iso')
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Newtype (class Newtype)
import Foreign (readString, unsafeToForeign)
import Foreign.Class (class Decode, class Encode)

newtype RawJson
  = RawJson String

derive instance genericRawJson :: Generic RawJson _

derive instance newtypeRawJson :: Newtype RawJson _

_RawJson :: Iso' RawJson String
_RawJson = _Newtype

instance showRawJson :: Show RawJson where
  show = genericShow

instance encodeRawJson :: Encode RawJson where
  encode (RawJson string) = unsafeToForeign string

instance decodeRawJson :: Decode RawJson where
  decode value = RawJson <$> readString value

{-# LANGUAGE ExistentialQuantification #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
{- HLINT ignore "Redundant bracket" -}
{- HLINT ignore "Use camelCase" -}
{- HLINT ignore "Use null" -}

-- |
-- Copyright: © 2022–2025 Jonathan Knowles
-- License: Apache-2.0
--
module Test.Common
    ( Key
    , Test
    , TestValueType (..)
    , testValueTypesMonoidNull
    , testValueTypesGroup
    , testValueTypesMonus
    , testValueTypesLeftReductive
    , testValueTypesRightReductive
    , testValueTypesReductive
    , testValueTypesLeftGCDMonoid
    , testValueTypesRightGCDMonoid
    , testValueTypesOverlappingGCDMonoid
    , testValueTypesGCDMonoid
    , testValueTypesLCMMonoid
    , TestValue
    , makeSpec
    , property
    ) where

import Prelude

import Data.Group
    ( Group )
import Data.Kind
    ( Constraint, Type )
import Data.Monoid
    ( Dual, Product, Sum )
import Data.Monoid.GCD
    ( GCDMonoid, LeftGCDMonoid, OverlappingGCDMonoid, RightGCDMonoid )
import Data.Monoid.LCM
    ( LCMMonoid )
import Data.Monoid.Monus
    ( Monus )
import Data.Monoid.Null
    ( MonoidNull )
import Data.MonoidMap
    ( MonoidMap )
import Data.Proxy
    ( Proxy (Proxy) )
import Data.Semigroup.Cancellative
    ( LeftReductive, Reductive, RightReductive )
import Data.Set
    ( Set )
import Data.Text
    ( Text )
import Data.Typeable
    ( Typeable, typeRep )
import GHC.Exts
    ( IsList (..) )
import Numeric.Natural
    ( Natural )
import Test.Hspec
    ( Spec, describe )
import Test.QuickCheck
    ( Arbitrary (..)
    , CoArbitrary (..)
    , Function (..)
    , Property
    , Testable
    , checkCoverage
    , choose
    , coarbitraryIntegral
    , coarbitraryShow
    , frequency
    , functionIntegral
    , functionShow
    , listOf
    , scale
    , shrinkMapBy
    )
import Test.QuickCheck.Instances.Natural
    ()

import qualified Data.MonoidMap as MonoidMap
import qualified Data.Text as Text
import qualified Test.QuickCheck as QC

--------------------------------------------------------------------------------
-- Arbitrary instances
--------------------------------------------------------------------------------

instance (Arbitrary k, Ord k, Arbitrary v, MonoidNull v) =>
    Arbitrary (MonoidMap k v)
  where
    arbitrary =
        fromList <$> scale (`mod` 16) (listOf ((,) <$> arbitrary <*> arbitrary))
    shrink =
        shrinkMapBy MonoidMap.fromMap MonoidMap.toMap shrink

instance Arbitrary Text where
    arbitrary = Text.pack <$> listOf genChar
      where
        genChar = frequency
            [ (64, pure 'a')
            , (16, pure 'b')
            , ( 4, pure 'c')
            , ( 1, pure 'd')
            ]

instance CoArbitrary Text where
    coarbitrary = coarbitraryShow

instance Function Text where
    function = functionShow

--------------------------------------------------------------------------------
-- Test keys
--------------------------------------------------------------------------------

newtype Key = Key Int
    deriving (Enum, Eq, Integral, Num, Ord, Real, Show)

instance Arbitrary Key where
    arbitrary = Key <$> choose (0, 15)
    shrink (Key k) = Key <$> shrink k

instance CoArbitrary Key where
    coarbitrary = coarbitraryIntegral

instance Function Key where
    function = functionIntegral

--------------------------------------------------------------------------------
-- Test constraints
--------------------------------------------------------------------------------

type Test k v = (TestKey k, TestValue v)

type TestKey k =
    ( Arbitrary k
    , CoArbitrary k
    , Function k
    , Ord k
    , Show k
    , Typeable k
    )

type TestValue v =
    ( Arbitrary v
    , CoArbitrary v
    , Eq v
    , Function v
    , MonoidNull v
    , Show v
    , Typeable v
    )

--------------------------------------------------------------------------------
-- Test types (for different type class constraints)
--------------------------------------------------------------------------------

data TestValueType (c :: Type -> Constraint) =
    forall v. (TestValue v, c v) => TestValueType (Proxy v)

testValueTypesMonoidNull :: [TestValueType MonoidNull]
testValueTypesMonoidNull =
    [ TestValueType (Proxy @(Dual Text))
    , TestValueType (Proxy @(Dual [Int]))
    , TestValueType (Proxy @(Dual [Natural]))
    , TestValueType (Proxy @(Set Int))
    , TestValueType (Proxy @(Set Natural))
    , TestValueType (Proxy @(Sum Int))
    , TestValueType (Proxy @(Sum Natural))
    , TestValueType (Proxy @(Product Int))
    , TestValueType (Proxy @(Product Natural))
    , TestValueType (Proxy @(Text))
    , TestValueType (Proxy @[Int])
    , TestValueType (Proxy @[Natural])
    ]

testValueTypesGroup :: [TestValueType Group]
testValueTypesGroup =
    [ TestValueType (Proxy @(Sum Int))
    ]

testValueTypesMonus :: [TestValueType Monus]
testValueTypesMonus =
    [ TestValueType (Proxy @(Set Int))
    , TestValueType (Proxy @(Set Natural))
    , TestValueType (Proxy @(Sum Natural))
    , TestValueType (Proxy @(Product Natural))
    ]

testValueTypesLeftReductive :: [TestValueType LeftReductive]
testValueTypesLeftReductive =
    [ TestValueType (Proxy @(Set Int))
    , TestValueType (Proxy @(Set Natural))
    , TestValueType (Proxy @(Sum Int))
    , TestValueType (Proxy @(Sum Natural))
    , TestValueType (Proxy @(Product Int))
    , TestValueType (Proxy @(Product Natural))
    , TestValueType (Proxy @[Int])
    , TestValueType (Proxy @[Natural])
    , TestValueType (Proxy @(Text))
    , TestValueType (Proxy @(Dual [Int]))
    , TestValueType (Proxy @(Dual [Natural]))
    , TestValueType (Proxy @(Dual Text))
    ]

testValueTypesRightReductive :: [TestValueType RightReductive]
testValueTypesRightReductive =
    [ TestValueType (Proxy @(Set Int))
    , TestValueType (Proxy @(Set Natural))
    , TestValueType (Proxy @(Sum Int))
    , TestValueType (Proxy @(Sum Natural))
    , TestValueType (Proxy @(Product Int))
    , TestValueType (Proxy @(Product Natural))
    , TestValueType (Proxy @[Int])
    , TestValueType (Proxy @[Natural])
    , TestValueType (Proxy @(Text))
    , TestValueType (Proxy @(Dual [Int]))
    , TestValueType (Proxy @(Dual [Natural]))
    , TestValueType (Proxy @(Dual Text))
    ]

testValueTypesReductive :: [TestValueType Reductive]
testValueTypesReductive =
    [ TestValueType (Proxy @(Set Int))
    , TestValueType (Proxy @(Set Natural))
    , TestValueType (Proxy @(Sum Int))
    , TestValueType (Proxy @(Sum Natural))
    , TestValueType (Proxy @(Product Int))
    , TestValueType (Proxy @(Product Natural))
    ]

testValueTypesLeftGCDMonoid :: [TestValueType LeftGCDMonoid]
testValueTypesLeftGCDMonoid =
    [ TestValueType (Proxy @(Set Int))
    , TestValueType (Proxy @(Set Natural))
    , TestValueType (Proxy @(Sum Natural))
    , TestValueType (Proxy @(Product Natural))
    , TestValueType (Proxy @(Text))
    , TestValueType (Proxy @(Dual Text))
    ]

testValueTypesRightGCDMonoid :: [TestValueType RightGCDMonoid]
testValueTypesRightGCDMonoid =
    [ TestValueType (Proxy @(Set Int))
    , TestValueType (Proxy @(Set Natural))
    , TestValueType (Proxy @(Sum Natural))
    , TestValueType (Proxy @(Product Natural))
    , TestValueType (Proxy @(Text))
    , TestValueType (Proxy @(Dual Text))
    ]

testValueTypesOverlappingGCDMonoid :: [TestValueType OverlappingGCDMonoid]
testValueTypesOverlappingGCDMonoid =
    [ TestValueType (Proxy @(Set Int))
    , TestValueType (Proxy @(Set Natural))
    , TestValueType (Proxy @(Sum Natural))
    , TestValueType (Proxy @(Product Natural))
    , TestValueType (Proxy @(Text))
    , TestValueType (Proxy @(Dual Text))
    ]

testValueTypesGCDMonoid :: [TestValueType GCDMonoid]
testValueTypesGCDMonoid =
    [ TestValueType (Proxy @(Set Int))
    , TestValueType (Proxy @(Set Natural))
    , TestValueType (Proxy @(Sum Natural))
    , TestValueType (Proxy @(Product Natural))
    ]

testValueTypesLCMMonoid :: [TestValueType LCMMonoid]
testValueTypesLCMMonoid =
    [ TestValueType (Proxy @(Set Int))
    , TestValueType (Proxy @(Set Natural))
    , TestValueType (Proxy @(Sum Natural))
    , TestValueType (Proxy @(Product Natural))
    ]

--------------------------------------------------------------------------------
-- Utilities
--------------------------------------------------------------------------------

makeSpec :: forall k v. Test k v => Spec -> Proxy k -> Proxy v -> Spec
makeSpec spec _k _v = describe (show $ typeRep (Proxy @(MonoidMap k v))) spec

property :: Testable t => t -> Property
property = checkCoverage . QC.property

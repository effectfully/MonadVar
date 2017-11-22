{-# LANGUAGE RankNTypes #-}
module MonadVar.Lens
  ( (./)
  , (.!)
  , _VarM
  , _Var
  ) where

import           MonadVar
import           Data.Functor.Identity
import           Data.Functor.Const
import           Data.Functor.Compose

infixl 8 ^.
infixr 9 ./, .!

-- We define our own lenses just to not depend on anything.
type LensLike f s t a b = (a -> f b) -> s -> f t
type Lens       s t a b = forall f. Functor f => LensLike f s t a b
type ASetter    s t a b = LensLike Identity s t a b

(^.) :: s -> LensLike (Const a) s t a b -> a
s ^. _L = getConst (_L Const s)
{-# INLINE (^.) #-}

_Of :: (s -> a) -> LensLike f s b a b
_Of f g = g . f
{-# INLINE _Of #-}

-- | Go down by '_L' into a data structure and apply '_M' to the result.
-- This throws away the non-'_L' part of a structure,
-- e.g. @('a', ('b', 'c')) & _2 ./ _2 %~ succ@ results in @('b','d')@.
(./)
  :: LensLike (Const s) v x s y
  -> LensLike  f        s t a b
  -> LensLike  f        v t a b
_L ./ _M = _Of (^. _L) . _M
{-# INLINE (./) #-}

effectful :: Functor f => Lens s t a b -> Lens s (f t) a (f b)
effectful _L f = getCompose . _L (Compose . f)
{-# INLINE effectful #-}

(.!)
  :: (Functor f, Functor g)
  => Lens       v  w    s t
  -> LensLike g s (f t) a b
  -> LensLike g v (f w) a b
_L .! _M = effectful _L . _M
{-# INLINE (.!) #-}

_VarM :: forall m n v a. MonadMutateM_ m n v => ASetter (v a) (n ()) a (m a)
_VarM f v = Identity . mutateM_ v $ runIdentity . f
{-# INLINE _VarM #-}

_Var :: forall m v a. MonadMutate_ m v => ASetter (v a) (m ()) a a
_Var f v = Identity . mutate_ v $ runIdentity . f
{-# INLINE _Var #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE UndecidableInstances #-}

module Text.PrettyPrint.Final.Extensions.Environment where

import Control.Applicative
import Control.Monad.Reader
import Control.Monad.State
import Control.Monad.Writer


import Text.PrettyPrint.Final as Final
import Text.PrettyPrint.Final.Extensions.Precedence

class MonadReaderEnv env m where
  askEnv :: m env
  localEnv :: (env -> env) -> m a -> m a

class ( MonadPretty w ann fmt m
      , MonadReaderEnv env m
      ) => MonadPrettyEnv env w ann fmt m
      | m -> w, m -> ann, m -> fmt, m -> env where


newtype EnvT env m a = EnvT { unEnvT :: ReaderT env m a }
  deriving
    ( Functor, Monad, Applicative, Alternative, MonadTrans
    , MonadState s, MonadWriter o
    )

runEnvT :: env -> EnvT env m a -> m a
runEnvT e xM = runReaderT (unEnvT xM) e

mapEnvT :: (m a -> n b) -> EnvT env m a -> EnvT env n b
mapEnvT f = EnvT . mapReaderT f . unEnvT

instance MonadReader r m => MonadReader r (EnvT env m) where
  ask = EnvT $ lift ask
  local f = mapEnvT (local f)

instance (Monad m, Measure w fmt m) => Measure w fmt (EnvT env m) where
  measure = lift . measure

instance MonadPretty w ann fmt m => MonadPretty w ann fmt (EnvT env m) where

instance Monad m => MonadReaderEnv env (EnvT env m) where
  askEnv = EnvT ask
  localEnv f = EnvT . local f . unEnvT

instance (Monad m, MonadReaderPrec ann m) => MonadReaderPrec ann (EnvT env m) where
  askPrecEnv = lift askPrecEnv
  localPrecEnv f (EnvT (ReaderT x)) = EnvT (ReaderT (\env -> localPrecEnv f (x env)))

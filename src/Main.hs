-- vim: set tw=99:

-- instapaper-sender: basic web -> Instapaper gateway
-- Copyright (C) 2017 Michael Smith <michael@spinda.net>

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU Affero General Public License for more details.

-- You should have received a copy of the GNU Affero General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Control.Applicative
import Control.Monad.IO.Class

import Data.Aeson
import Data.Default.Class

import qualified Data.ByteString.Lazy as LazyByteString

import qualified Data.Text as Text
import qualified Data.Text.Encoding as Text

import qualified Data.Text.Lazy as LazyText

import GHC.Generics

import Network.HaskellNet.Auth
import Network.HaskellNet.SMTP.SSL
import Network.HTTP.Types.Status
import Network.Socket
import Network.Wai
import Network.Wai.Middleware.RequestLogger

import System.Environment
import System.Exit

import Web.Scotty

type LazyText = LazyText.Text

data Config = Config { configHttpPort        :: !Int
                     , configSmtpHost        :: !String
                     , configSmtpPort        :: !Int
                     , configSmtpUsername    :: !String
                     , configSmtpPassword    :: !String
                     , configSmtpFrom        :: !String
                     , configInstapaperEmail :: !String
                     } deriving (Show, Generic)

instance FromJSON Config where
  parseJSON (Object v) = Config <$> ((v .: "http") >>= (.: "port"))
                                <*> ((v .: "smtp") >>= (.: "host"))
                                <*> ((v .: "smtp") >>= (.: "port"))
                                <*> ((v .: "smtp") >>= (.: "username"))
                                <*> ((v .: "smtp") >>= (.: "password"))
                                <*> ((v .: "smtp") >>= (.: "from"))
                                <*> ((v .: "instapaper") >>= (.: "email"))
  parseJSON _          = empty

main :: IO ()
main = do
  args <- getArgs
  cfgPath <- case args of
    [] -> return "config.json"
    [cfgPath] -> return cfgPath
    _ -> die "Usage: instapaper-sender [path to config.json]"
  cfgJson <- LazyByteString.readFile cfgPath
  cfg <- case eitherDecode cfgJson :: Either String Config of
    Right cfg -> return cfg
    Left msg -> die msg
  app cfg

app :: Config -> IO ()
app cfg = do
  logger <- mkRequestLogger def { outputFormat = Apache FromHeader }
  scotty (configHttpPort cfg) $ do
    middleware logger
    get (fullPath "url") $ do
      url <- LazyText.strip . LazyText.tail <$> param "url"
      if LazyText.null url
         then text "Append a URL to this web address to send it to Instapaper!"
         else do success <- liftIO $ sendToInstapaper cfg url
                 if success then text "Sent!" else status internalServerError500 >> text "Error :("

sendToInstapaper :: Config -> LazyText -> IO Bool
sendToInstapaper cfg url = doSMTPSSLWithSettings (configSmtpHost cfg) settings $ \conn -> do
  authSuccess <- authenticate LOGIN (configSmtpUsername cfg) (configSmtpPassword cfg) conn
  if authSuccess
    then True <$ sendPlainTextMail (configInstapaperEmail cfg) (configSmtpFrom cfg) "Instapaper"
                                   url conn
    else return False
  where
    settings = defaultSettingsSMTPSSL { sslPort = fromIntegral $ configSmtpPort cfg }

fullPath :: LazyText -> RoutePattern
fullPath key =
  function $ \req ->
    Just [(key, LazyText.fromStrict $ Text.decodeUtf8 $ rawPathInfo req)]

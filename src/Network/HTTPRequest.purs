module Network.HTTPClient where

import Prelude

import Data.HTTP.Method as HTTPMethod
import Data.HTTP.Types.Headers as HTTPHeaders
import DOM.Event.EventTarget as EventTarget
import Network.HTTP.Types.StatusCode as HTTPStatusCode
import Data.String as Str
import Data.URI as URI
import Web.XHR as XHR

-- RFC 7230: HTTP/1.1 Message Syntax and Routing
-- https://tools.ietf.org/html/rfc7230#section-3.2

newtype HTTPRequestBody = HTTPRequestBody String

type Username = String
type Password = String
newtype HTTPAuth = HTTPAuth (Maybe Username) (Maybe Password)

-- HTTP Request Message, as stated in RFC 7230
data HTTPRequest = HTTPRequest
  HTTPMethod.Method
  URI.URI
  -- HTTPVersion -- Not necessary?
  HTTPHeaders.Headers
  HTTPRequestBody
  HTTPAuth -- ??? Some servers require simple authentication. Is this best description?

newtype HTTPResponseBody = HTTPResponseBody String

data HTTPResponse = HTTPResponse
  -- HTTPVersion -- Not necessary?
  HTTPStatusCode.StatusCode
  HTTPHeaders.Headers
  HTTPResponseBody

data HTTPClient = HTTPClient (forall m. HTTPRequest -> m HTTPResponse)

sendHttpRequest :: HTTPClient -> HTTPRequest -> m HTTPResponse

--class HTTPClient c where
--  sendHttpRequest' :: forall m. MonadEff m =>
--      HTTPClient -> HTTPRequest -> m HTTPResponse
--  -- or --
--  sendHttpRequest :: forall m. MonadEff m =>
--      HTTPRequest -> m HTTPResponse
--  -- why do some HTTP clients have `auth` as argument?
--  -- sendHttpRequestAuthenticated :: forall m. MonadEff m =>
--  --     Tuple Auth HTTPRequest -> m HTTPResponse

-- ??? Is typeclass unnecessary?
--     Maybe use typeclass for environment constraint?
--     `getOAuthAccessToken :: MonadEff m => HTTPClientEnd m =>`
--     Maybe use purescript-run to have runtime provide the HTTPClient?


-----------
-- Make XMLHttpRequest fit the uniform HTTP client interface.

sendXhr :: MonadEff m => HTTPRequest -> m HTTPResponse
sendXhr (HTTPRequest method uri headers
    (HTTPRequestBody body)
    (HTTPAuth username password))
  = do
  -- To fit generic interface of `HTTPClient` can only send/receive `String`
  xhr :: XHR.XMLHttpRequest (ResponseType String)
    <- xmlHttpRequest XHR.string
  _ <- open' xhr
      { method: print method
      , url: print url
      , username
      , password
      })
      xhr
  _ <- for_ (toUnfoldable headers)
      (\Tuple h v -> XHR.setRequestHeader h v xhr)
  let xhrET = xmlHttpRequestToEventTarget xhr
  let onError _ = pure $ errorCb $ "XHR Request failed: " <> print method <> " " <> print url
  let onLoad evt = do
        statusCode <- (StatusCode <<< { code: _, reasonPhrase: _ })
            <$> XHR.status xhr <*> XHR.statusText xhr
        headers :: Maybe String <- XHR.getAllResponseHeaders xhr
        let headers' =
              fold (\header ->
                let colonIndex = Str.indexOf (Pattern ":")
                in singleton $ take colonIndex header $ drop (colonIndex + 1) header
                )
              $ filter (_ \= "")
              $ Str.split (Pattern "\r\n")
              -- ??? Hide the fact that response could contain no headers? Seems uncommon.
              $ fromMaybe "" headers
        body :: Maybe String <- XHR.response xhr
        let body' = case body of
              Just b -> pure b
              -- ??? How to make this stop if `Nothing`?
              Nothing -> pure $ errorCb "XHR response was null. Failure? "
                <> print method <> " " <> print url
        _ <- successCb $ HTTPResponse statusCode headers' (HTTPResponseBody body')
  EventTarget.addEventListener (EventType "error") $ eventListener onError $ true xhrET
  EventTarget.addEventListener (EventType "load") $ eventListener onLoad $ true xhrET
  -- ??? How to manage `withCredentials`? Always false? It seems more secure
  --_ <- if isCrossSiteRequest then XHR.setWithCredentials true isCredentials else pure unit
  sendString body

-- instance xhrHttpClient where
--   sendHttpRequest' :: forall m a b. MonadEff m =>
--       HTTPExchange -> HTTPRequest -> m HTTPResponse
--   sendHttpRequest' httpClient = send
--   sendHttpRequest :: forall m. MonadEff m =>
--       HTTPRequest -> m HTTPResponse
--   sendHttpRequest r = sendXhr r



-----------
-- Try using HTTPClient in OAuth library

data AuthTokenRequestParams = AuthTokenRequstParams
  ClientId RedirectURI (Maybe Scope) (Maybe CSRFToken)
newtype AuthToken = AuthToken String

getOAuthToken :: forall m. MonadEff m => HTTPClient httpClient =>
  HTTPClient
  -> AuthTokenRequestParams
  -> AuthorizationEndpoint
  -> TokenEndpoint
  -> m _ AccessToken
getOAuthToken httpClient req authEndpoint tokenEndpoint = do
  let
    makeRequestForAuthToken :: AuthTokenRequestParams -> AuthorizationEndpoint -> HTTPRequest
    makeRequestForAuthToken = ...
    makeRequestForAccessToken :: AuthTokenRequestParams -> AuthToken
        -> TokenEndpoint -> HTTPRequest
    makeRequestForAccessToken = ...
  authToken <- sendHttpRequest httpClient $ makeRequestForAuthToken req authEndpoint
  accessToken <- sendHttpRequest httpClient
      $ makeRequestForAccessToken req authToken tokenEndpoint
  pure accesstoken

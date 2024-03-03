{-# LANGUAGE OverloadedStrings #-}

import Data.Monoid (mappend)
import Hakyll
import Data.Functor ((<&>))

main :: IO ()
main = hakyll $ do
  match "static/*" $ do
    route $ gsubRoute "static/" (const "")
    compile copyFileCompiler

  match "sass/*" $ do
    route $ gsubRoute "sass/" (const "") `composeRoutes` setExtension "css"
    compile (sassCompiler <&> fmap compressCss)

  match "src/*.md" $ do
    route srcRoute
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/default.html" defaultContext

  match "src/blog/*" $ do
    route srcRoute
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/blog_page.html" postCtx
        >>= loadAndApplyTemplate "templates/default.html" postCtx
        >>= relativizeUrls

  create ["blog.html"] $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "src/blog/*"
      let blogCtx =
            listField "posts" postCtx (return posts)
              `mappend` constField "title" "Blog"
              `mappend` defaultContext

      makeItem ""
        >>= loadAndApplyTemplate "templates/blog.html" blogCtx
        >>= loadAndApplyTemplate "templates/default.html" blogCtx
        >>= relativizeUrls

  match "templates/*" $ compile templateBodyCompiler

srcRoute :: Routes
srcRoute = gsubRoute "src/" (const "") `composeRoutes` setExtension "html"

sassCompiler :: Compiler (Item String)
sassCompiler = getResourceString
        >>= withItemBody (unixFilter "sassc" ["-s"])

postCtx :: Context String
postCtx =
  dateField "date" "%B %e, %Y"
    `mappend` defaultContext

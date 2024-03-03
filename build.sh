#!/bin/sh
rm -r _site/*
cabal run site rebuild

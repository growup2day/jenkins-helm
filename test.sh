#!/bin/bash -e

helm unittest --helm3 --strict -f 'unittests/*.yaml' -f 'unittests/*/*.yaml' ./helm/ "$@"
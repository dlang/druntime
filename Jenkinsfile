#!/bin/env groovy

node {
    stage ("Load CI Scripts") {
        dir ("dlang/ci") {
            git "https://github.com/Dicebot/dlangci.git"
        }
    }

    load "dlang/ci/pipeline.groovy"
}

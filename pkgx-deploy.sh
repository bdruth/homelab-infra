#!/bin/bash

pkgx +tofu^1.7.1 +pip +ansible +ssh ./deploy.sh "$@"

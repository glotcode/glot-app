#!/bin/bash

killall workerd
wrangler pages dev ../dist

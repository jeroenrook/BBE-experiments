#!/usr/bin/env bash

for instance in ../../instances/*
do
	./scratch.R --instance $instance
done
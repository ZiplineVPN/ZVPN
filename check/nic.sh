#!/bin/bash
ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1
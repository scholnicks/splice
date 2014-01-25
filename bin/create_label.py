#!/usr/bin/python -B
# -*- coding: utf-8 -*-

'''
 
'''

import sys


def main(): 
    sys.exit(0)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description='splice')
    options = parser.parse_args()
    main()
#!/usr/bin/python3

import re
import sys
import os
import pyperclip


# res = os.system('node ./node_modules/')


def search(contract_name):
    contract_name = contract_name + '.sol'

    start_path = os.path.join(os.getcwd())

    return rec_search(contract_name, 'contracts')


def rec_search(file_name, start_path):
    cur_dir = os.listdir(start_path)
    if file_name in cur_dir:
        return os.path.join(start_path, file_name)

    for sub_dir in filter(os.path.isdir, cur_dir):
        res = rec_search(file_name, os.path.join(start_path, sub_dir))
        if res is not None:
            return res


def split_arr(way, arr):
    a = []
    b = []
    for left_right, item in zip(way, arr):
        if left_right:
            a.append(item)
        else:
            b.append(item)
    return a, b


def remove_context(fc):
    m = re.search(r'// File: @openzeppelin/contracts/GSN/Context\.sol', fc)
    if not m:
        return fc
    s, e = m.span()
    fc = fc[:s] + fc[e+1:]

    m = re.search(r'^(contract|library|abstract contract) Context {', fc, re.M)

    real_start, parse_start = m.span()

    curly_braces = 1
    quotes = None
    escaped = False
    i = parse_start
    first = 0
    for i, c in enumerate(fc[i:], start=parse_start+1):
        if first < 20:
            first += 1
        if not quotes:
            if c == '{':
                curly_braces += 1
            elif c == '}':
                curly_braces -= 1
            if c in '\'"':
                quotes = c
        else:
            if not escaped:
                if c == '\\':
                    escaped = True
                elif c == quotes:
                    quotes = None
            else:
                escaped = False
        if curly_braces == 0:
            break

    fc = fc[:real_start] + fc[i:]
    for pat in (r'Context, ', r', Context', 'is Context'):
        fc = re.sub(pat, '', fc)
    return re.sub(r'_msgSender\(\)', 'msg.sender', fc)


def process(flattened_contract, rm_context=True):
    if rm_context:
        flattened_contract = remove_context(flattened_contract)
    lines = flattened_contract.splitlines()
    licenses, lines = split_arr(
        [re.match('// SPDX-License-Identifier: [a-zA-Z-]', line) for line in lines], lines)
    lines = [licenses[0]] + lines

    return '\n'.join(lines)


if __name__ == '__main__':
    fp = search(sys.argv[1])
    print('fp:', fp)
    cmd = f'truffle-flattener ./{fp} > temp-output.txt'
    os.system(cmd)
    with open('temp-output.txt', 'r') as f:
        res = f.read()
    os.remove('temp-output.txt')

    rm_context = len(sys.argv) == 2 or sys.argv[2] == 'yes'

    res = process(res, rm_context)
    print(res)
    pyperclip.copy(res)

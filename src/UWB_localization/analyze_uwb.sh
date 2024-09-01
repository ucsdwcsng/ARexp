#!/bin/bash

cases=(0)

echo -e "0\n5\n0" | python 00_average_error.py
echo -e "1\n3\n0" | python 00_average_error.py
echo -e "2\n1\n0" | python 00_average_error.py
echo -e "3\n-1\n0" | python 00_average_error.py
echo -e "4\n-3\n0" | python 00_average_error.py
echo -e "5\n-5\n0" | python 00_average_error.py
echo -e "6\n5\n2" | python 00_average_error.py
echo -e "7\n3\n2" | python 00_average_error.py
echo -e "8\n1\n2" | python 00_average_error.py
echo -e "9\n-1\n2" | python 00_average_error.py
echo -e "10\n-3\n2" | python 00_average_error.py
echo -e "11\n-5\n2" | python 00_average_error.py
echo -e "12\n5\n4" | python 00_average_error.py
echo -e "13\n3\n4" | python 00_average_error.py
echo -e "14\n1\n4" | python 00_average_error.py
echo -e "15\n-1\n4" | python 00_average_error.py
echo -e "16\n-3\n4" | python 00_average_error.py
echo -e "17\n-5\n4" | python 00_average_error.py
echo -e "18\n5\n6" | python 00_average_error.py
echo -e "19\n3\n6" | python 00_average_error.py
echo -e "20\n1\n6" | python 00_average_error.py
echo -e "21\n-1\n6" | python 00_average_error.py
echo -e "22\n-3\n6" | python 00_average_error.py
echo -e "23\n-5\n6" | python 00_average_error.py

echo "All scripts are done"

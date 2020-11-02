echo "run linux echo command .....\n"

python3<<EOF  #/usr/bin/python3 绝对路径
print("call python interpretor\n")
import os
print(os.getcwd())
EOF

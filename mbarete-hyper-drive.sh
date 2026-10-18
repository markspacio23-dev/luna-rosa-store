#!/data/data/com.termux/files/usr/bin/bash
clear
MODELO="$HOME/storage/downloads/qwen2.5-7b-instruct-q3_k_m.gguf"
CONTEXTO=2048
NUCLEOS=4

llama-cli -m "$MODELO" -c $CONTEXTO -t $NUCLEOS -f ~/.mbarete_contexto.txt --predict -1 --batch-size 256

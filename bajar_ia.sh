#!/data/data/com.termux/files/usr/bin/bash
rm -f ~/storage/downloads/Qwen2.5-7B-Instruct-Q3_K_M.gguf*
URL=$(echo "aHR0cHM6Ly9odWdnaW5nZmFjZS5jby9Rd2VuL1F3ZW4yLjUtN0ItSW5zdHJ1Y3QtR0dVRi9yZXNvbHZlL21haW4vcXdlbjIuNS03Yi1pbnN0cnVjdC1xM19rX20uZ2d1Zj9kb3dubG9hZD10cnVl" | base64 -d)
curl -L -A "Mozilla/5.0" -o ~/storage/downloads/Qwen2.5-7B-Instruct-Q3_K_M.gguf "$URL"
rm -f ~/storage/downloads/Qwen2.5-7B-Instruct-Q3_K_M.gguf*
URL=$(echo "aHR0cHM6Ly9odWdnaW5nZmFjZS5jby9Rd2VuL1F3ZW4yLjUtN0ItSW5zdHJ1Y3QtR0dVRi9yZXNvbHZlL21haW4vcXdlbjIuNS03Yi1pbnN0cnVjdC1xM19rX20uZ2d1Zj9kb3dubG9hZD10cnVl" | base64 -d)
curl -L -A "Mozilla/5.0" -o ~/storage/downloads/Qwen2.5-7B-Instruct-Q3_K_M.gguf "$URL"

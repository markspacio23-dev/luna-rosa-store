#!/data/data/com.termux/files/usr/bin/bash
rm -f ~/storage/downloads/qwen1.5b.gguf*
URL=$(echo "aHR0cHM6Ly9odWdnaW5nZmFjZS5jby9Rd2VuL1F3ZW4yLjUtMS41Qi1JbnN0cnVjdC1HR1VGL3Jlc29sdmUvbWFpbi9xd2VuMi41LTEuNWItaW5zdHJ1Y3QtcTQ_a19tLmdndWY_ZG93bmxvYWQ9dHJ1ZQ==" | base64 -d)
curl -L -A "Mozilla/5.0" -o ~/storage/downloads/qwen1.5b.gguf "$URL"

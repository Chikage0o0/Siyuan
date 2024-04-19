import os
import sys
import requests

if len(sys.argv) < 2:
    print("Usage: python script.py <repository_name>")
    sys.exit(1)

# 从命令行参数获取仓库名称
repository_name = sys.argv[1]
api_url = f"https://api.github.com/repos/{repository_name}/tags"

response = requests.get(api_url)
tags = response.json()

# 查找最新的不是dev的tag
latest_tag = next((tag["name"] for tag in tags if not "dev" in tag["name"]), None)

if latest_tag:
    github_output = os.getenv("GITHUB_OUTPUT")
    with open(github_output, "a") as f:
        f.write(f"tag={latest_tag}\n")
else:
    print("No suitable tag found")
    exit(1)

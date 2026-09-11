#!/usr/bin/env python3
import os
import json
import urllib.request
import urllib.error

GITHUB_TOKEN = os.environ.get("PROJECT_READ_PAT")
if not GITHUB_TOKEN:
    print("Error: PROJECT_READ_PAT environment variable not set.")
    exit(1)

QUERY = """
query {
  user(login: "fezzik-the-giant") {
    projectV2(number: 1) {
      items(first: 100) {
        nodes {
          content {
            ... on Issue { title }
            ... on PullRequest { title }
            ... on DraftIssue { title }
          }
          fieldValues(first: 10) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field { ... on ProjectV2SingleSelectField { name } }
              }
            }
          }
        }
      }
    }
  }
}
"""

req = urllib.request.Request("https://api.github.com/graphql", method="POST")
req.add_header("Authorization", f"Bearer {GITHUB_TOKEN}")
req.add_header("Content-Type", "application/json")
data = json.dumps({"query": QUERY}).encode("utf-8")

try:
    response = urllib.request.urlopen(req, data=data)
    result = json.loads(response.read().decode("utf-8"))
except urllib.error.URLError as e:
    print(f"Error communicating with GitHub API: {e}")
    if hasattr(e, 'read'):
        print(e.read().decode("utf-8"))
    exit(1)

if "errors" in result:
    print(f"GraphQL Errors: {result['errors']}")
    exit(1)

project_data = result.get("data", {}).get("user", {}).get("projectV2", {})
if not project_data:
    print("Could not find project data. Make sure the PAT has read:project scope and the project number is correct.")
    exit(1)

items = project_data.get("items", {}).get("nodes", [])

categories = {}

for item in items:
    title = None
    if item.get("content"):
        title = item["content"].get("title")
    
    if not title:
        continue
        
    status = "No Status"
    for field_node in item.get("fieldValues", {}).get("nodes", []):
        if "field" in field_node and field_node["field"].get("name") == "Status":
            status = field_node.get("name")
            break
            
    if status not in categories:
        categories[status] = []
    categories[status].append(title)

# Generate Markdown
markdown_content = "# BrutalDots Roadmap\n\n"
markdown_content += "> *Automatically synchronized from the GitHub Project Board.*\n\n"

# Desired order if these statuses exist
status_order = ["Backlog", "In Progress", "In Review", "Done"]
existing_statuses = list(categories.keys())

for s in status_order:
    if s in existing_statuses:
        existing_statuses.remove(s)

# Append any other custom statuses at the end
final_order = status_order + existing_statuses

for status in final_order:
    if status not in categories:
        continue
    
    markdown_content += f"## {status}\n\n"
    for title in categories[status]:
        checkbox = "[ ]"
        status_tag = ""
        
        if status.lower() == "done":
            checkbox = "[x]"
        elif status.lower() == "in progress":
            checkbox = "[-]"
            status_tag = " **[IN PROGRESS]**"
        elif status.lower() == "in review":
            checkbox = "[?]"
            status_tag = " **[IN REVIEW]**"
            
        markdown_content += f"- {checkbox}{status_tag} {title}\n"
    markdown_content += "\n"

with open("ROADMAP.md", "w") as f:
    f.write(markdown_content)

print("Successfully updated ROADMAP.md")

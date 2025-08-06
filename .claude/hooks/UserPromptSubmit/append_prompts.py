#!/usr/bin/env python3
# @see https://x.com/mckaywrigley/status/1952466679239524624

import sys
import json


def main():
    try:
        # Read the input from stdin
        input_data = json.load(sys.stdin)
        # Get the user prompt from the data
        prompt = input_data.get("prompt", "")

        # Only append if prompt ends with -u flag
        if prompt.rstrip().endswith("-u"):
            # Remove the -u flag from the original prompt
            original_prompt = prompt.rstrip()[:-2].rstrip()
            # Append the ultrathink instruction
            additional_context = f"{original_prompt}\n\nUse the maximum amount of ultrathink. Take all the time you need. It's much better if you do too much research and thinking than not enough."

            # Return JSON output with additional context
            output = {
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "additionalContext": additional_context,
                }
            }
            print(json.dumps(output))

        # Exit successfully (allows prompt to proceed)
        sys.exit(0)
    except json.JSONDecodeError as e:
        print(f"Append hook failed: Invalid JSON input - {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Append hook failed: {str(e)}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

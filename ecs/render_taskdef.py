#!/usr/bin/env python3
"""Update the image URI (and APP_VERSION) in an ECS task definition JSON file.

Usage: render_taskdef.py <in.json> <out.json> <container-name> <image-uri>
"""
import json
import sys

# Fields AWS adds to a registered task definition. They must be removed
# before registering again, in case the input came from describe-task-definition.
READ_ONLY_FIELDS = (
    "taskDefinitionArn", "revision", "status", "requiresAttributes",
    "compatibilities", "registeredAt", "registeredBy", "deregisteredAt",
)


def main():
    if len(sys.argv) != 5:
        sys.exit(__doc__)
    src, dst, container_name, image = sys.argv[1:]

    with open(src) as f:
        taskdef = json.load(f)

    for field in READ_ONLY_FIELDS:
        taskdef.pop(field, None)

    version = image.rsplit(":", 1)[-1]
    found = False
    for container in taskdef["containerDefinitions"]:
        if container["name"] == container_name:
            container["image"] = image
            env = [e for e in container.get("environment", []) if e["name"] != "APP_VERSION"]
            env.append({"name": "APP_VERSION", "value": version})
            container["environment"] = env
            found = True

    if not found:
        sys.exit(f"Container '{container_name}' not found in {src}")

    with open(dst, "w") as f:
        json.dump(taskdef, f, indent=2)
    print(f"Set {container_name} image to {image}")


if __name__ == "__main__":
    main()

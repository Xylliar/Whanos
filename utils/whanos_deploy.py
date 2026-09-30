import json
import os
import subprocess
import sys

import yaml


def fail(message):
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def is_int(value):
    return isinstance(value, int) and not isinstance(value, bool)


def load_deployment(path):
    with open(path, encoding="utf-8") as stream:
        try:
            config = yaml.safe_load(stream)
        except yaml.YAMLError as error:
            fail(f"{path} is not valid YAML: {error}")

    if not isinstance(config, dict) or "deployment" not in config:
        return None

    deployment = config["deployment"] or {}
    if not isinstance(deployment, dict):
        fail("'deployment' must be a mapping")

    replicas = deployment.get("replicas", 1)
    if not is_int(replicas) or replicas < 0:
        fail("'deployment.replicas' must be a non-negative integer")

    resources = deployment.get("resources") or {}
    if not isinstance(resources, dict):
        fail("'deployment.resources' must follow the Kubernetes resources syntax")

    ports = deployment.get("ports") or []
    if not isinstance(ports, list) or not all(is_int(port) and 0 < port < 65536 for port in ports):
        fail("'deployment.ports' must be a list of port numbers")

    return replicas, resources, ports


def kubectl(*args, **kwargs):
    command = ["kubectl"]
    server = os.environ.get("WHANOS_KUBE_SERVER")
    if server:
        command += ["--server", server]
    result = subprocess.run(command + list(args), text=True, **kwargs)
    if result.returncode != 0:
        fail(result.stderr if kwargs.get("capture_output") else f"kubectl {' '.join(args)} failed")
    return result


def build_manifests(name, image, replicas, resources, ports):
    labels = {"app": name, "app.kubernetes.io/managed-by": "whanos"}
    container = {"name": name, "image": image, "resources": resources}
    if ports:
        container["ports"] = [{"containerPort": port} for port in ports]

    manifests = [{
        "apiVersion": "apps/v1",
        "kind": "Deployment",
        "metadata": {"name": name, "labels": labels},
        "spec": {
            "replicas": replicas,
            "selector": {"matchLabels": {"app": name}},
            "template": {"metadata": {"labels": labels}, "spec": {"containers": [container]}},
        },
    }]

    if ports:
        manifests.append({
            "apiVersion": "v1",
            "kind": "Service",
            "metadata": {"name": name, "labels": labels},
            "spec": {
                "type": "NodePort",
                "selector": {"app": name},
                "ports": [{"name": f"port-{port}", "port": port, "targetPort": port} for port in ports],
            },
        })

    return {"apiVersion": "v1", "kind": "List", "items": manifests}


def main():
    if len(sys.argv) != 4:
        fail(f"usage: {sys.argv[0]} <whanos.yml> <name> <image>")
    path, name, image = sys.argv[1:]

    deployment = load_deployment(path)
    if deployment is None:
        print(f"{path} has no 'deployment' property: skipping deployment")
        return
    replicas, resources, ports = deployment

    if not ports:
        kubectl("delete", "service", name, "--ignore-not-found")
    kubectl("apply", "-f", "-", input=json.dumps(build_manifests(name, image, replicas, resources, ports)))
    kubectl("rollout", "status", f"deployment/{name}", "--timeout=300s")

    if ports:
        service = json.loads(kubectl("get", "service", name, "-o", "json", capture_output=True).stdout)
        host = os.environ.get("WHANOS_PUBLIC_HOST", "localhost")
        for port in service["spec"]["ports"]:
            print(f"Port {port['port']} is reachable at {host}:{port['nodePort']}")


if __name__ == "__main__":
    main()

# Lab environment

All technologies run in **Podman** pods, so everyone works in the same environment as in class.
Installation instructions (WSL 2, Podman Desktop, Git) were sent at the start of the semester and are on Moodle.

| File | What it starts | For which exercises |
|---|---|---|
| [`anaconda_jupyter.yaml`](anaconda_jupyter.yaml) | Jupyter Notebook with the Anaconda distribution (pandas, numpy, scipy, matplotlib, seaborn, scikit-learn …) | EX_5 |

## Starting the Jupyter pod

1. Download `anaconda_jupyter.yaml` to your computer (on GitHub: open the file → **Download raw file** button).
2. **Podman Desktop → Pods → Play Kubernetes YAML** → choose the file → **Play**.
   (Or in a terminal: `podman kube play anaconda_jupyter.yaml`.)
3. The first start downloads an image of several GB – wait until it finishes.
4. **Containers → jupyter-notebook-anaconda → Logs**: copy the address `http://127.0.0.1:8888/tree?token=…` and open it in your browser.

Files are stored in the Podman volume `notebook-storage-pvc` (folder `/opt/notebooks` in the container),
so they are kept when you stop and restart the pod.

Next time just start the pod (**Pods → jupyter-notebook-anaconda → Start**) and take the address with the token from Logs again.

How to get the materials from this repository into the pod is described in the [main README](../README.md#first-time-getting-the-repository).

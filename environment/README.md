# Lab environment

All technologies run in **Podman** pods, so everyone works in the same environment as in class.
Installation instructions (WSL 2, Podman Desktop, Git) were sent at the start of the semester and are on Moodle.

| File | What it starts | For which exercises |
|---|---|---|
| [`anaconda_jupyter.yaml`](anaconda_jupyter.yaml) | Jupyter Notebook with the Anaconda distribution (pandas, numpy, scipy, matplotlib, seaborn, scikit-learn …) | EX_5 |
| [`sql_pod.yaml`](sql_pod.yaml) | PostgreSQL 18 + pgAdmin 4 with the course databases | EX_6 |

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

## Starting the SQL pod

1. Download `sql_pod.yaml` to your computer (on GitHub: open the file → **Download raw file** button).
2. **Podman Desktop → Pods → Play Kubernetes YAML** → choose the file → **Play**.
   (Or in a terminal: `podman kube play sql_pod.yaml`.)
3. The first start downloads the images `postgres:18` and `dpage/pgadmin4` and fills the databases – wait a minute or two.
4. Open **pgAdmin** at <http://localhost:8081> and log in with `admin@admin.com` / `admin`.
5. The server **Algebra Bernays - Data Engineering** is already there. The first time you connect, enter the database password `mypassword` (you can tick *Save Password*).
6. Databases → **`transactional`** → right-click → **Query Tool**.

| What | Value |
|---|---|
| pgAdmin | <http://localhost:8081>, `admin@admin.com` / `admin` |
| PostgreSQL from your computer (DBeaver, VS Code …) | `localhost:5433`, user `myuser`, password `mypassword` |
| Databases | `transactional` (schema `public` = online shop, schema `raw` = raw data), `dwh` (star schema) |

The data is stored in the Podman volume `de-postgres18-data`, and the scripts you save in pgAdmin in `de-pgadmin-data` – both are kept when you stop and restart the pod.
Next time just start the pod: **Pods → postgres-pgadmin-pod → Start**.

To reset the database to its original state: stop and delete the pod, delete the volume `de-postgres18-data` (Podman Desktop → Volumes) and play the YAML again.
Then run the preparation script of the exercise (e.g. `EX_6_prep.sql`) again.

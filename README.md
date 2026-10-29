# Data Engineering (2026/2027)

Lab materials for the course **Data Engineering** at Algebra Bernays University, academic year 2026/2027.
Each exercise has its own folder with Jupyter notebooks, SQL scripts, Python and other code, data and helper files.
The README in each folder explains what is there and how to work with it.

## Exercises

| Folder | Topic | Environment |
|---|---|---|
| [`EX_5/`](EX_5/) | Handling missing values | Jupyter pod |

New exercises will be added to new folders during the semester (`EX_6/`, `EX_7/` …), so pull the newest version before every lab (see below).

## Repository structure

```
Data-Engineering-2026-2027/
├─ README.md            ← this file
├─ environment/         ← YAML files for the Podman pods (Jupyter, later SQL)
└─ EX_n/                ← one folder per exercise
   ├─ README.md         ← instructions for that exercise
   ├─ *.ipynb, *.sql, *.py …  ← notebooks, SQL scripts and other code (depending on the exercise)
   ├─ data/             ← datasets (if the exercise uses any)
   └─ images/           ← images for the notebooks (if any)
```

## First time: getting the repository

We work in the **Jupyter pod** (how to start it: [`environment/README.md`](environment/README.md)).
The pod has its own disk (a volume), so the repository is cloned **inside Jupyter**, not on Windows:

1. Start the Jupyter pod and open Jupyter in your browser.
2. In the file browser choose **New → Terminal**.
3. Type in the terminal (the first line matters – the terminal opens in the folder `/`, but Jupyter only shows the folder `/opt/notebooks`):
   ```bash
   cd /opt/notebooks
   git clone https://github.com/MySlav/Data-Engineering-2026-2027.git
   ```
   If you cloned without `cd` and don't see the folder, move it: `mv /Data-Engineering-2026-2027 /opt/notebooks/`.
4. The folder `Data-Engineering-2026-2027` appears in the file browser. Open the exercise folder and follow its README.

For SQL exercises you open the scripts in the tool that exercise names (e.g. pgAdmin). How to get them there is described in that exercise's README.

## Before every lab: pull the news

In the Jupyter terminal:
```bash
cd /opt/notebooks/Data-Engineering-2026-2027
git pull
```
In Jupyter notebooks you can also do it from the notebook – the first code cell is `!git pull`.

## Work in your own copy

Before you start solving tasks, save a copy of the task file and add `_my_work` to its name:
* notebook: **File → Save Notebook As…** → e.g. `EX_5_my_work.ipynb`,
* SQL script or other code: e.g. `EX_6_tasks_my_work.sql`.

If you edit the original file and the instructor later publishes a fix to the same file, `git pull` reports an error
(*Your local changes … would be overwritten by merge*). Files with `_my_work` in the name are ignored by git, so `git pull` never touches them.

If it happens anyway:
```bash
git status          # shows which original files you changed
git stash           # puts your changes aside
git pull            # pulls the new version
git stash pop       # brings your changes back (if it reports a conflict, save your work as a copy and repeat)
```

## If `git clone` does not work

On GitHub click **Code → Download ZIP** and unpack the archive on your computer.
For Jupyter exercises upload the exercise folder to Jupyter with the **Upload** button (files inside `data/` and `images/` go into the same subfolders).
You then cannot pull updates with `git pull` – download the ZIP again instead.

## Solutions

Solutions are not in the repository before the lab. If they are published, they will be in the `solutions/` subfolder of that exercise.

## Data sources

The datasets come from public sources and are used for teaching only. The source is listed in the README of each exercise.

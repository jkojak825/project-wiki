---
title: Activating the Discernment Journal Venv and not the Project Wiki Venv
prerequisites:
  - ""
steps:
  - ""
verification: >-
  <!--StartFragment -->


  deactivate


  source ~/discernment-journal/venv/bin/activate






  That traceback is clear: your app is trying to import `matplotlib.pyplot` on line 4 of `app.py`, but the library isn’t installed in your virtual environment. That’s why Flask can’t even start.


  - - -


  ### ✅ Fix


  1. Make sure you’re inside your virtual environment (`(.venv)` shows you are).

  2. Install matplotlib:

     ```bash
     pip install matplotlib
     ```

     or, if you want to keep dependencies consistent:

     ```bash
     pip install -r requirements.txt
     ```

     (and add `matplotlib` to `requirements.txt` if it isn’t already listed).
  3. Verify installation:

     ```bash
     python -c "import matplotlib; print(matplotlib.__version__)"
     ```

     If that prints a version number, you’re good.
  4. Relaunch:

     ```bash
     flask run
     ```

     or

     ```bash
     python app.py
     ```

  - - -


  ### ⚠️ Notes


  * If you don’t actually need plotting in your journaling app, you can comment out or remove the `import matplotlib.pyplot as plt` line in `app.py`. That will let Flask start without installing matplotlib.

  * If you do need it (for generating charts in reports), then installing it is the right move.


  - - -


  👉 So the immediate fix is: **install matplotlib in your venv** or remove the import if it’s not required.


  Do you want me to check your `requirements.txt` and suggest the exact line to add so you don’t forget to include matplotlib in future deployments?


  <!--EndFragment -->
notes: "- "
---

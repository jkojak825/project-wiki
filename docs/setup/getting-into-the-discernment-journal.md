---
title: Getting into the Discernment Journal
prerequisites:
  - ""
steps:
  - ""
verification: >-
  <!--StartFragment -->


  Since your project is a Flask‑style app (judging by `app.py`, `templates/`, and `instance/`), you can launch it locally with a few straightforward steps:


  - - -


  ### ✅ Launching your discernment journal app


  1. **Activate your virtual environment** (looks like you already have `.venv`): 

     ```bash
     source venv/bin/activate
     ```

     or if you’re already inside `.venv` (your prompt shows `(.venv)`), you can skip this.
  2.

  3. **Set the Flask app environment variable**:

     ```bash
     export FLASK_APP=app.py
     ```

     (On Windows PowerShell, use `set FLASK_APP=app.py` instead.)
  4. **Run the app**:

     ```bash
     flask run
     ```

     By default, Flask will start a development server at:

     ```
     http://127.0.0.1:5000
     ```

     You can open that in your browser to see your journaling portal.

  - - -


  ### ⚠️ Common gotchas


  * If you’ve defined an `app` object inside `app.py` (e.g. `app = Flask(__name__)`), Flask will find it automatically.

  * If you’re using `python app.py` instead of `flask run`, make sure you have a `if __name__ == "__main__": app.run()` block at the bottom of `app.py`.

  * If you get errors about missing packages, install them from `requirements.txt`:

    ```bash
    pip install -r requirements.txt
    ```

  - - -


  👉 Once it’s running, you’ll be able to interact with your templates and routes again.


  Do you want me to check your `app.py` structure and confirm whether you should launch with `flask run` or `python app.py`? That way you’ll know the exact command that matches your setup.


  <!--EndFragment -->
notes: "- "
---

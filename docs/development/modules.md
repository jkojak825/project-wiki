---
title: "Accessing Postgre and Exiting "
design: >-
  <!--StartFragment -->


  Excellent progress, John — you’ve successfully created the database and user 🎉. The only hiccup is the way you’re trying to connect as `journal_user`. Right now you’re still inside the **psql shell as `postgres`**, so when you type:


  ```sql

  psql -U journal_user -d discernment_journal -h localhost

  ```


  Postgres interprets that as SQL, not a shell command — that’s why you see `postgres-#` instead of connecting.


  - - -


  ### ✅ Correct way to connect as `journal_user`


  1. **Exit the psql shell**\
     Type:

     ```
     \q
     ```

     That will drop you back to your Linux shell prompt (`john@Dev:~$`).
  2. **Run the connection command from the shell**\
     Now run:

     ```bash
     psql -U journal_user -d discernment_journal -h localhost
     ```

     It will prompt you for the password you set (`yourpassword`).\
     Once entered, you should see:

     ```
     discernment_journal=>
     ```

     That means you’re connected as `journal_user` to your new database.

  - - -


  ### ✅ Next step: wire Flask to Postgres


  In your `app.py`:


  ```python

  app.config['SQLALCHEMY_DATABASE_URI'] = (
      'postgresql://journal_user:yourpassword@localhost/discernment_journal'
  )

  ```


  Then initialize SQLAlchemy and create your tables:


  ```python

  from flask_sqlalchemy import SQLAlchemy

  db = SQLAlchemy(app)


  # Example model

  class JournalEntry(db.Model):
      id = db.Column(db.Integer, primary_key=True)
      title = db.Column(db.String(200), nullable=False)
      content = db.Column(db.Text, nullable=False)
  ```


  Run once in Python shell:


  ```bash

  python

  ```


  ```python

  from app import db

  db.create_all()

  ```


  - - -


  👉 So the immediate fix: **exit psql with `\q` and run the `psql -U journal_user ...` command from your shell, not inside psql.**


  Do you want me to sketch a **minimal Flask app with one route to insert and one to list journal entries** so you can test the Postgres connection end‑to‑end?


  <!--EndFragment -->
---

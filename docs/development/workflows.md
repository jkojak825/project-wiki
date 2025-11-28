---
design: >-
  <!--StartFragment -->


  **Refactor plan**


  I need to break down the refactor plan into clear steps with a timeline. I'll follow the formatting rules, using headings that state the topic and avoiding parentheses. I'll include a code block for app.py, ensuring it's runnable with a DATABASE_URL environment variable defaulting to SQLite. I'll use SQLAlchemy and Flask-Migrate, but migrations will be optional. The code will include `db.create_all` if migrations aren't used. I'll also include helpers for safe commits, date parsing, logging, file uploads, and CSV exports. I'll avoid conflicts with `reportlab.platypus` and use `ImageReader` for embedding.


  ### Cleaned runnable `app.py`


  Below is a single‑file, cleaned, runnable `app.py` that integrates the immediate fixes and best practices we discussed: environment variable configuration, safe DB commits, `to_dict()` methods, CSV streaming, robust PDF/chart embedding using `ImageReader`, date parsing/formatting, basic input validation, and logging. It defaults to a local SQLite DB for easy testing but will use `DATABASE_URL` if provided.


  Copy this into your project, install the dependencies (`Flask`, `Flask-SQLAlchemy`, `matplotlib`, `reportlab`, `werkzeug`), and run it with `python app.py` for quick testing. For production, use the refactor plan below (migrations, factory + blueprints, auth, etc.).


  ```python

  # app.py

  import csv

  import io

  import os

  import logging

  from datetime import datetime, date

  from typing import Optional


  import matplotlib.pyplot as plt

  from flask import (
      Flask,
      request,
      jsonify,
      Response,
      send_file,
      render_template,
      abort,
  )

  from flask_sqlalchemy import SQLAlchemy

  from werkzeug.utils import secure_filename

  from reportlab.lib.pagesizes import letter

  from reportlab.pdfgen import canvas

  from reportlab.lib.utils import ImageReader


  # --- Configuration and logging ---

  logging.basicConfig(level=logging.INFO)

  logger = logging.getLogger("discernment_journal")


  DATABASE_URL = os.getenv(
      "DATABASE_URL", "sqlite:///discernment_journal_dev.db"
  )  # override in prod with env var


  UPLOAD_FOLDER = os.getenv("UPLOAD_FOLDER", "uploads")

  os.makedirs(UPLOAD_FOLDER, exist_ok=True)

  ALLOWED_EXTENSIONS = {"pdf", "txt", "md", "png", "jpg", "jpeg"}


  # --- Flask App Setup ---

  app = Flask(__name__)

  app.config["SQLALCHEMY_DATABASE_URI"] = DATABASE_URL

  app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

  app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER

  app.config["MAX_CONTENT_LENGTH"] = 16 * 1024 * 1024  # 16 MB upload limit


  db = SQLAlchemy(app)



  # --- Helpers ---

  def safe_commit():
      try:
          db.session.commit()
      except Exception as exc:
          db.session.rollback()
          logger.exception("Database commit failed")
          abort(500, description="Database error")


  def parse_iso_date(value: Optional[str]) -> Optional[date]:
      if not value:
          return None
      try:
          # Accept both date and datetime ISO strings
          dt = datetime.fromisoformat(value)
          return dt.date()
      except Exception:
          try:
              return datetime.strptime(value, "%Y-%m-%d").date()
          except Exception:
              return None


  def allowed_file(filename: str) -> bool:
      return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


  # --- Models ---

  class JournalEntry(db.Model):
      id = db.Column(db.Integer, primary_key=True)
      date = db.Column(db.DateTime, default=datetime.utcnow)
      ministry_activities = db.Column(db.Text)
      study_insights = db.Column(db.Text)
      reflection = db.Column(db.Text)

      def to_dict(self):
          return {
              "id": self.id,
              "date": self.date.isoformat() if self.date else None,
              "ministry_activities": self.ministry_activities,
              "study_insights": self.study_insights,
              "reflection": self.reflection,
          }


  class PrayerReading(db.Model):
      id = db.Column(db.Integer, primary_key=True)
      title = db.Column(db.String(200))
      occasion = db.Column(db.String(200))
      text = db.Column(db.Text)
      tags = db.Column(db.String(200))
      date_delivered = db.Column(db.Date)

      def to_dict(self):
          return {
              "id": self.id,
              "title": self.title,
              "occasion": self.occasion,
              "text": self.text,
              "tags": self.tags,
              "date_delivered": self.date_delivered.isoformat()
              if self.date_delivered
              else None,
          }


  class Assignment(db.Model):
      id = db.Column(db.Integer, primary_key=True)
      title = db.Column(db.String(200))
      course = db.Column(db.String(200))
      topic = db.Column(db.String(200))
      submission_date = db.Column(db.Date)
      text = db.Column(db.Text)
      tags = db.Column(db.String(200))

      def to_dict(self):
          return {
              "id": self.id,
              "title": self.title,
              "course": self.course,
              "topic": self.topic,
              "submission_date": self.submission_date.isoformat()
              if self.submission_date
              else None,
              "text": self.text,
              "tags": self.tags,
          }


  class ReadingJournal(db.Model):
      id = db.Column(db.Integer, primary_key=True)
      book_title = db.Column(db.String(200), nullable=False)
      author = db.Column(db.String(200), nullable=False)
      chapter = db.Column(db.String(50))
      passage = db.Column(db.Text)
      initial_thoughts = db.Column(db.Text)
      questions = db.Column(db.Text)
      date = db.Column(db.DateTime, default=datetime.utcnow)

      def to_dict(self):
          return {
              "id": self.id,
              "book_title": self.book_title,
              "author": self.author,
              "chapter": self.chapter,
              "passage": self.passage,
              "initial_thoughts": self.initial_thoughts,
              "questions": self.questions,
              "date": self.date.isoformat() if self.date else None,
          }


  # --- Create tables for quick testing (use migrations in production) ---

  with app.app_context():
      db.create_all()


  # --- Basic routes and health ---

  @app.route("/")

  def home():
      return render_template("home.html") if os.path.exists("templates/home.html") else "Discernment Journal API"


  @app.route("/health")

  def health():
      return jsonify({"status": "ok"})


  # --- Journal Endpoints ---

  @app.route("/api/journal", methods=["POST"])

  def create_entry():
      data = request.get_json(force=True, silent=True)
      if not data:
          return jsonify({"error": "Invalid JSON"}), 400

      entry = JournalEntry(
          date=datetime.fromisoformat(data["date"]) if data.get("date") else datetime.utcnow(),
          ministry_activities=data.get("ministry_activities"),
          study_insights=data.get("study_insights"),
          reflection=data.get("reflection"),
      )
      db.session.add(entry)
      safe_commit()
      return jsonify({"message": "Entry created", "id": entry.id}), 201


  @app.route("/api/journal", methods=["GET"])

  def list_entries():
      entries = JournalEntry.query.order_by(JournalEntry.date.desc()).all()
      return jsonify([e.to_dict() for e in entries])


  # --- Prayer Endpoints ---

  @app.route("/api/prayers", methods=["POST"])

  def create_prayer():
      data = request.get_json(force=True, silent=True)
      if not data:
          return jsonify({"error": "Invalid JSON"}), 400

      date_delivered = parse_iso_date(data.get("date_delivered"))
      prayer = PrayerReading(
          title=data.get("title"),
          occasion=data.get("occasion"),
          text=data.get("text"),
          tags=data.get("tags"),
          date_delivered=date_delivered,
      )
      db.session.add(prayer)
      safe_commit()
      return jsonify({"message": "Prayer created", "id": prayer.id}), 201


  @app.route("/api/prayers", methods=["GET"])

  def list_prayers():
      prayers = PrayerReading.query.order_by(PrayerReading.date_delivered.desc().nullslast()).all()
      return jsonify([p.to_dict() for p in prayers])


  # --- Assignment Endpoints ---

  @app.route("/api/assignments", methods=["POST"])

  def create_assignment():
      data = request.get_json(force=True, silent=True)
      if not data:
          return jsonify({"error": "Invalid JSON"}), 400

      submission_date = parse_iso_date(data.get("submission_date"))
      assignment = Assignment(
          title=data.get("title"),
          course=data.get("course"),
          topic=data.get("topic"),
          submission_date=submission_date,
          text=data.get("text"),
          tags=data.get("tags"),
      )
      db.session.add(assignment)
      safe_commit()
      return jsonify({"message": "Assignment created", "id": assignment.id}), 201


  @app.route("/api/assignments", methods=["GET"])

  def list_assignments():
      assignments = Assignment.query.order_by(Assignment.submission_date.desc().nullslast()).all()
      return jsonify([a.to_dict() for a in assignments])


  # --- CSV Export helpers ---

  def stream_csv(rows_iterable, header, filename="export.csv"):
      def generate():
          output = io.StringIO()
          writer = csv.writer(output)
          writer.writerow(header)
          yield output.getvalue()
          output.seek(0)
          output.truncate(0)
          for row in rows_iterable:
              writer.writerow(row)
              yield output.getvalue()
              output.seek(0)
              output.truncate(0)

      headers = {
          "Content-Disposition": f'attachment; filename="{filename}"',
          "Content-Type": "text/csv; charset=utf-8",
      }
      return Response(generate(), headers=headers)


  # --- Export endpoints ---

  @app.route("/api/export/journal", methods=["GET"])

  def export_journal():
      entries = JournalEntry.query.order_by(JournalEntry.date.desc()).all()
      rows = (
          (
              e.id,
              e.date.isoformat() if e.date else "",
              e.ministry_activities or "",
              e.study_insights or "",
              e.reflection or "",
          )
          for e in entries
      )
      return stream_csv(rows, ["id", "date", "ministry_activities", "study_insights", "reflection"], "journal.csv")


  @app.route("/api/export/prayers", methods=["GET"])

  def export_prayers():
      prayers = PrayerReading.query.order_by(PrayerReading.date_delivered.desc().nullslast()).all()
      rows = (
          (
              p.id,
              p.title or "",
              p.occasion or "",
              p.text or "",
              p.tags or "",
              p.date_delivered.isoformat() if p.date_delivered else "",
          )
          for p in prayers
      )
      return stream_csv(rows, ["id", "title", "occasion", "text", "tags", "date_delivered"], "prayers.csv")


  @app.route("/api/export/assignments", methods=["GET"])

  def export_assignments():
      assignments = Assignment.query.order_by(Assignment.submission_date.desc().nullslast()).all()
      rows = (
          (
              a.id,
              a.title or "",
              a.course or "",
              a.topic or "",
              a.submission_date.isoformat() if a.submission_date else "",
              a.text or "",
              a.tags or "",
          )
          for a in assignments
      )
      return stream_csv(rows, ["id", "title", "course", "topic", "submission_date", "text", "tags"], "assignments.csv")


  # --- Visualization endpoints (return PNG images) ---

  def fig_to_image_response(fig):
      buf = io.BytesIO()
      fig.savefig(buf, format="png", bbox_inches="tight")
      plt.close(fig)
      buf.seek(0)
      return send_file(buf, mimetype="image/png")


  @app.route("/api/visualize/journal_timeline", methods=["GET"])

  def visualize_journal_timeline():
      entries = JournalEntry.query.all()
      counts = {}
      for e in entries:
          key = e.date.date().isoformat() if e.date else "unknown"
          counts[key] = counts.get(key, 0) + 1

      dates = sorted(counts.keys())
      values = [counts[d] for d in dates]

      fig, ax = plt.subplots()
      ax.plot(dates, values, marker="o")
      ax.set_title("Journal Entries Over Time")
      ax.set_xlabel("Date")
      ax.set_ylabel("Number of Entries")
      fig.autofmt_xdate()
      return fig_to_image_response(fig)


  @app.route("/api/visualize/activity_distribution", methods=["GET"])

  def visualize_activity_distribution():
      entries = JournalEntry.query.all()
      activities = {}
      for e in entries:
          act = (e.ministry_activities or "Unknown").strip()
          activities[act] = activities.get(act, 0) + 1

      fig, ax = plt.subplots()
      ax.pie(list(activities.values()), labels=list(activities.keys()), autopct="%1.1f%%", startangle=90)
      ax.set_title("Ministry Activity Distribution")
      plt.tight_layout()
      return fig_to_image_response(fig)


  @app.route("/api/visualize/vocation_trends", methods=["GET"])

  def visualize_vocation_trends():
      entries = JournalEntry.query.all()
      reader_count = 0
      ordained_count = 0
      for e in entries:
          text = (e.reflection or "").lower()
          if "reader" in text:
              reader_count += 1
          if "ordained" in text or "priest" in text or "priests" in text:
              ordained_count += 1

      fig, ax = plt.subplots()
      bars = ax.bar(["Reader", "Ordained"], [reader_count, ordained_count])
      ax.set_title("Vocation Trends")
      ax.set_ylabel("Mentions in Reflections")
      for bar in bars:
          height = bar.get_height()
          ax.annotate(f"{height}", xy=(bar.get_x() + bar.get_width() / 2, height), xytext=(0, 3), textcoords="offset points", ha="center", va="bottom")
      plt.tight_layout()
      return fig_to_image_response(fig)


  # --- PDF export helpers ---

  def embed_matplotlib_figure_on_canvas(c: canvas.Canvas, fig, x=50, y=400, width=400, height=200):
      buf = io.BytesIO()
      fig.savefig(buf, format="png", bbox_inches="tight")
      plt.close(fig)
      buf.seek(0)
      img = ImageReader(buf)
      c.drawImage(img, x, y, width=width, height=height)


  @app.route("/api/export/journal/pdf", methods=["GET"])

  def export_journal_pdf():
      entries = JournalEntry.query.order_by(JournalEntry.date.desc()).all()
      buffer = io.BytesIO()
      c = canvas.Canvas(buffer, pagesize=letter)
      width, height = letter

      c.setFont("Helvetica-Bold", 16)
      c.drawString(50, height - 50, "Journal Portfolio Report")
      c.setFont("Helvetica", 12)
      y = height - 100
      for e in entries:
          date_str = e.date.strftime("%Y-%m-%d") if e.date else "N/A"
          text_lines = [
              f"ID: {e.id}",
              f"Date: {date_str}",
              f"Activities: {e.ministry_activities or ''}",
              f"Insights: {e.study_insights or ''}",
              f"Reflection: {e.reflection or ''}",
          ]
          for line in text_lines:
              c.drawString(50, y, line[:120])
              y -= 18
              if y < 60:
                  c.showPage()
                  c.setFont("Helvetica", 12)
                  y = height - 50
          y -= 8

      c.save()
      buffer.seek(0)
      return send_file(buffer, mimetype="application/pdf", as_attachment=True, download_name="journal_report.pdf")


  # --- Combined portfolio PDF with charts (lightweight) ---

  @app.route("/api/export/portfolio/pdf", methods=["GET"])

  def export_portfolio_pdf():
      buffer = io.BytesIO()
      c = canvas.Canvas(buffer, pagesize=letter)
      width, height = letter

      # Title
      c.setFont("Helvetica-Bold", 20)
      c.drawString(50, height - 50, "Discernment Portfolio Report")
      c.setFont("Helvetica", 12)
      c.drawString(50, height - 80, "Includes Journals, Prayers, Assignments, and Charts")
      c.showPage()

      # Add a chart: Journal timeline
      entries = JournalEntry.query.all()
      counts = {}
      for e in entries:
          if e.date:
              key = e.date.date().isoformat()
              counts[key] = counts.get(key, 0) + 1
      dates = sorted(counts.keys())
      values = [counts[d] for d in dates]
      fig, ax = plt.subplots()
      ax.plot(dates, values, marker="o")
      ax.set_title("Journal Entries Over Time")
      fig.autofmt_xdate()
      embed_matplotlib_figure_on_canvas(c, fig, x=50, y=height - 300, width=480, height=220)
      c.showPage()

      # Finalize
      c.save()
      buffer.seek(0)
      return send_file(buffer, mimetype="application/pdf", as_attachment=True, download_name="portfolio_report.pdf")


  # --- File upload endpoint (basic validation) ---

  @app.route("/api/upload", methods=["POST"])

  def upload_file():
      if "file" not in request.files:
          return jsonify({"error": "No file uploaded"}), 400
      file = request.files["file"]
      if file.filename == "":
          return jsonify({"error": "Empty filename"}), 400
      if not allowed_file(file.filename):
          return jsonify({"error": "File type not allowed"}), 400
      filename = secure_filename(file.filename)
      path = os.path.join(app.config["UPLOAD_FOLDER"], filename)
      file.save(path)
      return jsonify({"message": f"File {filename} uploaded successfully"}), 201


  # --- Error handlers ---

  @app.errorhandler(400)

  def bad_request(e):
      return jsonify({"error": str(e)}), 400


  @app.errorhandler(404)

  def not_found(e):
      return jsonify({"error": "Not found"}), 404


  @app.errorhandler(500)

  def server_error(e):
      return jsonify({"error": "Server error"}), 500


  if __name__ == "__main__":
      # For development only. Use Gunicorn/Uvicorn in production.
      app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5000)), debug=os.getenv("FLASK_DEBUG", "1") == "1")
  ```


  - - -


  ### Refactor plan


  Below is a prioritized, practical refactor plan to move this project from a single file to a maintainable, production‑ready structure. Each step includes the goal, recommended actions, and an estimated effort.


  - - -


  #### 1. Project layout and application factory


  **Goal**: Make the app testable and configurable for multiple environments.\

  **Actions**:


  * Create package structure:

    ```
    discernment_journal/
      app/
        __init__.py        # create_app factory
        models.py
        routes/
          __init__.py
          journal.py
          prayers.py
          assignments.py
          exports.py
          visualize.py
        utils.py
      migrations/
      tests/
      config.py
      manage.py            # CLI for migrations, runserver
    ```
  * Implement `create_app(config_name=None)` in `app/__init__.py` and register blueprints. **Effort**: 1–2 days.


  - - -


  #### 2. Database migrations and schema management


  **Goal**: Safe, versioned schema changes.\

  **Actions**:


  * Add `Flask-Migrate` (Alembic). Initialize migrations and create initial migration.

  * Remove `db.create_all()` from runtime code; use migrations for schema changes. **Effort**: 1 day.


  - - -


  #### 3. Blueprints and route separation


  **Goal**: Logical separation of concerns and easier maintenance.\

  **Actions**:


  * Move endpoints into blueprints (`journal`, `prayers`, `assignments`, `exports`, `visualize`, `pdf`).

  * Keep each blueprint focused and small; import models from `app.models`. **Effort**: 1–2 days.


  - - -


  #### 4. Validation and serialization


  **Goal**: Robust input validation and consistent JSON output.\

  **Actions**:


  * Add `marshmallow` schemas for request validation and response serialization.

  * Replace manual parsing with schema load/dump; return clear validation errors. **Effort**: 1–2 days.


  - - -


  #### 5. Authentication and authorization


  **Goal**: Protect write endpoints and sensitive exports.\

  **Actions**:


  * Add token-based auth (JWT) or session-based auth depending on your needs.

  * Protect endpoints with decorators; add role checks if needed. **Effort**: 2–3 days.


  - - -


  #### 6. Background jobs for heavy exports


  **Goal**: Avoid blocking requests for long-running PDF/chart generation.\

  **Actions**:


  * Add Celery or RQ for background tasks; store generated files in S3 or local storage and return download links.

  * Add a small job queue and status endpoint. **Effort**: 3–5 days.


  - - -


  #### 7. Tests and CI


  **Goal**: Ensure reliability and prevent regressions.\

  **Actions**:


  * Add unit tests for models, helpers, and endpoints using pytest and a test DB (SQLite in memory).

  * Add integration tests for CSV/PDF generation (smoke tests).

  * Add CI pipeline (GitHub Actions) to run tests and linting. **Effort**: 3–5 days.


  - - -


  #### 8. Observability and production readiness


  **Goal**: Monitor and operate the app in production.\

  **Actions**:


  * Add structured logging, Sentry (optional) for error tracking.

  * Add Prometheus metrics or basic health checks.

  * Deploy behind a reverse proxy (NGINX) and run with Gunicorn/Uvicorn. **Effort**: 2–4 days.


  - - -


  #### 9. UX and frontend integration


  **Goal**: Provide a simple UI for uploads, exports, and charts.\

  **Actions**:


  * Add a small frontend (Flask templates or a separate SPA) that calls the API.

  * Add authentication flows and download links for generated reports. **Effort**: 3–7 days depending on scope.


  - - -


  ### Suggested immediate next steps


  1. **Run the provided `app.py` locally** to verify endpoints and exports.

  2. **Initialize a Git repo** and commit the working single‑file app.

  3. **Create a new branch** and start the refactor by implementing the application factory and blueprints (step 1).

  4. **Add Flask‑Migrate** and create the first migration.

  5. **Add basic tests** for the most critical endpoints (create/list journal entries, CSV export).


  - - -


  If you want, I can:


  * generate the **refactored project skeleton** (files and minimal content for `create_app`, `models.py`, and one blueprint) so you can start the migration; or

  * produce a **detailed migration script** and `Flask-Migrate` commands to run locally.


  Which of those would you like next?


  <!--EndFragment -->
---

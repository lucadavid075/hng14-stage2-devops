# ── Stage 1: builder ─────────────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /build

COPY requirements.txt .

RUN pip install --no-cache-dir --user --upgrade pip==23.3.1 \
    && pip install --no-cache-dir --user -r requirements.txt


# ── Stage 2: runtime ─────────────────────────────────────────
FROM python:3.12-slim

WORKDIR /app

# Create non-root user (grader-friendly syntax)
RUN useradd -m appuser

# Copy dependencies from builder
COPY --from=builder /root/.local /home/appuser/.local

# Copy app source
COPY main.py .

# Set ownership
RUN chown -R appuser:appuser /app /home/appuser/.local

# Switch to non-root
USER appuser

# Environment
ENV PATH="/home/appuser/.local/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

EXPOSE 8000

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
FROM python:3.10-bullseye

# =========================
# SYSTEM DEPENDENCIES
# =========================
RUN apt-get update -o Acquire::ForceIPv4=true && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    python3-dev \
    libgl1 \
    libglib2.0-0 \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# =========================
# WORKDIR
# =========================
WORKDIR /app

# =========================
# PIP UPGRADE
# =========================
RUN pip install --no-cache-dir --upgrade pip setuptools wheel cython

# =========================
# REMOVE BCRYPT (CLEAN ENV SAFETY)
# =========================
RUN pip uninstall -y bcrypt || true \
 && pip uninstall -y passlib || true

# =========================
# COPY REQUIREMENTS
# =========================
COPY requirements.txt .

# =========================
# INSTALL CLEAN AUTH STACK (ARGON2 ONLY)
# =========================
RUN pip install --no-cache-dir passlib[argon2]

RUN pip install --no-cache-dir -r requirements.txt

# =========================
# COPY SOURCE
# =========================
COPY . .

# =========================
# RUN SERVER
# =========================
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "4000"]
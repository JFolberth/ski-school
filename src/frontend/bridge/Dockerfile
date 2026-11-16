FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONNOUSERSITE=1 \
    PYTHONUNBUFFERED=1
WORKDIR /opt/ski-school/bridge
COPY requirements.txt .
ARG PIP_INDEX_URL
ARG PIP_TRUSTED_HOST
RUN python -m pip install --no-cache-dir --require-hashes -r requirements.txt \
    && python -m pip check \
    && groupadd --gid 10001 bridge \
    && useradd --uid 10001 --gid bridge --create-home bridge
COPY main.py .
USER bridge
EXPOSE 8089
CMD ["python", "-I", "-m", "uvicorn", "main:app", "--host", "127.0.0.1", "--port", "8089", "--no-access-log"]

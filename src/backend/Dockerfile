FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONNOUSERSITE=1 \
    PYTHONUNBUFFERED=1
WORKDIR /opt/ski-school/backend
COPY requirements.txt .
RUN python -m pip install --no-cache-dir --require-hashes -r requirements.txt \
    && python -m pip check \
    && groupadd --gid 10001 backend \
    && useradd --uid 10001 --gid backend --create-home backend
COPY main.py .
USER backend
EXPOSE 8088
CMD ["python", "-I", "/opt/ski-school/backend/main.py"]
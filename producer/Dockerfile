FROM python:3.8-slim
COPY producer.py .
RUN pip install kafka-python==2.0.2
CMD ["python", "producer.py"]

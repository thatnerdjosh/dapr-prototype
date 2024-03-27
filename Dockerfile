FROM python

COPY app.py .

ENTRYPOINT ["python"]
CMD ["app.py"]

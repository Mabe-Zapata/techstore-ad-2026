import os

import pyodbc

DB_SERVER = r"localhost\MSSQLSERVER01"
DB_NAME = "AppDistribuidas_2026_DB"
DB_USER =  "sa"
DB_PASSWORD = "sa"

CONNECTION_STRING = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    f"SERVER={DB_SERVER};"
    f"DATABASE={DB_NAME};"
    f"UID={DB_USER};"
    f"PWD={DB_PASSWORD};"
    "TrustServerCertificate=yes;"
)


def get_connection():
    return pyodbc.connect(CONNECTION_STRING, autocommit=False)

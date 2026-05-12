# Project Technology Stack: AI-Driven Career Assessment Platform

The following table outlines the technical architecture and tools used in the development of the AI-Driven Career Assessment Platform.

| Category | Technology | Description |
| :--- | :--- | :--- |
| **Frontend Framework** | **Flutter (Dart)** | Utilized for building a responsive, cross-platform UI with high-performance rendering. |
| **Backend Core** | **Python (Flask)** | A lightweight yet powerful web framework for managing RESTful APIs and background services. |
| **Artificial Intelligence** | **Google Gemini (GenAI)** | Powers the core intelligence for resume parsing, adaptive test generation, and personalized roadmaps. |
| **Authentication** | **JWT (JSON Web Tokens)** | Implemented via `flask-jwt-extended` for secure, stateless user session management. |
| **Cybersecurity** | **Werkzeug Security** | Handles password encryption using PBKDF2 hashing algorithms for database integrity. |
| **Database Layer** | **SQLAlchemy** | An Object-Relational Mapper (ORM) used to interface with the system's relational database. |
| **Resume Extraction** | **pdfplumber & PyPDF2** | Specialized libraries for extracting structured data and competencies from PDF resume uploads. |
| **Document Processing** | **python-docx** | Facilitates the parsing and analysis of resumes submitted in Microsoft Word format. |
| **News & Data Aggregation** | **Feedparser & Requests** | Fetches and processes real-time industry news and external API data for career insights. |
| **API Connectivity** | **Flask-CORS** | Manages Cross-Origin Resource Sharing for seamless communication between Flutter and Flask. |
| **Production Server** | **Gunicorn** | A production-grade WSGI HTTP server for deploying the backend application. |

---

### Logical Architecture Overview

*   **Client Side**: The Flutter application manages the user interface, state management, and interaction logic.
*   **API Gateway**: Flask handles incoming requests, authentication, and routing to specific services.
*   **AI Service Layer**: Integrates with Google's Generative AI to process complex textual data and generate dynamic content.
*   **Data Layer**: Persists user profiles, assessment results, and learning paths using SQLAlchemy.
